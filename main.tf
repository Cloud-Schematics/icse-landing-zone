##############################################################################
# IBM Cloud Provider
##############################################################################

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
  ibmcloud_timeout = 60
}

##############################################################################

##############################################################################
# VPC Module
##############################################################################

module "key_list" {
  source  = "./config_modules/concat_if_true"
  list    = ["bucket-key"]
  add     = "secrets-manager-key"
  if_true = var.create_secrets_manager
}

module "icse_vpc_network" {
  source                         = "./vpc_module"
  region                         = var.region
  prefix                         = var.prefix
  tags                           = var.tags
  enable_transit_gateway         = var.enable_transit_gateway
  transit_gateway_connections    = var.transit_gateway_connections
  enable_flow_logs               = var.enable_flow_logs
  vpcs                           = local.config.vpcs
  transit_gateway_resource_group = local.management_rg
  key_management                 = local.config.key_management
  atracker                       = local.config.atracker
  cos                            = local.config.cos
  enable_atracker                = local.config.enable_atracker
  security_groups                = []
  keys = [
    for kms_key in module.key_list.list :
    {
      name     = "bucket-key"
      root_key = true
    }
  ]
}

##############################################################################