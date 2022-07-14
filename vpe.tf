##############################################################################
# Virtual Private Endpoints
##############################################################################

module "vpe_subnets" {
  source           = "github.com/Cloud-Schematics/get-subnets"
  for_each         = module.icse_vpc_network.vpc_networks
  subnet_zone_list = each.value.subnet_zone_list
  regex            = "-vpe-"
}

module "virtual_private_endpoints" {
  source             = "github.com/Cloud-Schematics/vpe-module"
  for_each           = toset(var.enable_virtual_private_endpoints == true ? var.vpcs_create_endpoint_gateway_on_vpe_tier : [])
  prefix             = var.prefix
  region             = var.region
  vpc_name           = each.key
  vpc_id             = module.icse_vpc_network.vpc_networks[each.key].id
  subnet_zone_list   = module.vpe_subnets[each.key].subnets
  resource_group_id  = local.resource_group_vpc_map[each.key]
  service_endpoints  = "private"
  cloud_services     = var.vpe_services
  security_group_ids = [module.security_groups["${each.key}-vpe"].groups[0].id]
}

##############################################################################