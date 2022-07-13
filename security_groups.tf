##############################################################################
# Create a map of VPE security groups
##############################################################################

module "vpe_security_group_map" {
  source = "github.com/Cloud-Schematics/list-to-map"
  list = [
    for network in var.vpcs_create_endpoint_gateway_on_vpe_tier :
    {
      network = network
      tier    = "vpe"
      name    = "${network}-vpe"
    }
  ]
}

##############################################################################

##############################################################################
# Create a Security Group for each VSI deployment
##############################################################################

module "security_groups" {
  source   = "github.com/Cloud-Schematics/vpc-security-group-module"
  for_each = merge(module.vsi_deployment_map.value, module.vpe_security_group_map.value)
  prefix   = var.prefix
  tags     = var.tags
  vpc_id   = module.icse_vpc_network.vpc_networks[each.value.network].id
  security_groups = [
    {
      name = "${each.value.name}-sg"
      rules = flatten([
        [
          for cidr in var.quickstart_security_group_inbound_allow_list :
          {
            name      = "${each.value.name}-sg-allow-in-${index(var.quickstart_security_group_inbound_allow_list, cidr) + 1}"
            direction = "inbound"
            remote    = cidr
          }
        ],
        [
          for cidr in var.quickstart_security_group_outbound_allow_list :
          {
            name      = "${each.value.name}-sg-allow-out-${index(var.quickstart_security_group_outbound_allow_list, cidr) + 1}"
            direction = "outbound"
            remote    = cidr
          }
        ]
      ])
    }
  ]
}

##############################################################################