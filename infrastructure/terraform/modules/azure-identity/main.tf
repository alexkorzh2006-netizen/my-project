locals {
  resource_prefix = "${var.config.name_prefix}-${var.config.environment}"
  common_tags = merge(var.config.common_labels, {
    application = var.config.name_prefix
    environment = var.config.environment
    managed_by  = "terraform"
    cloud       = "azure"
  })
}

resource "azurerm_user_assigned_identity" "vm" {
  for_each = var.vms

  name                = "${local.resource_prefix}-${each.key}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = merge(local.common_tags, { role = each.value.role })
}
