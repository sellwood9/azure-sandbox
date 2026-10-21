locals {
  level = "basecamp"

  tags = {
    owner   = "steve"
    env     = "sandbox"
    level   = local.level
    expires = var.expires
  }

  # Deterministic, so backend.tf can hold a literal account name.
  suffix = substr(sha1(data.azurerm_client_config.current.subscription_id), 0, 8)
}
