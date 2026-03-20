// MAX: Custom OpenTofu/Terraform Provider Skeleton
//
// This is a minimal provider skeleton using the Terraform Plugin Framework
// (hashicorp/terraform-plugin-framework), which is the modern SDK for both
// Terraform and OpenTofu custom providers.
//
// Build:  go build -o terraform-provider-devops .
// Install: mkdir -p ~/.terraform.d/plugins/local/devops/devops/1.0.0/linux_amd64
//          cp terraform-provider-devops ~/.terraform.d/plugins/local/devops/devops/1.0.0/linux_amd64/
//
// Then reference in .tf files:
//   terraform {
//     required_providers {
//       devops = {
//         source  = "local/devops/devops"
//         version = "1.0.0"
//       }
//     }
//   }

package main

import (
	"context"
	"log"

	"github.com/hashicorp/terraform-plugin-framework/providerserver"
)

func main() {
	opts := providerserver.ServeOpts{
		Address: "local/devops/devops",
	}

	err := providerserver.Serve(context.Background(), NewDevOpsProvider, opts)
	if err != nil {
		log.Fatal(err)
	}
}
