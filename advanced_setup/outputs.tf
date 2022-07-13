##############################################################################
# Security Group Outputs
##############################################################################

output "security_groups" {
  description = "List of security groups created by this template"
  value = [
    for group in module.security_group_map.value :
    module.security_groups[group.name].groups
  ]
}

##############################################################################

##############################################################################
# VSI Outputs
##############################################################################

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
# Network ACL Outputs
##############################################################################

output "all_network_acl_list" {
  description = "List of all network ACLs"
  value       = local.all_network_acl_list
}

##############################################################################