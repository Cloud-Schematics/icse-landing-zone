##############################################################################
# Find valid IKS/ROKS Cluster versions for region
##############################################################################

data "ibm_container_cluster_versions" "cluster_versions" {
  count = length(var.cluster_vpcs) > 0 ? 1 : 0
}

##############################################################################

##############################################################################
# Default Kube Version Local
##############################################################################

locals {
  default_kube_version = {
    openshift = (
      length(var.cluster_vpcs) == 0 # if no clusters null, otherwise get latest
      ? null
      : "${data.ibm_container_cluster_versions.cluster_versions[0].valid_openshift_versions[length(data.ibm_container_cluster_versions.cluster_versions[0].valid_openshift_versions) - 1]}_openshift"
    )
    iks = (
      length(var.cluster_vpcs) == 0 # if no clusters null, otherwise get latest
      ? null
      : data.ibm_container_cluster_versions.cluster_versions[0].valid_kube_versions[length(data.ibm_container_cluster_versions.cluster_versions[0].valid_kube_versions) - 1]
    )
  }
}

##############################################################################

##############################################################################
# Get Cluster Subnets
##############################################################################

module "cluster_subnets" {
  source           = "./config_modules/get_subnets"
  for_each         = toset(var.cluster_vpcs)
  subnet_zone_list = module.icse_vpc_network.vpc_networks[each.key].subnet_zone_list
  regex = join("|",
    flatten(
      [
        # For each tier in cluster subnet tiers
        for tier in var.cluster_subnet_tier :
        [
          # for each zone in cluster zones (starting at 1 and ending at max 3)
          for zone in range(1, var.cluster_zones + 1) :
          "-${tier}-${zone}" # Create expression for each zone joined with a pipe |
        ]
      ]
    )
  )
}

##############################################################################

##############################################################################
# Create Cluster KMS Key
##############################################################################

resource "ibm_kms_key" "cluster_key" {
  instance_id   = module.icse_vpc_network.key_management_guid
  key_name      = "${var.prefix}-cluster-key"
  standard_key  = false
  endpoint_type = "public" # Use public endpoint to allow for creation on local machine
}

##############################################################################

##############################################################################
# Create Clusters
##############################################################################

module "clusters" {
  source                          = "github.com/Cloud-Schematics/icse-cluster-module"
  for_each                        = toset(var.cluster_vpcs)
  region                          = var.region
  prefix                          = var.prefix
  tags                            = var.tags
  disable_public_service_endpoint = var.disable_public_service_endpoint
  entitlement                     = var.entitlement
  update_all_workers              = var.update_all_workers
  machine_type                    = var.flavor
  workers_per_zone                = var.workers_per_zone
  wait_till                       = var.wait_till
  kube_version                    = var.kube_version == "default" ? local.default_kube_version[var.cluster_type] : var.kube_version
  pod_subnet                      = null
  service_subnet                  = null
  vpc_id                          = module.icse_vpc_network.vpc_networks[each.key].id
  resource_group_id               = local.resource_group_vpc_map[each.key]
  subnet_zone_list                = module.cluster_subnets[each.key].subnets
  cos_instance_crn                = module.icse_vpc_network.cos_instances[0].crn
  kms_config = {
    use_key_protect  = true
    instance_guid    = module.icse_vpc_network.key_management_guid
    private_endpoint = true
    key_id           = ibm_kms_key.cluster_key.key_id
  }
}

##############################################################################