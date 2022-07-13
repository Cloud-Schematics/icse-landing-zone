##############################################################################
# Detailed Network ACL Configuration
##############################################################################

locals {
  all_network_acl_list = flatten([
    # For each VPC network
    for network in var.vpc_modules :
    [
      # For each ACL in that network
      for network_acl in network.network_acls :
      # Create an object with existing data (name, id, first_rule_id) and and shortname
      merge(network_acl, {
        shortname = replace(network_acl.name, "/${var.prefix}-|-acl/", "")
      })
    ]
  ])
}

module "detailed_acl_rules" {
  source                           = "github.com/Cloud-Schematics/detailed-network-acl-rules/detailed_acl_rules_module"
  network_acls                     = local.all_network_acl_list
  network_cidr                     = "10.0.0.0/8"
  apply_new_rules_before_old_rules = var.apply_new_rules_before_old_rules
  deny_all_tcp_ports               = var.deny_all_tcp_ports
  deny_all_udp_ports               = var.deny_all_udp_ports
  get_detailed_acl_rules_from_json = var.get_detailed_acl_rules_from_json
  detailed_acl_rules               = var.detailed_acl_rules
  acl_rule_json                    = file("${path.module}/json-config/template-acl-rules.json")
}

##############################################################################