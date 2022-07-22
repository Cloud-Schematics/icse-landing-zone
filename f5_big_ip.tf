
##############################################################################
# Optionally provision Edge network / F5
##############################################################################

locals {
  # if either edge vpc added or edge network on management, create
  enable_f5 = var.add_edge_vpc == true || var.create_edge_network_on_management_vpc == true

  # Set resource group based on VPC. Management if management, edge if edge
  edge_resource_group_id = (
    var.create_edge_network_on_management_vpc == true
    ? local.management_rg
    : var.add_edge_vpc == true
    ? local.resource_group_vpc_map["edge"]
    : null
  )

  # Get public gateways if provisioning on management
  edge_public_gateways = (
    # if using management pass empty gatewats
    var.create_edge_network_on_management_vpc != true
    ? {
      zone-1 = null
      zone-2 = null
      zone-3 = null
    }
    # othewsie get management vpc gateways
    : module.icse_vpc_network.vpc_networks[var.vpc_names[0]].public_gateways
  )

  # Edge flow logs bucket name if not on management
  edge_flow_logs_bucket_name = (
    # if edge is true, lookup bucket name from output array, otherwise null
    var.add_edge_vpc == true ? [
      # get edge flow log bucket name
      for bucket in module.icse_vpc_network.cos_buckets :
      bucket.name if bucket.shortname == "edge-flow-logs-bucket"
    ][0] : null
  )
}

##############################################################################

##############################################################################
# F5 & Edge Network Deployment
##############################################################################

module "f5" {
  count                        = local.enable_f5 ? 1 : 0
  source                       = "github.com/Cloud-Schematics/icse-f5-deployment-module"
  prefix                       = var.prefix
  region                       = var.region
  tags                         = var.tags
  zones                        = var.zones
  global_inbound_allow_list    = var.global_inbound_allow_list
  global_outbound_allow_list   = var.global_outbound_allow_list
  global_inbound_deny_list     = var.global_inbound_deny_list
  global_outbound_deny_list    = var.global_outbound_deny_list
  create_vpn_1_subnet_tier     = var.f5_create_vpn_1_subnet_tier
  create_vpn_2_subnet_tier     = var.f5_create_vpn_2_subnet_tier
  bastion_subnet_zones         = var.f5_bastion_subnet_zones
  vpn_firewall_type            = var.vpn_firewall_type
  provision_f5_vsi             = var.provision_f5_vsi
  create_vpe_subnet_tier       = var.create_edge_network_on_management_vpc == true ? false : var.f5_create_vpe_subnet_tier
  vpe_services                 = var.vpe_services
  f5_image_name                = var.f5_image_name
  profile                      = var.f5_instance_profile
  enable_f5_management_fip     = var.enable_f5_management_fip
  enable_f5_external_fip       = var.enable_f5_external_fip
  create_flow_logs_collector   = var.add_edge_vpc
  flow_logs_bucket_name        = local.edge_flow_logs_bucket_name
  ssh_key_ids                  = [local.template_ssh_key_id]
  kms_guid                     = module.icse_vpc_network.key_management_guid
  resource_group_id            = local.edge_resource_group_id
  existing_public_gateways     = local.edge_public_gateways
  key_management_endpoint_type = var.key_management_endpoint_type
  create_encryption_key        = true
  f5_template_data = {
    domain                  = var.domain
    hostname                = var.hostname
    default_route_interface = var.default_route_interface
    tmos_admin_password     = var.tmos_admin_password
    license_type            = var.license_type
    byol_license_basekey    = var.byol_license_basekey
    license_host            = var.license_host
    license_username        = var.license_username
    license_password        = var.license_password
    license_pool            = var.license_pool
    license_sku_keyword_1   = var.license_sku_keyword_1
    license_sku_keyword_2   = var.license_sku_keyword_2
    license_unit_of_measure = var.license_unit_of_measure
    do_declaration_url      = var.do_declaration_url
    as3_declaration_url     = var.as3_declaration_url
    ts_declaration_url      = var.ts_declaration_url
    phone_home_url          = var.phone_home_url
    template_source         = var.template_source
    template_version        = var.template_version
    app_id                  = var.app_id
    tgstandby_url           = var.tgstandby_url
    tgactive_url            = var.tgactive_url
    tgrefresh_url           = var.tgrefresh_url
  }
}

##############################################################################

##############################################################################
# Create Transit Gateway Connection if enabled
##############################################################################

resource "ibm_tg_connection" "edge_connection" {
  count        = var.add_edge_vpc == true && var.enable_transit_gateway == true ? 1 : 0
  gateway      = module.icse_vpc_network.transit_gateway_id
  network_type = "vpc"
  name         = "${var.prefix}-edge-hub-connection"
  network_id   = module.f5[0].vpc_crn
  timeouts {
    create = "30m"
    delete = "30m"
  }
}

##############################################################################