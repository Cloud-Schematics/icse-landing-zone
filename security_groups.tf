##############################################################################
# Security Group Locals
##############################################################################

locals {
  security_group_json = jsondecode(file("./json-config/template-security-groups.json"))

  ##############################################################################
  # detailed groups from variable. separate from json decoded rules to prevent
  # errors using the ? operator
  ##############################################################################
  hcl_security_group_list = var.use_security_group_json == true ? [] : [
    for group in var.security_groups :
    {
      vpc_name          = group.vpc_name
      name              = group.name
      resource_group_id = group.resource_group_id
      rules = [
        for rule in group.rules :
        {
          name      = rule.name
          direction = rule.direction
          remote    = rule.remote
          icmp      = lookup(rule, "icmp", null)
          tcp       = lookup(rule, "tcp", null)
          udp       = lookup(rule, "udp", null)
        }
      ]
    }
  ]
  ##############################################################################

  ##############################################################################
  # detailed groups from json. separate from hcl rules to prevent
  # errors using the ? operator
  ##############################################################################
  json_security_group_list = var.use_security_group_json != true ? [] : [
    for group in local.security_group_json :
    {
      vpc_name          = group.vpc_name
      name              = group.name
      resource_group_id = lookup(group, "resource_group_id", null)
      rules = [
        for rule in group.rules :
        {
          name      = rule.name
          direction = rule.direction
          remote    = rule.remote
          icmp      = lookup(rule, "icmp", null)
          tcp       = lookup(rule, "tcp", null)
          udp       = lookup(rule, "udp", null)
        }
      ]
    }
  ]
  ##############################################################################
}

##############################################################################

##############################################################################
# Security Group Map
##############################################################################

module "security_group_map" {
  source = "./config_modules/list_to_map"
  list   = concat(local.hcl_security_group_list, local.json_security_group_list)
}

##############################################################################

##############################################################################
# Create Security Groups
##############################################################################

module "security_groups" {
  source            = "github.com/Cloud-Schematics/vpc-security-group-module"
  for_each          = module.security_group_map.value
  prefix            = var.prefix
  tags              = var.tags
  vpc_id            = module.icse_vpc_network.vpc_networks[each.value.vpc_name].id
  resource_group_id = each.value.resource_group_id == null ? local.resource_group_vpc_map[each.value.vpc_name] : each.value.resource_group_id
  security_groups = [
    {
      name  = each.value.name
      rules = each.value.rules
    }
  ]
}

##############################################################################