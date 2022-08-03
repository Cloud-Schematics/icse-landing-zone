##############################################################################
# Get Teleport Subnets
##############################################################################

locals {
  teleport_network = (
    var.add_edge_vpc == true && var.create_edge_network_on_management_vpc == true # if edge on management
    ? var.vpc_names[0]
    : var.add_edge_vpc == true
    ? "edge"
    : var.teleport_vpc
  )

  teleport_resource_group = (
    var.add_edge_vpc == true || var.create_edge_network_on_management_vpc == true # if edge is enabled
    ? local.edge_resource_group_id                                                # use edge rg
    : local.resource_group_vpc_map[var.teleport_vpc]                              # otherwise use vpc rg
  )
}

module "teleport_vsi_subnets" {
  count            = var.enable_teleport == true ? 1 : 0
  source           = "github.com/Cloud-Schematics/get-subnets"
  subnet_zone_list = (
    local.teleport_network == "edge"
    ? module.f5[0].subnet_zone_list
    : module.icse_vpc_network.vpc_networks[local.teleport_network].subnet_zone_list
  )
  regex = join("|",
    [
      for zone in range(1, var.vsi_zones + 1) :
      (
        var.add_edge_vpc == true || var.create_edge_network_on_management_vpc == true
        ? "edge-bastion-"              # if edge is in use search for edge bastion
        : var.teleport_deployment_tier # otherwise search for deployment tier
      )
    ]
  )
}

##############################################################################

##############################################################################
# Teleport Boot Volume Encryption Key
##############################################################################

resource "ibm_kms_key" "teleport_instance_key" {
  count         = var.enable_teleport == true ? 1 : 0
  instance_id   = module.icse_vpc_network.key_management_guid
  key_name      = "${var.prefix}-teleport-instance-key"
  standard_key  = false
  endpoint_type = var.key_management_endpoint_type
}

resource "ibm_kms_key" "teleport_bucket_key" {
  count         = var.enable_teleport == true ? 1 : 0
  instance_id   = module.icse_vpc_network.key_management_guid
  key_name      = "${var.prefix}-teleport-bucket-key"
  standard_key  = false
  endpoint_type = var.key_management_endpoint_type
}

##############################################################################

##############################################################################
# Teleport Deployment
##############################################################################

module "teleport_vsi" {
  count                      = var.enable_teleport == true ? 1 : 0
  source                     = "github.com/terraform-ibm-modules/terraform-teleport-deployment"
  region                     = var.region
  prefix                     = var.prefix
  tags                       = var.tags
  resource_group_id          = local.teleport_resource_group
  appid_use_data             = var.appid_use_data
  appid_name                 = var.appid_name
  appid_resource_group_id    = var.appid_resource_group_id
  cos_suffix                 = module.icse_vpc_network.cos_suffix
  cos_id                     = module.icse_vpc_network.cos_instances[0].id
  bucket_encryption_key_id   = ibm_kms_key.teleport_bucket_key[0].crn
  boot_volume_encryption_key = ibm_kms_key.teleport_instance_key[0].crn
  subnet_zone_list           = module.teleport_vsi_subnets[0].subnets
  ssh_key_ids                = [local.template_ssh_key_id]
  profile                    = var.teleport_profile
  image_name                 = var.teleport_image_name
  primary_security_group_ids = null
  add_floating_ip            = var.teleport_add_floating_ip
  teleport_license           = var.teleport_license
  https_cert                 = var.https_cert
  https_key                  = var.https_key
  teleport_hostname          = var.teleport_hostname
  teleport_domain            = var.teleport_domain
  teleport_version           = var.teleport_version
  message_of_the_day         = var.message_of_the_day
  claims_to_roles            = var.claims_to_roles
  primary_interface_security_group = {
    create = false
    rules  = []
  }
  vpc_id = (
    local.teleport_network == "edge"
    ? module.f5[0].vpc_id
    : module.icse_vpc_network.vpc_networks[local.teleport_network].id
  )
}

##############################################################################