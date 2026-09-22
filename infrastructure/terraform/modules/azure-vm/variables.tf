variable "config" {
  description = "Project configuration decoded from the external JSON."
  type        = any
}

variable "vms" {
  description = "Azure VMs keyed by logical workload name."
  type        = map(any)
}

variable "resource_group_name" {
  type     = string
  nullable = true
}

variable "location" {
  type     = string
  nullable = true
}

variable "subnet_ids" {
  type    = map(string)
  default = {}
}

variable "network_security_group_ids" {
  type    = map(string)
  default = {}
}

variable "identity_ids" {
  type    = map(string)
  default = {}
}

variable "identity_client_ids" {
  type    = map(string)
  default = {}
}

variable "database_runtime" {
  description = "Non-secret database and queue connection metadata exposed to Ansible through Azure VM tags."
  type = object({
    mode                   = string
    cloud                  = string
    host                   = string
    port                   = number
    name                   = string
    username               = string
    sslmode                = string
    secret_reference       = string
    queue_backend          = string
    queue_host             = string
    queue_port             = number
    queue_username         = string
    queue_vhost            = string
    queue_secret_reference = string
  })
}
