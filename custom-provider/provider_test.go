package main

import (
	"context"
	"testing"

	"github.com/hashicorp/terraform-plugin-framework/providerserver"
	"github.com/hashicorp/terraform-plugin-go/tfprotov6"
)

// testProtoV6ProviderFactories lets the tests (and the acceptance tests) run the provider
// in-process over the real plugin protocol.
var testProtoV6ProviderFactories = map[string]func() (tfprotov6.ProviderServer, error){
	"devops": providerserver.NewProtocol6WithError(New("test")()),
}

// TestProviderAdvertisesEverything asks the provider for its schema over the plugin protocol,
// exactly as OpenTofu does at `init`/`validate` time. A resource built with the wrong schema
// package, or an invalid attribute, fails here.
func TestProviderAdvertisesEverything(t *testing.T) {
	server, err := testProtoV6ProviderFactories["devops"]()
	if err != nil {
		t.Fatal(err)
	}

	schemaResp, err := server.GetProviderSchema(context.Background(), &tfprotov6.GetProviderSchemaRequest{})
	if err != nil {
		t.Fatal(err)
	}
	for _, d := range schemaResp.Diagnostics {
		t.Errorf("schema diagnostic: %s: %s", d.Summary, d.Detail)
	}

	if _, ok := schemaResp.ResourceSchemas["devops_config_file"]; !ok {
		t.Error("resource devops_config_file is not registered")
	}
	if _, ok := schemaResp.DataSourceSchemas["devops_file_info"]; !ok {
		t.Error("data source devops_file_info is not registered")
	}
	if _, ok := schemaResp.Functions["sanitise_label"]; !ok {
		t.Error("function sanitise_label is not registered")
	}
}
