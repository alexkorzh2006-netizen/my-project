output "bastion_public_ip" {
  description = "Bastion public IP."
  value       = try(merge(module.gcp_vm.vms, module.aws_vm.vms)["bastion"].public_ip, null)
}

output "workload_vm_names" {
  description = "VM names by workload."
  value = {
    for name, workload in merge(module.gcp_vm.vms, module.aws_vm.vms) : name => workload.name
    if workload.role != "bastion"
  }
}

output "workload_roles" {
  description = "Roles by workload."
  value = {
    for name, workload in merge(module.gcp_vm.vms, module.aws_vm.vms) : name => workload.role
    if workload.role != "bastion"
  }
}

output "workload_internal_ips" {
  description = "Internal IPs by workload."
  value = {
    for name, workload in merge(module.gcp_vm.vms, module.aws_vm.vms) : name => workload.internal_ip
    if workload.role != "bastion"
  }
}

output "workload_external_ips" {
  description = "External IPs by workload."
  value = {
    for name, workload in merge(module.gcp_vm.vms, module.aws_vm.vms) : name => workload.public_ip
    if workload.role != "bastion"
  }
}

output "workload_network_tags" {
  description = "Network tags by workload."
  value = {
    for name, workload in merge(module.gcp_vm.vms, module.aws_vm.vms) : name => workload.network_tags
    if workload.role != "bastion"
  }
}

output "workload_service_account_emails" {
  description = "Service-account emails by workload."
  value = {
    for name, workload in merge(module.gcp_vm.vms, module.aws_vm.vms) : name => workload.service_account_email
    if workload.role != "bastion" && workload.service_account_email != null
  }
}

output "workload_clouds" {
  description = "Selected cloud for each workload."
  value = {
    for name, workload in merge(module.gcp_vm.vms, module.aws_vm.vms) : name => workload.cloud
    if workload.role != "bastion"
  }
}

output "secret_ids" {
  description = "GCP Secret Manager container IDs created for GCP workloads."
  value       = module.gcp_secrets.secret_ids
}

output "secret_resource_names" {
  description = "Fully qualified GCP Secret Manager resource names, by secret ID."
  value       = module.gcp_secrets.secret_resource_names
}

output "workload_secret_access" {
  description = "Secret IDs each GCP workload service account may read."
  value       = module.gcp_secrets.workload_secret_access
}
