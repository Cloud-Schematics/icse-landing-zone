##############################################################################
# VPC Outputs
##############################################################################

output "vpc_networks" {
  description = "VPC network information"
  value       = module.icse_vpc_network.vpc_networks
}

output "vpc_flow_logs_data" {
  description = "Information for Connecting VPC to flow logs using ICSE Flow Logs Module"
  value       = module.icse_vpc_network.vpc_flow_logs_data
}

output "vpc_network_acls" {
  description = "List of network ACLs"
  value       = module.advanced_setup.all_network_acl_list
}

##############################################################################

##############################################################################
# Key Management Outputs
##############################################################################

output "key_management_name" {
  description = "Name of key management service"
  value       = module.icse_vpc_network.key_management_name
}

output "key_management_crn" {
  description = "CRN for KMS instance"
  value       = module.icse_vpc_network.key_management_crn
}

output "key_management_guid" {
  description = "GUID for KMS instance"
  value       = module.icse_vpc_network.key_management_guid
}

output "key_rings" {
  description = "Key rings created by module"
  value       = module.icse_vpc_network.key_rings
}

output "keys" {
  description = "List of names and ids for keys created."
  value       = module.icse_vpc_network.keys
}

##############################################################################

##############################################################################
# Cloud Object Storage Outputs
##############################################################################

output "cos_instances" {
  description = "List of COS resource instances with shortname, name, id, and crn."
  value       = module.icse_vpc_network.cos_instances
}

output "cos_buckets" {
  description = "List of COS bucket instances with shortname, instance_shortname, name, id, crn, and instance id."
  value       = module.icse_vpc_network.cos_buckets
}

##############################################################################

##############################################################################
# Secrets Manager Outputs
##############################################################################

output "secrets_manager_name" {
  description = "Name of secrets manager instance"
  value       = module.icse_vpc_network.secrets_manager_name
}

output "secrets_manager_id" {
  description = "id of secrets manager instance"
  value       = module.icse_vpc_network.secrets_manager_id
}

output "secrets_manager_guid" {
  description = "guid of secrets manager instance"
  value       = module.icse_vpc_network.secrets_manager_guid
}

##############################################################################

##############################################################################
# Cluster Outputs
##############################################################################

output "cluster_list" {
  description = "ID, name, crn, ingress hostname, private service endpoint url, public service endpoint url of each cluster"
  value = [
    for cluster in module.clusters :
    {
      name                         = cluster.cluster_name
      crn                          = cluster.cluster_crn
      id                           = cluster.cluster_id
      ingress_hostname             = cluster.ingress_hostname
      private_service_endpoint_url = cluster.private_service_endpoint_url
      public_service_endpoint_url  = cluster.public_service_endpoint_url
    }
  ]
}

##############################################################################

##############################################################################
# VSI Outputs
##############################################################################

output "vsi_data" {
  description = "List of VSI data"
  value = [
    for deployment in module.vsi_deployment_map.value :
    {
      deployment_name       = "${deployment.name}-vsi"
      virtual_servers       = module.vsi_deployment[deployment.name].virtual_servers
      public_load_balancer  = module.vsi_deployment[deployment.name].public_load_balancer
      private_load_balancer = module.vsi_deployment[deployment.name].private_load_balancer
      security_group_id     = module.security_groups[deployment.name].groups[0].id
    }
  ]
}

output "custom_vsi_data" {
  description = "List of VSI data"
  value       = module.advanced_setup.custom_vsi_data
}

##############################################################################

##############################################################################
# Security Group Outputs
##############################################################################

output "security_groups" {
  description = "List of security groups created by this template"
  value = flatten([
    [
      for group in module.vsi_deployment_map.value :
      module.security_groups[group.name].groups
    ],
    module.advanced_setup.security_groups
  ])
}

##############################################################################

##############################################################################
# Edge Outputs
##############################################################################

output "f5_vpc_id" {
  description = "ID of edge VPC"
  value       = local.enable_f5 == true ? module.f5[0].vpc_id : null
}

output "f5_network_acl" {
  description = "Network ACL name and ID"
  value       = local.enable_f5 == true ? module.f5[0].network_acl : null
}

output "f5_public_gateways" {
  description = "Edge VPC public gateways"
  value       = local.enable_f5 == true ? module.f5[0].public_gateways : null
}

output "f5_subnet_zone_list" {
  description = "List of subnet ids, cidrs, names, and zones."
  value       = local.enable_f5 == true ? module.f5[0].subnet_zone_list : null
}

output "f5_subnet_tiers" {
  description = "Map of subnet tiers where each key contains the subnet zone list for that tier."
  value       = local.enable_f5 == true ? module.f5[0].subnet_tiers : null
}

output "f5_security_groups" {
  description = "List of security groups created."
  value       = local.enable_f5 == true ? module.f5[0].security_groups : null
}

output "f5_virtual_servers" {
  description = "List of virtual servers created by this module."
  value       = local.enable_f5 == true ? module.f5[0].virtual_servers : null
}

##############################################################################

##############################################################################
# App ID Outputs
##############################################################################

output "appid_guid" {
  description = "App ID GUID"
  value       = var.enable_teleport == true ? module.teleport_vsi[0].appid_guid : null
}

output "appid_crn" {
  description = "App ID CRN"
  value       = var.enable_teleport == true ? module.teleport_vsi[0].appid_crn : null
}

output "appid_redirect_urls" {
  description = "List of App ID redirect URLs"
  value       = var.enable_teleport == true ? module.teleport_vsi[0].appid_redirect_urls : null
}

##############################################################################

##############################################################################
# Teleport VSI Outputs
##############################################################################

output "teleport_virtual_servers" {
  description = "List of VSI IDs, Names, Primary IPV4 addresses, floating IPs, and secondary floating IPs"
  value       = var.enable_teleport == true ? module.teleport_vsi[0].virtual_servers : null
}

##############################################################################