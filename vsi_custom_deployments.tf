##############################################################################
# Create Map of Detailed Deployments
##############################################################################

locals {
  vsi_json = jsondecode(file("./json-config/template-virtual-servers.json"))
}

module "custom_vsi_map" {
  source = "./config_modules/list_to_map"
  list = (
    var.use_detailed_vsi_deployment_json != true
    ? var.detailed_vsi_deployments
    : concat(local.vsi_json, var.detailed_vsi_deployments)
  )
  key_name_field = "deployment_name"
}

##############################################################################

##############################################################################
# Get Subnets for Detailed Deployments
##############################################################################

module "custom_vsi_subnets" {
  source           = "./config_modules/get_subnets"
  for_each         = module.custom_vsi_map.value
  subnet_zone_list = module.icse_vpc_network.vpc_networks[each.value.vpc_name].subnet_zone_list
  regex = join("|",
    flatten(
      [
        # For each tier in vsi subnet tiers
        for tier in each.value.subnet_tiers :
        [
          # for each zone in vsi zones (starting at 1 and ending at max 3)
          for zone in range(1, each.value.zones + 1) :
          "-${tier}-${zone}" # Create expression for each zone joined with a pipe |
        ]
      ]
    )
  )
}

module "custom_vsi_secondary_subnets" {
  source           = "./config_modules/get_subnets"
  for_each         = module.custom_vsi_map.value
  subnet_zone_list = module.icse_vpc_network.vpc_networks[each.value.vpc_name].subnet_zone_list
  regex = join("|",
    flatten(
      [
        # For each tier in vsi subnet tiers
        for tier in each.value.secondary_subnet_tiers :
        [
          # for each zone in vsi zones (starting at 1 and ending at max 3)
          for zone in range(1, each.value.zones + 1) :
          "-${tier}-${zone}" # Create expression for each zone joined with a pipe |
        ]
      ]
    )
  )
}

##############################################################################

##############################################################################
# Create Deployments
##############################################################################

module "custom_deployments" {
  source                           = "github.com/Cloud-Schematics/icse-vsi-deployment"
  for_each                         = module.custom_vsi_map.value
  prefix                           = var.prefix
  tags                             = var.tags
  vpc_id                           = module.icse_vpc_network.vpc_networks[each.value.vpc_name].id
  subnet_zone_list                 = module.custom_vsi_subnets[each.key].subnets
  secondary_subnet_zone_list       = module.custom_vsi_secondary_subnets[each.key].subnets
  deployment_name                  = "${each.value.vpc_name}-${each.key}"
  resource_group_id                = lookup(each.value, "resource_group_id", null)
  vsi_per_subnet                   = lookup(each.value, "vsi_per_subnet", null)
  ssh_key_ids                      = [
    for ssh_key in each.value.ssh_key_ids:
    ssh_key == "default" ? local.template_ssh_key_id : ssh_key
  ]
  image_name                       = lookup(each.value, "image_name", null)
  profile                          = lookup(each.value, "profile", null)
  boot_volume_encryption_key       = lookup(each.value, "boot_volume_encryption_key", null)
  user_data                        = lookup(each.value, "user_data", null)
  allow_ip_spoofing                = lookup(each.value, "allow_ip_spoofing", null)
  add_floating_ip                  = lookup(each.value, "add_floating_ip", null)
  availability_policy_host_failure = lookup(each.value, "availability_policy_host_failure", null)
  boot_volume_name                 = lookup(each.value, "boot_volume_name", null)
  boot_volume_size                 = lookup(each.value, "boot_volume_size", null)
  dedicated_host                   = lookup(each.value, "dedicated_host", null)
  dedicated_host_group             = lookup(each.value, "dedicated_host_group", null)
  default_trusted_profile_target   = lookup(each.value, "default_trusted_profile_target", null)
  metadata_service_enabled         = lookup(each.value, "metadata_service_enabled", null)
  placement_group                  = lookup(each.value, "placement_group", null)
  load_balancer_security_group_ids = lookup(each.value, "load_balancer_security_group_ids", null)
  listener_connection_limit        = lookup(each.value, "listener_connection_limit", null)
  ##############################################################################
  # To ensure valid configuration these the default for each of these values   #
  # is used instead of `null`.                                                 #
  ##############################################################################
  primary_security_group_ids = (
    lookup(each.value, "primary_security_group_ids", null) == null
    && lookup(each.value, "primary_security_group_names", null) == null
    ? null
    : concat(
      lookup(each.value, "primary_security_group_ids", null) == null ? [] : each.value.primary_security_group_ids,
      lookup(each.value, "primary_security_group_names", null) == null ? [] : [
        for group in each.value.primary_security_group_names :
        module.security_groups[group].groups[0].id
      ]
    )
  )
  block_storage_volumes        = lookup(each.value, "block_storage_volumes", null) == null ? [] : each.value.block_storage_volumes
  secondary_floating_ips       = lookup(each.value, "secondary_floating_ips", null) == null ? [] : each.value.secondary_floating_ips
  create_public_load_balancer  = lookup(each.value, "create_public_load_balancer", null) == null ? false : each.value.create_public_load_balancer
  create_private_load_balancer = lookup(each.value, "create_private_load_balancer", null) == null ? false : each.value.create_private_load_balancer
  pool_algorithm               = lookup(each.value, "pool_algorithm", null) == null ? "round_robin" : each.value.pool_algorithm
  pool_protocol                = lookup(each.value, "pool_protocol", null) == null ? "http" : each.value.pool_protocol
  pool_health_delay            = lookup(each.value, "pool_health_delay", null) == null ? 60 : each.value.pool_health_delay
  pool_health_retries          = lookup(each.value, "pool_health_retries", null) == null ? 5 : each.value.pool_health_retries
  pool_health_timeout          = lookup(each.value, "pool_health_timeout", null) == null ? 30 : each.value.pool_health_timeout
  pool_health_type             = lookup(each.value, "pool_health_type", null) == null ? "http" : each.value.pool_health_type
  pool_member_port             = lookup(each.value, "pool_member_port", null) == null ? 8080 : each.value.pool_member_port
  listener_port                = lookup(each.value, "listener_port", null) == null ? 80 : each.value.listener_port
  listener_protocol            = lookup(each.value, "listener_protocol", null) == null ? "http" : each.value.listener_protocol
  ##############################################################################
}

##############################################################################