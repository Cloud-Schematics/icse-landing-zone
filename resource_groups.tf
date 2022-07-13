
##############################################################################
# Create Resource Groups
##############################################################################

locals {
  # Set of resource groups to create
  create_resource_group_set = toset(
    length(var.existing_resource_groups) == 0 # If not using existing resource groups
    ? var.vpc_names                           # use VPC name
    : [
      # Otherwise for each name in vpc names return the name if the corresponding index
      # in existing resource groups is empty string ""
      for name in var.vpc_names :
      name if var.existing_resource_groups[index(var.vpc_names, name)] == ""
    ]
  )
}

resource "ibm_resource_group" "resource_group" {
  for_each = local.create_resource_group_set
  name     = "${var.prefix}-${each.key}-rg"
}

##############################################################################

##############################################################################
# Existing Resource Groups
##############################################################################

locals {
  # Create a list of distinct resource groups from existing resource group
  # list if the group is not an empty string
  existing_resource_group_set = toset(
    distinct([
      for group in var.existing_resource_groups :
      group if group != ""
    ])
  )
}

data "ibm_resource_group" "existing_resource_group" {
  for_each = local.existing_resource_group_set
  name     = each.key
}

##############################################################################

##############################################################################
# Map Resource Group IDs to VPC Names
##############################################################################

locals {
  resource_group_vpc_map = {
    # for each network 
    for network in var.vpc_names :
    # Set name to resource group id
    (network) => (
      # If no existing resource groups
      length(var.existing_resource_groups) == 0
      # lookup network from created rgs
      ? ibm_resource_group.resource_group[network].id
      # if existing resource group is empty string
      : var.existing_resource_groups[index(var.vpc_names, network)] == ""
      # lookup network from created rgs
      ? ibm_resource_group.resource_group[network].id
      # otherwise lookup rg from data block based on index
      : data.ibm_resource_group.existing_resource_group[
        var.existing_resource_groups[index(var.vpc_names, network)]
      ].id
    )
  }
}

##############################################################################