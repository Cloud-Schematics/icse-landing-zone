##############################################################################
# Advanced Setup Module
##############################################################################

module "advanced_setup" {
  source                                       = "./advanced_setup"
  prefix                                       = var.prefix
  tags                                         = var.tags
  vpc_modules                                  = module.icse_vpc_network.vpc_networks
  resource_group_vpc_map                       = local.resource_group_vpc_map
  security_group_modules                       = module.security_groups
  clusters                                     = module.clusters
  cluster_subnets                              = module.cluster_subnets
  kms_instance_guid                            = module.icse_vpc_network.key_management_guid
  cluster_key_id                               = ibm_kms_key.cluster_key.key_id
  cluster_type                                 = var.cluster_type
  flavor                                       = var.flavor
  workers_per_zone                             = var.workers_per_zone
  entitlement                                  = var.entitlement
  template_ssh_key_id                          = local.template_ssh_key_id
  apply_new_rules_before_old_rules             = var.apply_new_rules_before_old_rules
  deny_all_tcp_ports                           = var.deny_all_tcp_ports
  deny_all_udp_ports                           = var.deny_all_udp_ports
  get_detailed_acl_rules_from_json             = var.get_detailed_acl_rules_from_json
  detailed_acl_rules                           = var.detailed_acl_rules
  use_worker_pool_json                         = var.use_worker_pool_json
  detailed_worker_pools                        = var.detailed_worker_pools
  use_quickstart_vsi_security_group_rules_json = var.use_quickstart_vsi_security_group_rules_json
  quickstart_vsi_detailed_security_group_rules = var.quickstart_vsi_detailed_security_group_rules
  use_security_group_json                      = var.use_security_group_json
  security_groups                              = var.security_groups
  use_detailed_vsi_deployment_json             = var.use_detailed_vsi_deployment_json
  detailed_vsi_deployments                     = var.detailed_vsi_deployments
}

##############################################################################