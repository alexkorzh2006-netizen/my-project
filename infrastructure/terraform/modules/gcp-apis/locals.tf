locals {
  cloud_name      = "gcp"
  vms = {
    for name, vm in var.config.vms : name => vm
    if lookup(vm, "cloud", var.config.default_cloud) == local.cloud_name
  }
  required_apis = ["compute.googleapis.com", "iam.googleapis.com", "secretmanager.googleapis.com"]
}
