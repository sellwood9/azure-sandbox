# Steve's Azure sandbox

Personal learning repo. Azure **commercial** subscription, self-funded, hard budget $100/month.
Goal: practice the Stanley Martin platform-engineer stack + AZ-401 (Agentic DevOps) topics.

## Stack
- IaC: Bicep. Entry point is `infra/main.bicep` (`targetScope = 'subscription'`) with parameters in `infra/main.bicepparam`.
- Deploy only through subscription-scope deployment stacks (`az stack sub ...`). No plain `az deployment ... create`, no portal changes.
- Prefer Azure Verified Modules (`br/public:avm/...`, pinned versions) when they don't fight our rules. If an AVM module can't disable local auth, set tags, or scope RBAC narrowly enough, use a native resource instead and say why.
- App code: Python 3.12+, managed with `uv` (never pip/venv directly)
- CI/CD: GitHub Actions on GitHub.com, OIDC to Azure (no client secrets, ever)
- Region: eastus2 unless a service isn't available there

## Hard rules
- No secrets, keys, or connection strings in code, `.bicepparam`, or workflow files. Use managed identity, Entra ID, and Key Vault references.
- Entra-only auth: disable local auth on every service that supports it. "Local auth" means every non-Entra mechanism, not just account keys:
  - Storage: `allowSharedKeyAccess: false`, `isLocalUserEnabled: false`, `isSftpEnabled: false`
  - Service Bus / Foundry (Cognitive Services) / others with the property: `disableLocalAuth: true`
  - ACR: `adminUserEnabled: false`
  - For any other service, check the resource's API reference for every auth-related property before proposing it.
- Least privilege: use the narrowest scope that works, preferring child resource (container, queue, secret) > resource > RG. Never subscription, except the budget.
- Every resource gets tags: `owner=steve`, `env=sandbox`, `level=<level>`, `expires=<yyyy-mm-dd>`; the deployment stack itself gets them too (`--tags`). If a resource type can't be tagged (budgets, blob containers, role assignments, ...), list it as an explicit exception in the plan and carry the tags in `metadata`/`description` where that exists.
- Before proposing any resource, state its estimated monthly cost. Flag anything over $5/month.
- Expensive labs (AKS, Databricks, APIM non-Consumption) live in their own Bicep entry point and their own deployment stack, so deleting that stack removes them alone.
- `az bicep lint` must pass before any what-if or deploy.
- Always run what-if and show me the output before any deploy.
- Never run `az stack ... create` or `az stack ... delete` (any scope) without showing me the exact command, including `--action-on-unmanage` and `--deny-settings-mode`, and getting my OK.

## Commands
- `uv run pytest` — tests
- `uv run ruff check .`
- `az bicep lint --file infra/main.bicep`
- `az deployment sub what-if --location eastus2 --template-file infra/main.bicep --parameters infra/main.bicepparam` — preview (read-only)
- `az stack sub validate --name <stack> --location eastus2 --template-file infra/main.bicep --parameters infra/main.bicepparam ...` — validate stack (read-only)
- `az stack sub create ...` / `az stack sub delete ...` — **only with my OK** (see Hard rules)

## Teaching mode
I'm learning. Explain *why* briefly before *how*. I already know Terraform, so when something maps to a Terraform concept, say so (e.g. what-if ≈ `plan`, deployment stack ≈ state + `destroy` boundary, AVM ≈ registry modules). Point out which AZ-401 skill a change exercises.
- Map every planned change to the AZ-401 skill it exercises (a table in the plan), not one summary line.
- Analogies come from Terraform/Bicep/Azure only. Don't assume AWS/GCP knowledge.

## Before presenting any plan
Self-review the plan against every Hard rule and Teaching-mode bullet above, and fix violations before showing it to me.

## References
- AZ-401 skills outline: https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/az-401. Fetch it when mapping work to AZ-401.
- Bicep reference implementation for Claude on Azure: https://github.com/Azure-Samples/claude (see `infra-bicep/`).
