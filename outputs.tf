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
  value       = local.all_network_acl_list
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
      security_group_id     = module.vsi_security_groups[deployment.name].groups[0].id
    }
  ]
}

output "custom_vsi_data" {
  description = "List of VSI data"
  value = [
    for deployment in module.custom_vsi_map.value :
    {
      deployment_name       = deployment.deployment_name
      virtual_servers       = module.custom_deployments[deployment.deployment_name].virtual_servers
      public_load_balancer  = module.custom_deployments[deployment.deployment_name].public_load_balancer
      private_load_balancer = module.custom_deployments[deployment.deployment_name].private_load_balancer
    }
  ]
}

##############################################################################

##############################################################################
# Security Group Outputs
##############################################################################

output security_groups {
  description = "List of security groups created by this template"
  value       = flatten([
    [
      for group in module.vsi_deployment_map.value:
      module.vsi_security_groups[group.name].groups
    ],
    [
      for group in module.security_group_map.value:
      module.security_groups[group.name].groups
    ]
  ])
}

##############################################################################