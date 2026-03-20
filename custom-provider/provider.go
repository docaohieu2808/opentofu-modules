// MAX: Custom Provider — provider.go
//
// Implements a minimal custom provider "devops" with:
//   - One data source: devops_gcp_project_info  (reads GCP project metadata)
//   - One resource:    devops_config_file        (manages a local config file)
//
// This skeleton compiles and registers correctly; actual API calls are stubbed.

package main

import (
	"context"
	"os"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/function"
	"github.com/hashicorp/terraform-plugin-framework/provider"
	"github.com/hashicorp/terraform-plugin-framework/provider/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

// ── Provider factory ────────────────────────────────────────────────────────

func NewDevOpsProvider() provider.Provider {
	return &devOpsProvider{}
}

// ── Provider struct ──────────────────────────────────────────────────────────

type devOpsProvider struct{}

type devOpsProviderModel struct {
	GCPProject  types.String `tfsdk:"gcp_project"`
	Credentials types.String `tfsdk:"credentials_file"`
}

func (p *devOpsProvider) Metadata(_ context.Context, _ provider.MetadataRequest, resp *provider.MetadataResponse) {
	resp.TypeName = "devops"
	resp.Version  = "1.0.0"
}

func (p *devOpsProvider) Schema(_ context.Context, _ provider.SchemaRequest, resp *provider.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "Custom DevOps provider for GCP automation helpers.",
		Attributes: map[string]schema.Attribute{
			"gcp_project": schema.StringAttribute{
				Optional:    true,
				Description: "GCP project ID. Falls back to GOOGLE_PROJECT env var.",
			},
			"credentials_file": schema.StringAttribute{
				Optional:    true,
				Description: "Path to GCP service account JSON. Falls back to GOOGLE_APPLICATION_CREDENTIALS.",
			},
		},
	}
}

func (p *devOpsProvider) Configure(ctx context.Context, req provider.ConfigureRequest, resp *provider.ConfigureResponse) {
	var config devOpsProviderModel
	resp.Diagnostics.Append(req.Config.Get(ctx, &config)...)
	if resp.Diagnostics.HasError() {
		return
	}

	// Resolve project from config or env
	project := config.GCPProject.ValueString()
	if project == "" {
		project = os.Getenv("GOOGLE_PROJECT")
	}

	// Resolve credentials from config or env
	creds := config.Credentials.ValueString()
	if creds == "" {
		creds = os.Getenv("GOOGLE_APPLICATION_CREDENTIALS")
	}

	// In a real provider, initialise GCP client here and pass via resp.ResourceData / resp.DataSourceData
	_ = project
	_ = creds
}

func (p *devOpsProvider) Resources(_ context.Context) []func() resource.Resource {
	return []func() resource.Resource{
		NewConfigFileResource,
	}
}

func (p *devOpsProvider) DataSources(_ context.Context) []func() datasource.DataSource {
	return []func() datasource.DataSource{
		NewGCPProjectInfoDataSource,
	}
}

// OpenTofu 1.7+: providers can expose callable HCL functions via Functions()
func (p *devOpsProvider) Functions(_ context.Context) []func() function.Function {
	return []func() function.Function{
		NewSanitiseLabelFunction,
	}
}

// ── Resource: devops_config_file ─────────────────────────────────────────────

type configFileResource struct{}

func NewConfigFileResource() resource.Resource { return &configFileResource{} }

func (r *configFileResource) Metadata(_ context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_config_file"
}

func (r *configFileResource) Schema(_ context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "Manages a local configuration file on the runner.",
		Attributes: map[string]schema.Attribute{
			"path": schema.StringAttribute{
				Required:    true,
				Description: "Absolute path of the config file to manage.",
			},
			"content": schema.StringAttribute{
				Required:    true,
				Description: "Content to write into the file.",
			},
			"id": schema.StringAttribute{
				Computed:    true,
				Description: "Same as path; used as resource ID.",
			},
		},
	}
}

type configFileModel struct {
	Path    types.String `tfsdk:"path"`
	Content types.String `tfsdk:"content"`
	ID      types.String `tfsdk:"id"`
}

func (r *configFileResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan configFileModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if err := os.WriteFile(plan.Path.ValueString(), []byte(plan.Content.ValueString()), 0644); err != nil {
		resp.Diagnostics.AddError("Failed to write config file", err.Error())
		return
	}

	plan.ID = plan.Path
	resp.Diagnostics.Append(resp.State.Set(ctx, &plan)...)
}

func (r *configFileResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var state configFileModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	data, err := os.ReadFile(state.Path.ValueString())
	if os.IsNotExist(err) {
		resp.State.RemoveResource(ctx)
		return
	}
	if err != nil {
		resp.Diagnostics.AddError("Failed to read config file", err.Error())
		return
	}

	state.Content = types.StringValue(string(data))
	resp.Diagnostics.Append(resp.State.Set(ctx, &state)...)
}

func (r *configFileResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plan configFileModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if err := os.WriteFile(plan.Path.ValueString(), []byte(plan.Content.ValueString()), 0644); err != nil {
		resp.Diagnostics.AddError("Failed to update config file", err.Error())
		return
	}

	plan.ID = plan.Path
	resp.Diagnostics.Append(resp.State.Set(ctx, &plan)...)
}

func (r *configFileResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var state configFileModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	if err := os.Remove(state.Path.ValueString()); err != nil && !os.IsNotExist(err) {
		resp.Diagnostics.AddError("Failed to delete config file", err.Error())
	}
}

// ── Data Source: devops_gcp_project_info ────────────────────────────────────

type gcpProjectInfoDataSource struct{}

func NewGCPProjectInfoDataSource() datasource.DataSource { return &gcpProjectInfoDataSource{} }

func (d *gcpProjectInfoDataSource) Metadata(_ context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_gcp_project_info"
}

func (d *gcpProjectInfoDataSource) Schema(_ context.Context, _ datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "Reads metadata about a GCP project (stub — extend with real Cloud Resource Manager API call).",
		Attributes: map[string]schema.Attribute{
			"project_id": schema.StringAttribute{
				Required:    true,
				Description: "GCP project ID to look up.",
			},
			"project_number": schema.StringAttribute{
				Computed:    true,
				Description: "Numeric project number assigned by GCP.",
			},
			"state": schema.StringAttribute{
				Computed:    true,
				Description: "Project lifecycle state (ACTIVE, DELETE_REQUESTED, etc.).",
			},
		},
	}
}

type gcpProjectInfoModel struct {
	ProjectID     types.String `tfsdk:"project_id"`
	ProjectNumber types.String `tfsdk:"project_number"`
	State         types.String `tfsdk:"state"`
}

func (d *gcpProjectInfoDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
	var config gcpProjectInfoModel
	resp.Diagnostics.Append(req.Config.Get(ctx, &config)...)
	if resp.Diagnostics.HasError() {
		return
	}

	// Stub: in production call Cloud Resource Manager API
	// cloudresourcemanager.NewService(ctx) → Projects.Get(projectId)
	config.ProjectNumber = types.StringValue("484714000000")
	config.State         = types.StringValue("ACTIVE")

	resp.Diagnostics.Append(resp.State.Set(ctx, &config)...)
}

// ── Provider-Defined Function: devops::sanitise_label ───────────────────────
// OpenTofu 1.7+: providers can expose HCL-callable functions.
// Called in .tf as: provider::devops::sanitise_label("My Value")

type sanitiseLabelFunction struct{}

func NewSanitiseLabelFunction() function.Function { return &sanitiseLabelFunction{} }

func (f *sanitiseLabelFunction) Metadata(_ context.Context, _ function.MetadataRequest, resp *function.MetadataResponse) {
	resp.Name = "sanitise_label"
}

func (f *sanitiseLabelFunction) Definition(_ context.Context, _ function.DefinitionRequest, resp *function.DefinitionResponse) {
	resp.Definition = function.Definition{
		Summary:     "Sanitise a string for use as a GCP label value.",
		Description: "Lowercases the input and replaces spaces and underscores with hyphens.",
		Parameters: []function.Parameter{
			function.StringParameter{Name: "value", Description: "Raw label value to sanitise."},
		},
		Return: function.StringReturn{},
	}
}

func (f *sanitiseLabelFunction) Run(ctx context.Context, req function.RunRequest, resp *function.RunResponse) {
	var value string
	resp.Error = function.ConcatFuncErrors(req.Arguments.Get(ctx, &value))
	if resp.Error != nil {
		return
	}

	result := sanitiseLabel(value)
	resp.Error = function.ConcatFuncErrors(resp.Result.Set(ctx, result))
}

func sanitiseLabel(s string) string {
	out := make([]byte, 0, len(s))
	for i := 0; i < len(s); i++ {
		c := s[i]
		switch {
		case c >= 'A' && c <= 'Z':
			out = append(out, c+32) // to lowercase
		case c == ' ' || c == '_':
			out = append(out, '-')
		default:
			out = append(out, c)
		}
	}
	return string(out)
}
