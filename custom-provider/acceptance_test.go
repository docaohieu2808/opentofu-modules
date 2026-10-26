package main

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"testing"

	"github.com/hashicorp/terraform-plugin-testing/helper/resource"
	"github.com/hashicorp/terraform-plugin-testing/terraform"
)

// These tests drive a real tofu/terraform binary against the provider running in-process
// (reattach). They are skipped unless TF_ACC=1, and need TF_ACC_TERRAFORM_PATH pointing at the
// binary. Everything happens in a temp directory: no cloud and no credentials.
//
//	TF_ACC=1 TF_ACC_TERRAFORM_PATH=$(command -v tofu) \
//	TF_ACC_PROVIDER_HOST=registry.opentofu.org TF_ACC_PROVIDER_NAMESPACE=lab go test ./...

func configFileConfig(path, content string) string {
	return fmt.Sprintf(`
resource "devops_config_file" "x" {
  path    = %q
  content = %q
}

data "devops_file_info" "x" {
  path       = devops_config_file.x.path
  depends_on = [devops_config_file.x]
}

output "label" {
  value = provider::devops::sanitise_label("Dev/Staging Env")
}
`, path, content)
}

func fileHasContent(path, want string) resource.TestCheckFunc {
	return func(_ *terraform.State) error {
		got, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		if string(got) != want {
			return fmt.Errorf("file %s has %q, want %q", path, got, want)
		}
		return nil
	}
}

func TestAccConfigFileLifecycle(t *testing.T) {
	path := filepath.Join(t.TempDir(), "hello.txt")

	resource.Test(t, resource.TestCase{
		ProtoV6ProviderFactories: testProtoV6ProviderFactories,
		CheckDestroy: func(_ *terraform.State) error {
			if _, err := os.Stat(path); !os.IsNotExist(err) {
				return fmt.Errorf("file %s should be gone after destroy (stat error: %v)", path, err)
			}
			return nil
		},
		Steps: []resource.TestStep{
			{
				Config: configFileConfig(path, "one"),
				Check: resource.ComposeAggregateTestCheckFunc(
					fileHasContent(path, "one"),
					resource.TestCheckResourceAttr("devops_config_file.x", "id", path),
					resource.TestCheckResourceAttr("data.devops_file_info.x", "exists", "true"),
					resource.TestCheckResourceAttr("data.devops_file_info.x", "size_bytes", "3"),
					// sha256("one")
					resource.TestCheckResourceAttr("data.devops_file_info.x", "sha256", "7692c3ad3540bb803c020b3aee66cd8887123234ea0c6e7143c0add73ff431ed"),
					resource.TestCheckOutput("label", "dev-staging-env"),
				),
			},
			{
				// Changing only the content updates in place.
				Config: configFileConfig(path, "three!"),
				Check: resource.ComposeAggregateTestCheckFunc(
					fileHasContent(path, "three!"),
					resource.TestCheckResourceAttr("data.devops_file_info.x", "size_bytes", "6"),
				),
			},
		},
	})
}

func TestAccFileInfoMissingFile(t *testing.T) {
	missing := filepath.Join(t.TempDir(), "nope.txt")

	resource.Test(t, resource.TestCase{
		ProtoV6ProviderFactories: testProtoV6ProviderFactories,
		Steps: []resource.TestStep{
			{
				Config: fmt.Sprintf(`data "devops_file_info" "x" { path = %q }`, missing),
				Check: resource.ComposeAggregateTestCheckFunc(
					resource.TestCheckResourceAttr("data.devops_file_info.x", "exists", "false"),
					resource.TestCheckResourceAttr("data.devops_file_info.x", "size_bytes", "0"),
					resource.TestCheckNoResourceAttr("data.devops_file_info.x", "sha256"),
				),
			},
		},
	})
}

func TestAccConfigFileUnwritablePathIsAnError(t *testing.T) {
	// The "directory" in the path is really a regular file, so the file cannot be created.
	blocker := filepath.Join(t.TempDir(), "blocker")
	if err := os.WriteFile(blocker, []byte("x"), 0o600); err != nil {
		t.Fatal(err)
	}

	resource.Test(t, resource.TestCase{
		ProtoV6ProviderFactories: testProtoV6ProviderFactories,
		Steps: []resource.TestStep{
			{
				Config: fmt.Sprintf(`
resource "devops_config_file" "x" {
  path    = %q
  content = "x"
}
`, filepath.Join(blocker, "f.txt")),
				ExpectError: regexp.MustCompile(`Unable to write file`),
			},
		},
	})
}
