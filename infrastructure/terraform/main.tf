module "gcp_apis" {
  source = "./modules/gcp-apis"
  config = local.config
}

module "iam" {
  source = "./modules/iam"
  config = local.config

  depends_on = [module.gcp_apis]
}

module "aws_network" {
  source = "./modules/aws-network"
  config = local.config
}

module "aws_security" {
  source = "./modules/aws-security"
  config = local.config
  vpc_id = module.aws_network.vpc_id

  enable_bastion_ssh_bootstrap = var.enable_bastion_ssh_bootstrap
}

module "aws_vm" {
  source                = "./modules/aws-vm"
  config                = local.config
  subnet_ids            = module.aws_network.subnet_ids
  security_group_ids    = module.aws_security.security_group_ids
  instance_profile_name = module.iam.aws_instance_profile_name
}

module "gcp_network" {
  source = "./modules/gcp-network"
  config = local.config

  depends_on = [module.gcp_apis]
}

module "gcp_security" {
  source     = "./modules/gcp-security"
  config     = local.config
  network_id = module.gcp_network.network_id

  enable_bastion_ssh_bootstrap = var.enable_bastion_ssh_bootstrap
}

module "gcp_vm" {
  source                 = "./modules/gcp-vm"
  config                 = local.config
  subnet_ids             = module.gcp_network.subnet_ids
  service_account_emails = module.iam.gcp_service_account_emails
}

module "gcp_secrets" {
  source                  = "./modules/gcp-secrets"
  config                  = local.config
  service_account_emails  = module.iam.gcp_service_account_emails
  secret_version_managers = var.secret_version_managers

  depends_on = [module.gcp_apis]
}
