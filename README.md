# opentofu-modules

**Tier 2 of 5 in a zero-to-max Infrastructure-as-Code ladder: OpenTofu, and what it adds on top of Terraform.**

[![ci](https://github.com/docaohieu2808/opentofu-modules/actions/workflows/ci.yml/badge.svg)](https://github.com/docaohieu2808/opentofu-modules/actions/workflows/ci.yml)

The same GCP modules as `terraform-modules` (network, compute, storage), run with OpenTofu, plus the
features OpenTofu added: **state and plan encryption**, `tofu test` with `mock_provider`, provider-defined
functions, and a small **custom provider** written with `terraform-plugin-framework`. Every level runs
without a cloud account, and CI proves it on every push and weekly.

## Level map

| Level | Folder | You learn | How it is proven |
|-------|--------|-----------|------------------|
| L1 | `levels/l1-local-basics` | resources, variables + validation, outputs, `random` / `local` providers | `tofu test` applies for real |
| L2 | `modules/*` | reusable GCP modules, provider v8, validation rules | `tofu validate`, tflint |
| L3 | `environments/dev` | composing modules, partial backend config | offline `tofu plan` with a fake token |
| L4 | `encryption/`, `environments/dev` | AES-GCM state + plan encryption, migrating an unencrypted state, enforcing | `encryption/demo.sh` inspects the state file and tries a wrong key |
| L5 | `modules/*/tests` | `tofu test`, `mock_provider`, `expect_failures`, `command = apply` against mocks | `tofu test` per module |
| L6 | `functions/`, `custom-provider/` | provider-defined functions (google's and your own), building a provider in Go | `go test` with a real `tofu` binary, then HCL calls the built provider |

| Tier | Tool | Trade-off vs this tier |
|------|------|------------------------|
| 1 | Terraform + Terragrunt + OPA (`terraform-modules`) | MPL-2.0 until 1.5, BUSL-1.1 since. Largest ecosystem, HashiCorp/IBM support, no built-in state encryption. |
| **2 (this)** | OpenTofu | MPL-2.0 under the Linux Foundation. Built-in state encryption, `tofu test` mocking, drop-in HCL. Smaller commercial ecosystem. |
| 3 | Pulumi | A real programming language: loops, types, unit tests. Steeper curve than HCL. |
| 4 | AWS CDK | Synthesizes to CloudFormation. AWS only. |
| 5 | Crossplane | Kubernetes control plane with a reconciliation loop. Operationally heavy. |

## Layout

```
levels/l1-local-basics/    L1: local-only first steps (random + local providers)
modules/                   L2: gcp-network, gcp-compute, gcp-storage (+ tests/ per module for L5)
environments/dev/          L3/L4: composition with encrypted state, partial gcs backend
encryption/                L4: demo.sh + step1-unencrypted / step2-migrate / step3-enforced
functions/google-builtin/  L6a: provider::google::* functions (they exist in provider v8) + test
functions/custom/          L6b: provider::devops::sanitise_label from our own provider
custom-provider/           L6: Go provider (provider, resource, data source, function, tests)
.github/workflows/ci.yml   everything above
```

## Running it

Tested versions: OpenTofu 1.13.2, google provider 8.x (`~> 8.0`, locked for linux/mac/windows), Go 1.27,
terraform-plugin-framework 1.19.0. Providers are pulled from `registry.opentofu.org`.

```bash
# L1: a real apply on your machine, cleaned up by the test runner
cd levels/l1-local-basics && tofu init && tofu test

# L2 / L5: unit-test a module with the cloud mocked away
cd modules/gcp-compute && tofu init -backend=false && tofu test

# L3: plan the dev environment offline (fake token + a throwaway local backend).
cd environments/dev
printf 'terraform {\n  backend "local" {}\n}\n' > override.tf      # throwaway: delete it afterwards
export GOOGLE_OAUTH_ACCESS_TOKEN=fake TF_VAR_project_id=example-lab-project
export TF_VAR_state_encryption_passphrase="at-least-16-characters"
tofu init && tofu plan

# L4: prove encryption end to end (needs jq)
encryption/demo.sh

# L6a: google's own provider-defined functions, offline
cd functions/google-builtin && tofu init && tofu test

# L6b: build the custom provider, test it, and call it from HCL
cd custom-provider
go test ./...                                            # unit tests; acceptance tests skip without TF_ACC
TF_ACC=1 TF_ACC_TERRAFORM_PATH=$(command -v tofu) TF_ACC_PROVIDER_HOST=registry.opentofu.org \
  TF_ACC_PROVIDER_NAMESPACE=lab go test -v ./...         # drives a real tofu binary
go build -o bin/terraform-provider-devops .
printf 'provider_installation {\n  dev_overrides {\n    "registry.opentofu.org/lab/devops" = "%s"\n  }\n  direct {}\n}\n' \
  "$PWD/bin" > /tmp/devops.tofurc
TF_CLI_CONFIG_FILE=/tmp/devops.tofurc tofu -chdir=../functions/custom apply
```

### Deploying the dev environment for real

```bash
export TF_VAR_project_id=<your-project> TF_VAR_state_encryption_passphrase=<16+ chars>
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json     # or use `gcloud auth application-default login`
cd environments/dev
tofu init -backend-config="bucket=<your-state-bucket>"
tofu apply
```

The bucket name is intentionally not in the repository (partial backend configuration). Lose the
passphrase and the state is unreadable: store it in a secret manager.

## What changed from the first version, and why

- **Provider `~> 8.0`, OpenTofu `>= 1.10`.** The old `>= 5, < 7` range never used a current provider.
- **`tofu test` works.** The test lived at the repo root and used `module {}`, which cannot see a
  module's resources (root cannot `init`, and assertions on `google_compute_instance.this` failed). Tests
  now sit in `modules/<name>/tests/` and assert resources directly; `command = apply` against
  `mock_resource` defaults tests the outputs. Block-valued mocks must be objects, not lists.
- **The custom provider compiles.** It used one `provider/schema` import for the resource and the data
  source (they need `resource/schema` and `datasource/schema`). Now: framework v1.19.0, `go.sum`
  committed, a valid registry-style address, and unit + acceptance tests. The data source that returned a
  hard-coded fake project number was replaced by `devops_file_info`, which reads a real local file; the
  provider is honest about being local-only.
- **`provider::devops::sanitise_label` is actually called**, from `functions/custom`, against the built
  binary. The earlier `functions/` file only did string replacement with built-ins and claimed otherwise.
  The google provider *does* ship functions in v8 (`region_from_zone`, `name_from_id`, ...); L6a uses them.
- **No default encryption passphrase.** `change-me-use-env-var` was a public key in disguise. The
  variable is now required, validated to 16+ characters (PBKDF2 itself enforces the minimum too) and
  `enforced = true` makes OpenTofu refuse unencrypted state. The old comment mixed up
  `TOFU_ENCRYPTION` with `TF_VAR_...`; the supported way here is `TF_VAR_state_encryption_passphrase`
  (variables inside `encryption` need OpenTofu 1.9+).
- **`credentials` no longer breaks the default run.** `file("")` failed when no key file was set; the
  provider now receives `null` and uses Application Default Credentials.
- **No private identifiers.** The state bucket, project ID and a local key path were removed from the
  tree. SSH is limited to private ranges by default and the network module rejects `0.0.0.0/0`.

## What CI checks

`.github/workflows/ci.yml` runs on push, pull request, `workflow_dispatch` and every Monday 02:41 UTC:

| Job | Checks |
|-----|--------|
| `lint` | `tofu fmt -check`, `tflint`, `shellcheck` |
| `validate` | `init -backend=false -lockfile=readonly` + `validate` for the environment, 3 modules, L1, L6a |
| `test` | `tofu test` for each module (mocked google provider), L1 and L6a; `encryption/demo.sh` |
| `plan-offline` | `environments/dev` plan with encryption on: refused without a passphrase, 5 creates with one, plan file not readable |
| `provider` | `go mod tidy` clean, `gofmt`, `go vet`, `go build`, `go test` incl. acceptance tests against `tofu`, then HCL applies and calls the built provider |

## Honest limits

- Nothing is applied to a real cloud in CI; the GCP modules are verified up to a plan and by mocks.
  Remote state in GCS, locking, and KMS key providers are not exercised (the passphrase provider is).
- Mock tests assert what the module controls; values the cloud computes only exist where a test supplies
  them through `mock_resource` defaults.
- The custom provider is a teaching skeleton (local file resource, file data source, one function), not
  something to publish. It is built and tested, but never released to a registry.
- Tool versions are pinned in `ci.yml`; Dependabot updates actions, OpenTofu lock files and Go modules,
  but the `env:` tool versions are bumped by hand.
