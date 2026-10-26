package main

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/function"
)

var _ function.Function = (*sanitiseLabelFunction)(nil)

// NewSanitiseLabelFunction is the factory registered in the provider's Functions().
func NewSanitiseLabelFunction() function.Function { return &sanitiseLabelFunction{} }

// sanitiseLabelFunction is called in HCL as provider::devops::sanitise_label("Dev/Staging").
type sanitiseLabelFunction struct{}

func (f *sanitiseLabelFunction) Metadata(_ context.Context, _ function.MetadataRequest, resp *function.MetadataResponse) {
	resp.Name = "sanitise_label"
}

func (f *sanitiseLabelFunction) Definition(_ context.Context, _ function.DefinitionRequest, resp *function.DefinitionResponse) {
	resp.Definition = function.Definition{
		Summary:     "Make a string a valid GCP label",
		Description: "Lower-cases the input, replaces every character outside a-z, 0-9 and '-' with '-', and truncates to 63 characters.",
		Parameters: []function.Parameter{
			function.StringParameter{
				Name:        "value",
				Description: "Raw text to turn into a label.",
			},
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
	resp.Error = function.ConcatFuncErrors(resp.Result.Set(ctx, sanitiseLabel(value)))
}
