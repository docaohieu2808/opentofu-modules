package main

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"os"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/datasource/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

var _ datasource.DataSource = (*fileInfoDataSource)(nil)

// NewFileInfoDataSource is the factory registered in the provider's DataSources().
func NewFileInfoDataSource() datasource.DataSource { return &fileInfoDataSource{} }

// fileInfoDataSource reports whether a local file exists and, if so, its size and SHA-256.
type fileInfoDataSource struct{}

type fileInfoModel struct {
	Path      types.String `tfsdk:"path"`
	Exists    types.Bool   `tfsdk:"exists"`
	SizeBytes types.Int64  `tfsdk:"size_bytes"`
	SHA256    types.String `tfsdk:"sha256"`
}

func (d *fileInfoDataSource) Metadata(_ context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_file_info"
}

func (d *fileInfoDataSource) Schema(_ context.Context, _ datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema = schema.Schema{
		Description: "Reads facts about a local file.",
		Attributes: map[string]schema.Attribute{
			"path": schema.StringAttribute{
				Required:    true,
				Description: "Path of the file to inspect.",
			},
			"exists": schema.BoolAttribute{
				Computed:    true,
				Description: "Whether the file exists.",
			},
			"size_bytes": schema.Int64Attribute{
				Computed:    true,
				Description: "Size in bytes (0 when the file does not exist).",
			},
			"sha256": schema.StringAttribute{
				Computed:    true,
				Description: "Hex SHA-256 of the content (null when the file does not exist).",
			},
		},
	}
}

func (d *fileInfoDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
	var state fileInfoModel
	resp.Diagnostics.Append(req.Config.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	data, err := os.ReadFile(state.Path.ValueString())
	switch {
	case os.IsNotExist(err):
		state.Exists = types.BoolValue(false)
		state.SizeBytes = types.Int64Value(0)
		state.SHA256 = types.StringNull()
	case err != nil:
		resp.Diagnostics.AddError("Unable to read file", err.Error())
		return
	default:
		sum := sha256.Sum256(data)
		state.Exists = types.BoolValue(true)
		state.SizeBytes = types.Int64Value(int64(len(data)))
		state.SHA256 = types.StringValue(hex.EncodeToString(sum[:]))
	}

	resp.Diagnostics.Append(resp.State.Set(ctx, &state)...)
}
