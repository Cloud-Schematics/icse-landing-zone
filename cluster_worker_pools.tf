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
  source = "./config_modules/list_to_map"
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
  encryption_key_id = ibm_kms_key.cluster_key.key_id
  kms_instance_guid = module.icse_vpc_network.key_management_guid
  depends_on        = [ibm_iam_authorization_policy.easy_cluster_to_kms]
}

##############################################################################

##############################################################################
# Detailed Worker Pools
##############################################################################

locals {
  worker_pool_json = jsondecode(file("./json-config/template-worker-pools.json"))
}

module "detailed_worker_pool_map" {
  source         = "./config_modules/list_to_map"
  list           = var.use_worker_pool_json ? local.worker_pool_json : var.detailed_worker_pools
  key_name_field = "pool_name"
}

module "detailed_worker_pools" {
  source            = "github.com/Cloud-Schematics/icse-vpc-cluster-worker-pool-module"
  for_each          = module.detailed_worker_pool_map.value
  prefix            = var.prefix
  entitlement       = var.cluster_type == "openshift" ? var.entitlement : null
  cluster_id        = module.clusters[each.value.cluster_vpc].cluster_id
  vpc_id            = module.icse_vpc_network.vpc_networks[each.value.cluster_vpc].id
  resource_group_id = local.resource_group_vpc_map[each.value.cluster_vpc]
  subnet_zone_list  = module.cluster_subnets[each.value.cluster_vpc].subnets
  pool_name         = each.value.pool_name
  flavor            = lookup(each.value, "flavor", null) == null ? var.flavor : each.value.flavor
  workers_per_zone  = lookup(each.value, "workers_per_zone", null) == null ? var.workers_per_zone : each.value.workers_per_zone
  encryption_key_id = lookup(each.value, "encryption_key_id", null) == null ? ibm_kms_key.cluster_key.key_id : each.value.encryption_key_id
  kms_instance_guid = lookup(each.value, "kms_instance_guid", null) == null ? module.icse_vpc_network.key_management_guid : each.value.kms_instance_guid
  depends_on        = [ibm_iam_authorization_policy.easy_cluster_to_kms]
}

##############################################################################