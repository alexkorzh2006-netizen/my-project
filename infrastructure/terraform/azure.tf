locals {
  azure_explicit_vms = {
    for name, vm in local.config.vms : name => vm
    if lookup(vm, "cloud", local.config.default_cloud) == "azure"
  }
  azure_explicit_bastions = {
    for name, vm in local.azure_explicit_vms : name => vm
    if vm.role == "bastion"
  }
  azure_workload_vms = {
    for name, vm in local.azure_explicit_vms : name => vm
    if vm.role != "bastion"
  }
  azure_auto_bastion = (
    length(local.azure_workload_vms) > 0 &&
    length(local.azure_explicit_bastions) == 0
    ) ? {
    azure-bastion = merge(local.config.vms.bastion, {
      cloud            = "azure"
      internal_ip      = try(local.config.vms.bastion.internal_ips.azure, "10.2.0.10")
      assign_public_ip = true
    })
  } : {}
  azure_vms = merge(local.azure_explicit_vms, local.azure_auto_bastion)
}
