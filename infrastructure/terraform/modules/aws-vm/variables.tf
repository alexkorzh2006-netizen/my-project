variable "config" {
  description = "Project configuration decoded from the external JSON."
  type        = any
}
variable "subnet_ids" {
  description = "Management and workload subnet IDs."
  type        = map(string)
}
variable "security_group_ids" {
  description = "Security group IDs keyed by VM name."
  type        = map(string)
}
variable "instance_profile_name" {
  description = "IAM profile for EC2."
  type        = string
  default     = null
}
