##############################################################################
# Template Variables
##############################################################################
ibmcloud_api_key = "<your api key>"
region           = "<ibm cloud region>"
prefix           = "icse-lz"
tags             = ["icse", "landing-zone"]
zones            = 3
##############################################################################

##############################################################################
# VPC Variables
##############################################################################
vpc_names                           = ["management", "workload"]
vpc_subnet_tiers                    = ["vsi", "vpe"]
vpc_subnet_tiers_add_public_gateway = ["vpn"]
vpcs_add_vpn_subnet                 = ["management"]
enable_transit_gateway              = true
transit_gateway_connections         = ["management", "workload"]
##############################################################################

##############################################################################
# Network ACL Variables
##############################################################################
add_cluster_rules          = true
global_inbound_allow_list  = ["10.0.0.0/8", "161.26.0.0/16"]
global_outbound_allow_list = ["0.0.0.0/0"]
global_inbound_deny_list   = ["0.0.0.0/0"]
global_outbound_deny_list  = []
##############################################################################

##############################################################################
# Cloud Service Variables
##############################################################################
existing_hs_crypto_name           = null # if null, Key Protect will be created
existing_hs_crypto_resource_group = null
enable_atracker                   = true
add_atracker_route                = false
cos_use_random_suffix             = true
create_secrets_manager            = false
##############################################################################

##############################################################################
# Virtual Private Endpoint Variables
##############################################################################
enable_virtual_private_endpoints         = true
vpe_services                             = ["cloud-object-storage", "kms"]
vpcs_create_endpoint_gateway_on_vpe_tier = ["management", "workload"]
##############################################################################

##############################################################################
# (Optional) Quickstart Cluster Variables
##############################################################################
cluster_type                    = "openshift"
cluster_vpcs                    = []
cluster_subnet_tier             = []
cluster_zones                   = 3
kube_version                    = "default"
flavor                          = "bx2.16x64"
workers_per_zone                = 2
wait_till                       = "IngressReady"
update_all_workers              = false
disable_public_service_endpoint = false
entitlement                     = null
worker_pool_names               = []
##############################################################################

##############################################################################
# (Optional) Quickstart Virtual Server Variables
##############################################################################
ssh_public_key                     = null
use_ssh_key_data                   = null
vsi_vpcs                           = ["workload"]
vsi_subnet_tier                    = ["vsi"]
vsi_per_subnet                     = 1
vsi_zones                          = 3
image_name                         = "ibm-ubuntu-18-04-6-minimal-amd64-3"
profile                            = "bx2-2x8"
quickstart_vsi_inbound_allow_list  = ["10.0.0.0/8", "161.26.0.0/16"]
quickstart_vsi_outbound_allow_list = ["0.0.0.0/0"]
##############################################################################

##############################################################################
#                                                                            #
#                              Advanced Setup                                #
#                                                                            #
##############################################################################

##############################################################################
# (Optional) Advanced ACL Variables
##############################################################################
apply_new_rules_before_old_rules = true
deny_all_tcp_ports               = []
deny_all_udp_ports               = []
get_detailed_acl_rules_from_json = false
detailed_acl_rules               = []
##############################################################################

##############################################################################
# (Optional) Advanced Worker Pool Setup
##############################################################################
use_worker_pool_json  = false
detailed_worker_pools = []
##############################################################################

##############################################################################
# (Optional) Advanced VSI Setup
##############################################################################
use_quickstart_vsi_security_group_rules_json = false
quickstart_vsi_detailed_security_group_rules = []
use_security_group_json                      = false
security_groups                              = []
use_detailed_vsi_deployment_json             = false
detailed_vsi_deployments                     = []
##############################################################################