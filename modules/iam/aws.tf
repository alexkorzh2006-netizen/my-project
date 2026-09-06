resource "aws_iam_role" "ec2" {
  count = length(local.aws_vms) > 0 ? 1 : 0
  name  = "${local.resource_prefix}-ec2"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
  tags = local.aws_tags
}

resource "aws_iam_instance_profile" "ec2" {
  count = length(local.aws_vms) > 0 ? 1 : 0
  name  = "${local.resource_prefix}-ec2"
  role  = aws_iam_role.ec2[0].name
  tags  = local.aws_tags
}
