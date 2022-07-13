
##############################################################################
# Detailed Worker Pools
##############################################################################

locals {
  worker_pool_json = jsondecode(file("${path.module}/json-config/template-worker-pools.json"))
}

module "detailed_worker_pool_map" {
  source         = "github.com/Cloud-Schematics/list-to-map"
  list           = var.use_worker_pool_json ? local.worker_pool_json : var.detailed_worker_pools
  key_name_field = "pool_name"
}

module "detailed_worker_pools" {
  source            = "github.com/Cloud-Schematics/icse-vpc-cluster-worker-pool-module"
  for_each          = module.detailed_worker_pool_map.value
  prefix            = var.prefix
  entitlement       = var.cluster_type == "openshift" ? var.entitlement : null
  resource_group_id = var.resource_group_vpc_map[each.value.cluster_vpc]
  vpc_id            = var.vpc_modules[each.value.cluster_vpc].id
  cluster_id        = var.clusters[each.value.cluster_vpc].cluster_id
  subnet_zone_list  = var.cluster_subnets[each.value.cluster_vpc].subnets
  pool_name         = each.value.pool_name
  flavor            = lookup(each.value, "flavor", null) == null ? var.flavor : each.value.flavor
  workers_per_zone  = lookup(each.value, "workers_per_zone", null) == null ? var.workers_per_zone : each.value.workers_per_zone
  encryption_key_id = lookup(each.value, "encryption_key_id", null) == null ? var.cluster_key_id : each.value.encryption_key_id
  kms_instance_guid = lookup(each.value, "kms_instance_guid", null) == null ? var.kms_instance_guid : each.value.kms_instance_guid
}

##############################################################################