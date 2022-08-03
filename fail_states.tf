##############################################################################
# Configuration Failure States
##############################################################################

locals {
  # fail configuration if virtual private endpoints are enabled and `vpe` tier is not in tier list.
  CONFIGURATION_FAILURE_vpe_tier_not_found = regex("true", var.enable_virtual_private_endpoints != true ? true : contains(var.vpc_subnet_tiers, "vpe"))
  # fail if cluster subnet tier not found
  CONFIGURATION_FAILURE_cluster_tier_not_found_in_tier_list = regex(
    "true",
    length(var.cluster_vpcs) == 0
    ? true
    : length([
      for tier in var.cluster_subnet_tier :
      true if !contains(var.vpc_subnet_tiers, tier)
    ]) == 0
  )
  # fail if OpenShift cluster does not have enough workers
  CONFIGURATION_FAILURE_openshift_cluster_needs_2_workers = regex(
    "true",
    var.cluster_type != "openshift"
    ? true
    : length(var.cluster_vpcs) == 0
    ? true
    : var.cluster_zones * var.workers_per_zone >= 2
  )
  # Fail if no VSI ssh key
  CONFIGURATION_FAILURE_no_ssh_key_provided = regex(
    "true",
    length(var.vsi_vpcs) == 0 || var.vsi_subnet_tier == 0 || var.vsi_per_subnet == 0
    ? true
    : var.ssh_public_key != null || var.use_ssh_key_data != null
  )
  # fail if vsi subnet tier not found
  CONFIGURATION_FAILURE_vsi_tier_not_found_in_tier_list = regex(
    "true",
    length(var.vsi_vpcs) == 0
    ? true
    : length([
      for tier in var.vsi_subnet_tier :
      true if !contains(var.vpc_subnet_tiers, tier)
    ]) == 0
  )
  # Fail if add edge and create edge true
  CONFIGURATION_FAILURE_both_edge_and_management_vpc_provided = regex(
    false,
    var.add_edge_vpc == true && var.create_edge_network_on_management_vpc == true
  )

  # fail if teleport vpc not found
  CONFIGURATION_FAILURE_teleport_vpc_not_found = regex(
    true,
    var.enable_teleport == false || (    # if teleport is disabled or
      var.enable_teleport == true        # if teleport is eabled 
      && var.f5_bastion_subnet_zones > 0 # At lease one bastion zone is provided
      # and edge VPC is enabled
      && (var.add_edge_vpc == true || var.create_edge_network_on_management_vpc == true)
    )
    ? true
    : contains(var.vpc_names, var.teleport_vpc)
  )

  # fail if teleport subnet tier not found
  CONFIGURATION_FAILURE_teleport_vsi_tier_not_found_in_tier_list = regex(
    "true",
    var.enable_teleport == false || (    # if teleport is disabled or
      var.enable_teleport == true        # if teleport is eabled 
      && var.f5_bastion_subnet_zones > 0 # At lease one bastion zone is provided
      # and edge VPC is enabled
      && (var.add_edge_vpc == true || var.create_edge_network_on_management_vpc == true)
    )
    ? true
    : contains(var.vpc_subnet_tiers, var.teleport_deployment_tier)
  )
}

##############################################################################