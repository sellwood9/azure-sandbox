data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "basecamp" {
  name     = "rg-sandbox-basecamp"
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "sttfstate${local.suffix}"
  resource_group_name      = azurerm_resource_group.basecamp.name
  location                 = azurerm_resource_group.basecamp.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Entra ID only: no account keys, no SFTP local users.
  shared_access_key_enabled       = false
  local_user_enabled              = false
  sftp_enabled                    = false
  default_to_oauth_authentication = true

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  tags = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"

  # Containers can't take ARM tags; carry them as metadata instead.
  metadata = local.tags
}

resource "azurerm_role_assignment" "tfstate_blob_contributor" {
  scope                = azurerm_storage_container.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  description          = "owner=steve level=${local.level}: Terraform state read/write"
}
