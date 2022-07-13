##############################################################################
# Static list for tiers by type
##############################################################################

locals {
  vpn_firewall_types = {
    full-tunnel = ["f5-management", "f5-external", "f5-bastion"]
    waf         = ["f5-management", "f5-external", "f5-workload"]
    vpn-and-waf = ["f5-management", "f5-external", "f5-workload", "f5-bastion"]
  }
}

##############################################################################

##############################################################################
# Create list of edge VPC tiers
##############################################################################

locals {
  # list of tiers to create
  create_tier_list = flatten([
    var.create_vpn_1_subnet_tier == true ? ["vpn-1"] : [],
    var.create_vpn_2_subnet_tier == true ? ["vpn-2"] : [],
    local.vpn_firewall_types[var.vpn_firewall_type],
    var.create_bastion_subnet_tier == true ? ["bastion"] : [],
    var.create_vpe_subnet_tier == true ? ["vpe"] : []
  ])

  # all subnet tiers
  all_subnet_tiers = ["vpn-1", "vpn-2", "f5-management", "f5-external", "f5-workload", "f5-bastion", "bastion", "vpe"]

  # nested map of subnet tier CIDR blocks by zone
  subnet_tiers = {
    for zone in [1, 2, 3] :
    "zone-${zone}" => {
      for tier in local.all_subnet_tiers :
      (tier) => format("10.%d.%d0.0/24", 4 + zone, index(local.all_subnet_tiers, tier) + 1)
    }
  }
}

##############################################################################

##############################################################################
# Network ACL Config
##############################################################################

locals {
  allow_443_source_inbound_rule = {
    name        = "allow-443-source-inbound"
    action      = "allow"
    direction   = "inbound"
    destination = "10.0.0.0/8"
    source      = "0.0.0.0/0"
    tcp = {
      port_min        = null
      port_max        = null
      source_port_min = 443
      source_port_max = 443
    }
  }

  allow_443_inbound_rule = {
    name        = "allow-443-inbound"
    action      = "allow"
    direction   = "inbound"
    destination = "10.0.0.0/8"
    source      = "0.0.0.0/0"
    tcp = {
      port_min        = 443
      port_max        = 443
      source_port_min = null
      source_port_max = null
    }
  }

  edge_network_acl = {
    name              = "edge-acl"
    resource_group_id = var.resource_group_id
    rules = flatten([
      [
        contains(local.vpn_firewall_types[var.vpn_firewall_type], "bastion")
        ? [local.allow_443_source_inbound_rule]
        : []
      ],
      [
        contains(local.vpn_firewall_types[var.vpn_firewall_type], "f5-external")
        ? [local.allow_443_inbound_rule]
        : []
      ],
      [
        for cidr in var.global_inbound_allow_list :
        {
          name        = "edge-allow-inbound-${index(var.global_inbound_allow_list, cidr) + 1}"
          action      = "allow"
          source      = cidr
          destination = "10.0.0.0/8"
          direction   = "inbound"
          tcp = {
            port_min        = null
            port_max        = null
            source_port_min = null
            source_port_max = null
          }
        }
      ],
      [
        for cidr in var.global_outbound_allow_list :
        {
          name        = "edge-allow-outbound-${index(var.global_outbound_allow_list, cidr) + 1}"
          action      = "allow"
          destination = cidr
          source      = "10.0.0.0/8"
          direction   = "outbound"
          tcp = {
            port_min        = null
            port_max        = null
            source_port_min = null
            source_port_max = null
          }
        }
      ],
      [
        for cidr in var.global_inbound_deny_list :
        {
          name        = "edge-deny-inbound-${index(var.global_inbound_deny_list, cidr) + 1}"
          action      = "deny"
          source      = cidr
          destination = "10.0.0.0/8"
          direction   = "inbound"
          tcp = {
            port_min        = null
            port_max        = null
            source_port_min = null
            source_port_max = null
          }
        }
      ],
      [
        for cidr in var.global_outbound_deny_list :
        {
          name        = "edge-deny-outbound-${index(var.global_outbound_deny_list, cidr) + 1}"
          action      = "deny"
          destination = cidr
          source      = "10.0.0.0/8"
          direction   = "outbound"
          tcp = {
            port_min        = null
            port_max        = null
            source_port_min = null
            source_port_max = null
          }
        }
      ],
    ])
  }
}

##############################################################################