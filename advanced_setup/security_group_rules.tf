##############################################################################
# Additional Security Group Rules Configuration
##############################################################################

locals {
  rules_json = jsondecode(file("${path.module}/json-config/template-quickstart-security-group-rules.json"))

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

module "quickstart_detailed_security_group_rules" {
  source = "github.com/Cloud-Schematics/vpc-security-group-rules-module"
  for_each = {
    for group in concat(local.detailed_json_rules, local.detailed_hcl_rules) :
    (group.name) => group
  }
  security_group_id    = var.security_group_modules[each.value.name].groups[0].id
  security_group_rules = each.value.rules
}

##############################################################################