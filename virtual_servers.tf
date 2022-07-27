##############################################################################
# SSH Keys
##############################################################################

resource "ibm_is_ssh_key" "ssh_key" {
  count      = var.use_ssh_key_data == null && length(var.vsi_vpcs) > 0 ? 1 : 0
  name       = "${var.prefix}-ssh-key"
  public_key = var.ssh_public_key
}

data "ibm_is_ssh_key" "ssh_key" {
  count = var.use_ssh_key_data == null ? 0 : 1
  name  = var.use_ssh_key_data
}

locals {
  template_ssh_key_id = (
    length(var.vsi_vpcs) == 0
    ? null
    : var.use_ssh_key_data == null
    ? ibm_is_ssh_key.ssh_key[0].id
    : data.ibm_is_ssh_key.ssh_key[0].id
  )
}

##############################################################################

##############################################################################
# Create a map of VSI deployments
##############################################################################

module "vsi_deployment_map" {
  source = "github.com/Cloud-Schematics/list-to-map"
  list = flatten([
    for network in var.vsi_vpcs :
    [
      for tier in var.vsi_subnet_tier :
      {
        network = network
        tier    = tier
        name    = "${network}-${tier}"
      }
    ]
  ])
}

##############################################################################

##############################################################################
# Get VSI Subnets
##############################################################################

module "vsi_subnets" {
  source           = "github.com/Cloud-Schematics/get-subnets"
  for_each         = module.vsi_deployment_map.value
  subnet_zone_list = module.icse_vpc_network.vpc_networks[each.value.network].subnet_zone_list
  regex = join("|",
    [
      for zone in range(1, var.vsi_zones + 1) :
      "-${each.value.tier}-${zone}"
    ]
  )
}

##############################################################################

##############################################################################
# Create VSI KMS Key
##############################################################################

resource "ibm_kms_key" "vsi_key" {
  instance_id   = module.icse_vpc_network.key_management_guid
  key_name      = "${var.prefix}-vsi-key"
  standard_key  = false
  endpoint_type = var.key_management_endpoint_type
}

##############################################################################

##############################################################################
# VSI Deployment
##############################################################################

data "ibm_is_image" "image" {
  name  = var.image_name
}

module "vsi_deployment" {
  source                     = "github.com/Cloud-Schematics/icse-vsi-deployment"
  for_each                   = module.vsi_deployment_map.value
  prefix                     = var.prefix
  tags                       = var.tags
  image_id                   = true
  image_name                 = data.ibm_is_image.image.id # Prevent force deletion when scaling
  vsi_per_subnet             = var.vsi_per_subnet
  profile                    = var.profile
  resource_group_id          = local.resource_group_vpc_map[each.value.network]
  vpc_id                     = module.icse_vpc_network.vpc_networks[each.value.network].id
  subnet_zone_list           = module.vsi_subnets[each.key].subnets
  deployment_name            = "${each.key}-vsi"
  boot_volume_encryption_key = ibm_kms_key.vsi_key.crn
  primary_security_group_ids = [module.security_groups[each.key].groups[0].id]
  ssh_key_ids                = [local.template_ssh_key_id]
  # force await of additional security group rules to ensure network connectivity
  # is set up before virtual server creation.
  depends_on = [module.advanced_setup]
}

##############################################################################