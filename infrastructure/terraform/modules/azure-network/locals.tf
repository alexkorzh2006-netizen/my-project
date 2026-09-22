locals {
  cloud_name      = "azure"
  cloud_config    = lookup(var.config.clouds, local.cloud_name, {})
  resource_prefix = "${var.config.name_prefix}-${var.config.environment}"
  enabled         = length(var.vms) > 0
  location        = try(local.cloud_config.regions[var.config.location.region], null)
  network         = merge(var.config.network, lookup(local.cloud_config, "network", {}))
  vnet_cidr       = try(local.network.vnet_cidr, local.network.vpc_cidr)
  common_tags = merge(var.config.common_labels, {
    application = var.config.name_prefix
    environment = var.config.environment
    managed_by  = "terraform"
    cloud       = local.cloud_name
  })
}
