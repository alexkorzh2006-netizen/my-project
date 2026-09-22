locals {
  cloud_name      = "azure"
  resource_prefix = "${var.config.name_prefix}-${var.config.environment}"
  common_tags = merge(var.config.common_labels, {
    application = var.config.name_prefix
    environment = var.config.environment
    managed_by  = "terraform"
    cloud       = local.cloud_name
  })
  network = merge(var.config.network, lookup(var.config.clouds.azure, "network", {}))

  bastion_ssh_rules = {
    for rule in flatten([
      for name, vm in var.vms : [
        for index, cidr in lookup(vm, "allowed_cidrs", []) : {
          key      = "${name}-${index}"
          vm_name  = name
          cidr     = cidr
          port     = lookup(vm, "ssh_port", 22)
          priority = 100 + index
        }
      ] if vm.role == "bastion"
    ]) : rule.key => rule
  }
  workload_ssh_targets = {
    for name, vm in var.vms : name => vm if vm.role != "bastion"
  }
  ui_targets = {
    for name, vm in var.vms : name => vm if vm.role == "ui"
  }
  history_targets = {
    for name, vm in var.vms : name => vm if vm.role == "history"
  }
  database_targets = {
    for name, vm in var.vms : name => vm if vm.role == "database"
  }
}
