// Command terraform-provider-devops is a small, fully local provider that teaches the
// terraform-plugin-framework: a provider, a resource, a data source and a provider-defined
// function. Everything it does happens on the machine running OpenTofu/Terraform, so it can be
// built, tested and used with no cloud account.
//
// Build and try it:
//
//	go build -o terraform-provider-devops .
//	# then follow ../functions/custom/README or the repository README (dev_overrides).
package main

import (
	"context"
	"flag"
	"log"

	"github.com/hashicorp/terraform-plugin-framework/providerserver"
)

// version is stamped at build time: go build -ldflags "-X main.version=1.2.3".
var version = "dev"

func main() {
	var debug bool
	flag.BoolVar(&debug, "debug", false, "start the provider with support for debuggers such as delve")
	flag.Parse()

	err := providerserver.Serve(context.Background(), New(version), providerserver.ServeOpts{
		// A registry-style address. With dev_overrides in the CLI configuration the same address
		// is mapped to a local directory, so nothing has to be published.
		Address: "registry.opentofu.org/lab/devops",
		Debug:   debug,
	})
	if err != nil {
		log.Fatal(err)
	}
}
