output "vpc_id" {
  value = try(aws_vpc.this[0].id, null)
}
output "subnet_ids" {
  value = { for name, subnet in aws_subnet.this : name => subnet.id }
}
