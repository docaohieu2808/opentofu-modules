# opentofu-modules

**Tier 2 of 5 — OpenTofu: open-source Terraform fork with state encryption and native testing**

## Purpose

Demonstrates OpenTofu-specific capabilities absent in Terraform: AES-GCM state encryption, `tofu test` with `mock_provider`, provider-defined functions, and a custom provider built with terraform-plugin-framework. Same GCP modules as `terraform-modules` but highlighting what changes post-fork.

## Position in the IaC spectrum

| Tier | Tool | Trade-off vs this tier |
|------|------|----------------------|
| 1 | Terraform + Terragrunt | MPL-2.0 originally, now BUSL-1.1 (restrictions for SaaS). Larger registry, HashiCorp support. No built-in state encryption. |
| **2 (this)** | OpenTofu | MPL-2.0 (truly open). State encryption built-in (1.7+). `tofu test` + `mock_provider` (no external tool). Provider-defined functions. Drop-in HCL compatible. |
| 3 | Pulumi | Real language — loops, types, Automation API. Trade-off: JS/TS/Python learning curve vs HCL simplicity. |
| 4 | AWS CDK | AWS-only. Synthesizes to CloudFormation. |
| 5 | Crossplane | Control-plane GitOps, no CLI apply, Kubernetes operational model. |

## Key differentiators vs Terraform (interview talking points)

- **License**: OpenTofu = MPL-2.0; Terraform >= 1.6 = BUSL-1.1 (cannot use to build competing SaaS)
- **State encryption** (`encryption/`): PBKDF2 key derivation + AES-GCM; optional GCP KMS backend; `enforced = false` here (demo mode — set `true` in prod)
- **`tofu test`** (`tests/`): `mock_provider` blocks eliminate real cloud API calls during unit tests; `expect_failures` targets specific check blocks
- **Provider-defined functions** (`functions/`): custom HCL functions implemented in the provider binary (no external tooling)
- **Custom provider** (`custom-provider/`): built with `terraform-plugin-framework v1.13.0` (same SDK, cross-compatible)

## Structure

```
modules/          # gcp-compute, gcp-network, gcp-storage
environments/dev/ # dev environment config
encryption/       # State encryption examples (PBKDF2 + optional KMS)
functions/        # Provider-defined function demo
tests/            # tofu test unit tests with mock_provider
custom-provider/  # Example provider in Go (plugin-framework)
```

## Running

```bash
# Prerequisites: tofu >= 1.9

export TF_VAR_project_id="your-gcp-project"
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/sa.json"
export TF_VAR_state_encryption_passphrase="your-passphrase"

cd environments/dev
tofu init && tofu plan

# Run unit tests (no real GCP calls)
tofu test
```
