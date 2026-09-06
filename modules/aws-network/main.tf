resource "aws_vpc" "this" {
  count = length(local.vms) > 0 ? 1 : 0

  cidr_block           = local.network.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, { Name = "${local.resource_prefix}-vpc" })
}

resource "aws_subnet" "this" {
  for_each = length(local.vms) > 0 ? {
    management = local.network.management_subnet_cidr
    workload   = local.network.workload_subnet_cidr
  } : {}

  vpc_id            = aws_vpc.this[0].id
  cidr_block        = each.value
  availability_zone = local.zone

  tags = merge(local.common_tags, { Name = "${local.resource_prefix}-${each.key}" })
}

resource "aws_internet_gateway" "this" {
  count = length(local.vms) > 0 ? 1 : 0

  vpc_id = aws_vpc.this[0].id
  tags   = merge(local.common_tags, { Name = "${local.resource_prefix}-igw" })
}

resource "aws_route_table" "public" {
  count = length(local.vms) > 0 ? 1 : 0

  vpc_id = aws_vpc.this[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }

  tags = merge(local.common_tags, { Name = "${local.resource_prefix}-public" })
}

resource "aws_route_table_association" "this" {
  for_each = aws_subnet.this

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}
