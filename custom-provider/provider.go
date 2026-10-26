package main

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/function"
	"github.com/hashicorp/terraform-plugin-framework/provider"
	"github.com/hashicorp/terraform-plugin-framework/provider/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource"
)

// Compile-time proof that the provider implements the interfaces it advertises.
var (
	_ provider.Provider              = (*devOpsProvider)(nil)
	_ provider.ProviderWithFunctions = (*devOpsProvider)(nil)
)

// New returns the provider factory used by main and by the tests.
func New(version string) func() provider.Provider {
	return func() provider.Provider {
		return &devOpsProvider{version: version}
	}
}

type devOpsProvider struct {
	version string
}

func (p *devOpsProvider) Metadata(_ context.Context, _ provider.MetadataRequest, resp *provider.MetadataResponse) {
	resp.TypeName = "devops"
	resp.Version = p.version
}

// Schema: the provider needs no configuration because it only touches the local machine.
// (A provider that talks to an API would declare its endpoint and credentials here.)
func (p *devOpsProvider) Schema(_ context.Context, _ provider.SchemaRequest, resp *provider.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "Local helpers used to learn provider development: a managed file, a file data source and a label function.",
	}
}

func (p *devOpsProvider) Configure(_ context.Context, _ provider.ConfigureRequest, _ *provider.ConfigureResponse) {
}

func (p *devOpsProvider) Resources(_ context.Context) []func() resource.Resource {
	return []func() resource.Resource{
		NewConfigFileResource,
	}
}

func (p *devOpsProvider) DataSources(_ context.Context) []func() datasource.DataSource {
	return []func() datasource.DataSource{
		NewFileInfoDataSource,
	}
}

// Functions exposes provider-defined functions, callable in HCL as provider::devops::<name>(...).
func (p *devOpsProvider) Functions(_ context.Context) []func() function.Function {
	return []func() function.Function{
		NewSanitiseLabelFunction,
	}
}
