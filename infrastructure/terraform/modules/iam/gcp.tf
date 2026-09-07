resource "google_service_account" "vm" {
  for_each     = local.gcp_vms
  account_id   = "${local.resource_prefix}-${each.key}"
  display_name = "${local.resource_prefix}-${each.key}"
  description  = "Runtime identity for the ${local.resource_prefix}-${each.key} workload VM"
}
