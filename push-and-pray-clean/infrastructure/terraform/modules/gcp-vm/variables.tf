variable "config" {
  description = "Project configuration decoded from the external JSON."
  type        = any
}
variable "subnet_ids" {
  description = "Management and workload subnet IDs."
  type        = map(string)
}
variable "service_account_emails" {
  description = "Runtime service accounts keyed by VM name."
  type        = map(string)
}
