##############################################################################
# Create a Security Group for each VSI deployment
##############################################################################

module "vsi_security_groups" {
  source   = "github.com/Cloud-Schematics/vpc-security-group-module"
  for_each = module.vsi_deployment_map.value
  prefix   = var.prefix
  tags     = var.tags
  vpc_id   = module.icse_vpc_network.vpc_networks[each.value.network].id
  security_groups = [
    {
      name = "${each.value.name}-sg"
      rules = flatten([
        [
          for cidr in var.quickstart_vsi_inbound_allow_list :
          {
            name      = "${each.value.name}-sg-allow-in-${index(var.quickstart_vsi_inbound_allow_list, cidr) + 1}"
            direction = "inbound"
            remote    = cidr
          }
        ],
        [
          for cidr in var.quickstart_vsi_outbound_allow_list :
          {
            name      = "${each.value.name}-sg-allow-out-${index(var.quickstart_vsi_outbound_allow_list, cidr) + 1}"
            direction = "outbound"
            remote    = cidr
          }
        ]
      ])
    }
  ]
}

##############################################################################

##############################################################################
# Additional Security Group Rules Configuration
##############################################################################

locals {
  rules_json = jsondecode(file("./json-config/template-quickstart-security-group-rules.json"))

  ##############################################################################
  # detailed rules from variable. separate from json decoded rules to prevent
  # errors using the ? operator
  ##############################################################################
  detailed_hcl_rules = var.use_quickstart_vsi_security_group_rules_json == true ? [] : [
    for group in var.quickstart_vsi_detailed_security_group_rules :
    {
      name = group.security_group_shortname
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
  # detailed rules from variable. separate from hcl rules to prevent
  # errors using the ? operator
  ##############################################################################
  detailed_json_rules = var.use_quickstart_vsi_security_group_rules_json != true ? [] : [
    for group in local.rules_json :
    {
      name = replace(group.security_group_shortname, "-sg", "")
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
# Add rules to security groups
##############################################################################

module "quickstart_vsi_detailed_security_group_rules" {
  source = "github.com/Cloud-Schematics/vpc-security-group-rules-module"
  for_each = {
    for group in concat(local.detailed_json_rules, local.detailed_hcl_rules) :
    (group.name) => group
  }
  security_group_id    = module.vsi_security_groups[each.value.name].groups[0].id
  security_group_rules = each.value.rules
}

##############################################################################