# Steve's Azure sandbox

Personal learning repo. Azure **commercial** subscription, self-funded, hard budget $100/month.
Goal: practice the Stanley Martin platform-engineer stack + AZ-401 (Agentic DevOps) topics.

## Stack
- IaC: Terraform (azurerm ~> 5.10), one root module per level under `infra/<level>/`
- App code: Python 3.12+, managed with `uv` (never pip/venv directly)
- CI/CD: GitHub Actions on GitHub.com, OIDC to Azure (no client secrets, ever)
- Region: eastus2 unless a service isn't available there

## Hard rules
- No secrets, keys, or connection strings in code, tfvars, or workflow files. Use managed identity, Entra ID, and Key Vault references.
- Disable local auth (keys) on every service that supports it. "Local auth" means every non-Entra mechanism, not just account keys:
  - Storage: `shared_access_key_enabled = false`, `local_user_enabled = false`, `sftp_enabled = false`
  - Service Bus / Foundry (Cognitive): `local_auth_enabled = false`
  - ACR: `admin_enabled = false`
  - For any other service, check the provider docs for every auth-related argument before proposing it.
- Least privilege: use the narrowest scope that works, preferring child resource (container, queue, secret) > resource > RG. Never subscription, except the budget.
- Every resource gets tags: `owner=steve`, `env=sandbox`, `level=<level>`, `expires=<yyyy-mm-dd>`. If a resource type can't be tagged (budgets, containers, role assignments, ...), list it as an explicit exception in the plan and carry the tags in `metadata`/`description` where that exists.
- Before proposing any resource, state its estimated monthly cost. Flag anything over $5/month.
- Expensive labs (AKS, Databricks, APIM non-Consumption) live in their own root module so `terraform destroy` removes them alone.
- Never run `terraform apply`/`destroy`, or anything that rewrites or removes state (`init -migrate-state`, `state mv/rm`, `import`, deleting `*.tfstate*`), without showing me the plan or command first and getting my OK.

## Commands
- `uv run pytest` — tests
- `terraform -chdir=infra/<level> fmt -check && terraform -chdir=infra/<level> validate`
- `uv run ruff check .`

## Teaching mode
I'm learning. Explain *why* briefly before *how*. When something maps to a Terraform/Azure infra concept I already know, say so. Point out which AZ-401 skill a change exercises.
- Map every planned change to the AZ-401 skill it exercises (a table in the plan), not one summary line.
- Analogies come from Terraform/Azure only. Don't assume AWS/GCP knowledge.

## Before presenting any plan
Self-review the plan against every Hard rule and Teaching-mode bullet above, and fix violations before showing it to me.
