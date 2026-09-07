data "aws_ssm_parameter" "image" {
  for_each = local.ssm_image_paths

  name = each.value
}

resource "aws_key_pair" "operator" {
  count = length(local.vms) > 0 ? 1 : 0

  key_name   = "${local.resource_prefix}-${replace(local.primary_ssh_user, "_", "-")}"
  public_key = var.config.ssh_users[local.primary_ssh_user]

  tags = local.common_tags
}

resource "aws_instance" "this" {
  for_each = local.resolved_vms

  ami                         = startswith(each.value.image, "/") ? data.aws_ssm_parameter.image[each.value.image].value : each.value.image
  instance_type               = each.value.machine_type
  subnet_id                   = each.value.role == "bastion" ? var.subnet_ids["management"] : var.subnet_ids["workload"]
  private_ip                  = each.value.internal_ip
  associate_public_ip_address = each.value.assign_public_ip
  key_name                    = aws_key_pair.operator[0].key_name
  iam_instance_profile        = var.instance_profile_name
  vpc_security_group_ids      = [var.security_group_ids[each.key]]

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = each.value.boot_disk.size_gb
    volume_type           = each.value.boot_disk.type
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(
    lookup(each.value, "labels", {}),
    local.common_tags,
    {
      Name = "${local.resource_prefix}-${each.key}"
      role = each.value.role
    },
  )
}
