##############################################################################
# Get Config For Subnets, Public Gateways, and VPN Gateways
##############################################################################

module "subnet_config" {
  for_each                            = toset(var.vpc_names)
  source                              = "./config_modules/subnet_config"
  prefix                              = var.prefix
  vpc_name                            = each.key
  vpc_names                           = var.vpc_names
  zones                               = var.zones
  vpc_subnet_tiers                    = var.vpc_subnet_tiers
  vpc_subnet_tiers_add_public_gateway = var.vpc_subnet_tiers_add_public_gateway
  vpcs_add_vpn_subnet                 = var.vpcs_add_vpn_subnet
}

##############################################################################

##############################################################################
# Create Network ACLs Config
##############################################################################

module "network_acls" {
  for_each                   = toset(var.vpc_names)
  source                     = "./config_modules/acl_config"
  prefix                     = var.prefix
  vpc_name                   = each.key
  vpc_names                  = var.vpc_names
  vpc_subnet_tiers           = var.vpc_subnet_tiers
  add_cluster_rules          = var.add_cluster_rules
  global_inbound_allow_list  = var.global_inbound_allow_list
  global_outbound_allow_list = var.global_outbound_allow_list
  global_inbound_deny_list   = var.global_inbound_deny_list
  global_outbound_deny_list  = var.global_outbound_deny_list
  vpcs_add_vpn_subnet        = var.vpcs_add_vpn_subnet
}

##############################################################################

##############################################################################
# Dynamic VPC Network Configuration
##############################################################################

locals {
  vpcs = [
    for network in var.vpc_names :
    {
      prefix                       = network
      resource_group               = local.resource_group_vpc_map[network]
      default_security_group_rules = []
      address_prefixes = {
        zone-1 = []
        zone-2 = []
        zone-3 = []
      }
      subnets               = module.subnet_config[network].subnets
      use_public_gateways   = module.subnet_config[network].use_public_gateways
      vpn_gateway           = module.subnet_config[network].vpn_gateway
      network_acls          = module.network_acls[network].network_acls
      flow_logs_bucket_name = "${network}-flow-logs-bucket"
    }
  ]
}

##############################################################################

##############################################################################
# Dynamic Cloud Object Storage configuration
##############################################################################

module "cos_bucket_list" {
  source  = "./config_modules/concat_if_true"
  list    = var.vpc_names
  add     = "atracker"
  if_true = var.enable_atracker
}

locals {
  cos = [
    {
      name                = "cos"
      resource_group_name = local.management_rg
      random_suffix       = var.cos_use_random_suffix
      plan                = "standard"
      use_data            = false
      buckets = [
        # Create a flow log bucket for each vpc and a bucket for atracker
        for network in module.cos_bucket_list.list :
        {
          name          = network == "atracker" ? "atracker-bucket" : "${network}-flow-logs-bucket"
          endpoint_type = "public"
          force_delete  = true
          storage_class = "standard"
          kms_key       = "bucket-key"
        }
      ]
      keys = []
    }
  ]
}

##############################################################################

locals {
  # Shortcut for management resource group
  management_rg = local.resource_group_vpc_map[var.vpc_names[0]]

  ##############################################################################
  # Config
  ##############################################################################
  config = {
    vpcs = local.vpcs
    cos  = local.cos
    # Key Management
    key_management = {
      name                      = var.existing_hs_crypto_name == null ? "kms" : var.existing_hs_crypto_name
      use_hs_crypto             = var.existing_hs_crypto_name == null ? false : true
      use_data                  = var.existing_hs_crypto_name == null ? false : true
      resource_group_name       = var.existing_hs_crypto_resource_group == null ? local.management_rg : var.existing_hs_crypto_resource_group
      authorize_vpc_reader_role = true
    }
    # Atracker
    atracker = {
      receive_global_events = true
      add_route             = var.add_atracker_route
      collector_bucket_name = "atracker-bucket"
    }
    enable_atracker = var.enable_atracker
    # Secrets Manager
    secrets_manager = {
      use_secrets_manager = var.create_secrets_manager == true ? true : false
      name                = "secrets-manager"
      kms_key_name        = "secrets-manager-key"
      resource_group_name = local.management_rg
    }
  }
}

##############################################################################