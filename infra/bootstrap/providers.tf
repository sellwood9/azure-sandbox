provider "azurerm" {
  features {}

  # Pinned so Terraform fails instead of deploying to whatever az is logged into.
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  # Shared keys are disabled on the state account, so data-plane calls
  # must authenticate with Entra ID.
  storage_use_azuread = true
}
