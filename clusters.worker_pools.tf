##############################################################################
# Create Auth Policy to allow containers to read from KMS to allow worker
# pools to be encrypted with key management keys
##############################################################################

resource "ibm_iam_authorization_policy" "easy_cluster_to_kms" {
  for_each = (
    # create if using worker pools
    length(var.worker_pool_names) > 0 || length(var.detailed_worker_pools) > 0 || var.use_worker_pool_json == true
    ? toset(["cluster-to-kms"])
    : toset([])
  )
  source_service_name         = "containers-kubernetes"
  target_service_name         = "kms"
  target_resource_instance_id = var.existing_hs_crypto_name == null ? module.icse_vpc_network.key_management_guid : "hs-crypto"
  roles                       = ["Reader", "Authorization Delegator"]
  description                 = "Allow cluster worker pools to be encrypted by Key Management instance."
}

##############################################################################

##############################################################################
# Create Worker Pools From List
##############################################################################

module "easy_worker_pool_map" {
  source = "github.com/Cloud-Schematics/list-to-map"
  list = flatten([
    for cluster in var.cluster_vpcs :
    [
      for pool in var.worker_pool_names :
      {
        name    = "${cluster}-${pool}"
        cluster = cluster
      }
    ]
  ])
}

module "easy_worker_pools" {
  source            = "github.com/Cloud-Schematics/icse-vpc-cluster-worker-pool-module"
  for_each          = module.easy_worker_pool_map.value
  prefix            = var.prefix
  pool_name         = each.key
  cluster_id        = module.clusters[each.value.cluster].cluster_id
  vpc_id            = module.icse_vpc_network.vpc_networks[each.value.cluster].id
  resource_group_id = local.resource_group_vpc_map[each.value.cluster]
  subnet_zone_list  = module.cluster_subnets[each.value.cluster].subnets
  flavor            = var.flavor
  workers_per_zone  = var.workers_per_zone
  entitlement       = var.cluster_type == "openshift" ? var.entitlement : null
  encryption_key_id = ibm_kms_key.cluster_key[0].key_id
  kms_instance_guid = module.icse_vpc_network.key_management_guid
}

##############################################################################