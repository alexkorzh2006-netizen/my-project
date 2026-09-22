output "identity_ids" {
  value = { for name, identity in azurerm_user_assigned_identity.vm : name => identity.id }
}

output "principal_ids" {
  value = { for name, identity in azurerm_user_assigned_identity.vm : name => identity.principal_id }
}

output "client_ids" {
  value = { for name, identity in azurerm_user_assigned_identity.vm : name => identity.client_id }
}
