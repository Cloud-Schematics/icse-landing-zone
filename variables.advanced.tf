##############################################################################
#                                                                            #
#                       Advanced Setup Variables                             #
#                                                                            #
##############################################################################

##############################################################################
# (Optional) Detailed Network ACL Variables
##############################################################################

variable "apply_new_rules_before_old_rules" {
  description = "When set to `true`, any new rules to be applied to existing Network ACLs will be added **before** existing rules and after any detailed rules that will be added. Otherwise, rules will be added after."
  type        = bool
  default     = true
}

variable "deny_all_tcp_ports" {
  description = "Deny all inbound and outbound TCP traffic on each port in this list."
  type        = list(number)
  default     = []
}

variable "deny_all_udp_ports" {
  description = "Deny all inbound and outbound UDP traffic on each port in this list."
  type        = list(number)
  default     = []
}

variable "get_detailed_acl_rules_from_json" {
  description = "Decode local file `acl-rules.json` for the automated creation of Network ACL rules. If this is set to `false`, detailed_acl_rules will be used instead."
  type        = bool
  default     = false
}

variable "detailed_acl_rules" {
  description = "OPTIONAL - List describing network ACLs and rules to add."
  type = list(
    object({
      acl_shortname = string
      rules = list(
        object({
          shortname   = string
          action      = string
          direction   = string
          add_first   = optional(bool)
          destination = optional(string)
          source      = optional(string)
          tcp = optional(
            object({
              port_max        = optional(number)
              port_min        = optional(number)
              source_port_max = optional(number)
              source_port_min = optional(number)
            })
          )
          udp = optional(
            object({
              port_max        = optional(number)
              port_min        = optional(number)
              source_port_max = optional(number)
              source_port_min = optional(number)
            })
          )
          icmp = optional(
            object({
              type = optional(number)
              code = optional(number)
            })
          )
        })
      )
    })
  )
  default = []
}

##############################################################################

##############################################################################
# (Optional) Advanced Worker Pools
##############################################################################

variable "use_worker_pool_json" {
  description = "Use detailed JSON information for the creation of worker pools from JSON. Conflicts with `detailed_worker_pools`."
  type        = bool
  default     = false
}

variable "detailed_worker_pools" {
  description = "OPTIONAL - Detailed worker pool configruation. Conflicts with `use_worker_pool_json`."
  type = list(
    object({
      pool_name   = string # Prefix will be prepended onto the pool name
      cluster_vpc = string # name of the vpc where the cluster is provisioned. used to reference cluster dynamically 
      # the folowing will default to the cluster values if not otherwise provided
      resource_group_id = optional(string)
      flavor            = optional(string)
      workers_per_zone  = optional(number)
      encryption_key_id = optional(string)
      kms_instance_guid = optional(string)
    })
  )
  default = []
  validation {
    error_message = "Each worker pool must have a unique name."
    condition = (
      length(var.detailed_worker_pools) == 0
      ? true
      : length(var.detailed_worker_pools.*.pool_name) == length(distinct(var.detailed_worker_pools.*.pool_name))
    )
  }
}

##############################################################################

##############################################################################
# (Optional) Quickstart VPC Networking Variables
##############################################################################

variable "use_quickstart_vsi_security_group_rules_json" {
  description = "Get JSON data from `template-quickstart-security-group-rules.json` and add to security groups. Conflicts with `quickstart_vsi_detailed_security_group_rules`."
  type        = bool
  default     = false
}

variable "quickstart_vsi_detailed_security_group_rules" {
  description = "Manage additional security group rules on quickstart VSI deployments. Conflicts with `use_quickstart_vsi_security_group_rules_json`."
  type = list(
    object({
      security_group_shortname = string
      rules = list(
        object({
          name      = string
          direction = string
          remote    = string
          tcp = optional(
            object({
              port_max = optional(number)
              port_min = optional(number)
            })
          )
          udp = optional(
            object({
              port_max = optional(number)
              port_min = optional(number)
            })
          )
          icmp = optional(
            object({
              type = optional(number)
              code = optional(number)
            })
          )
        })
      )
    })
  )
  default = []
}

##############################################################################

##############################################################################
# (Optional) Detailed Security Groups
##############################################################################

variable "use_security_group_json" {
  description = "Use JSON to create additional security groups. If true, groups in `var.security_groups` will not be created."
  type        = bool
  default     = true
}

variable "security_groups" {
  description = "List of security groups to create."
  type = list(
    object({
      vpc_name          = string           # VPC from var.vpc_names.
      name              = string           # Security group name. Prefix will be prepended 
      resource_group_id = optional(string) # groups will be added to the same resource group as VPC if null
      rules = list(
        object({
          name      = string
          direction = string
          remote    = string
          tcp = optional(
            object({
              port_max = optional(number)
              port_min = optional(number)
            })
          )
          udp = optional(
            object({
              port_max = optional(number)
              port_min = optional(number)
            })
          )
          icmp = optional(
            object({
              type = optional(number)
              code = optional(number)
            })
          )
        })
      )
    })
  )
  default = []
}

##############################################################################

##############################################################################
# (Optional) Detailed Virtual Server Deployments
##############################################################################

variable "use_detailed_vsi_deployment_json" {
  description = "Use detailed JSON information for the creation of VSI deployments from JSON. If true, will not use `detailed_vsi_deployments`."
  type        = bool
  default     = false
}

variable "detailed_vsi_deployments" {
  description = "OPTIONAL - Detailed list of virtual server deployments."
  type = list(
    object({
      deployment_name                  = string                 # name to use for the deployment
      image_name                       = string                 # name of the image
      vsi_per_subnet                   = number                 # number of VSI per subnet to create
      profile                          = string                 # vsi profile
      vpc_name                         = string                 # shortname of VPC to use
      zones                            = number                 # number of zones
      subnet_tiers                     = list(string)           # list of subnet tiers for deployments
      ssh_key_ids                      = list(string)           # existing ssh key ids. to use template ssh_key set to ["default"]
      resource_group_id                = optional(string)       # if null, default to VPC rg
      primary_security_group_ids       = optional(list(string)) # ids of existing groups to use
      secondary_subnet_tiers           = optional(list(string)) # list of secondary subnet tiers
      boot_volume_encryption_key       = optional(string)       # crn of key management key
      user_data                        = optional(string)       # arbitrary user data
      allow_ip_spoofing                = optional(bool)         # allow spoofing on primary network interface
      add_floating_ip                  = optional(bool)         # add floating IPs to interface
      secondary_floating_ips           = optional(list(string)) # list of secondary interfaces to add fip
      availability_policy_host_failure = optional(string)       # availability policy
      boot_volume_name                 = optional(string)       # override default boot volume name
      boot_volume_size                 = optional(number)       # default boot volume size
      dedicated_host                   = optional(string)       # dedicated host id
      metadata_service_enabled         = optional(bool)         # enable metadata sevice
      placement_group                  = optional(string)       # placement group id
      default_trusted_profile_target   = optional(string)       # profile target id
      dedicated_host_group             = optional(string)       # dedicated host id
      ##############################################################################
      # List of block storage volumes. Each volume in this list will be attached
      # to each VSI in the deployment
      ##############################################################################
      block_storage_volumes = optional(
        list(
          object({
            name                 = string
            profile              = string
            capacity             = optional(number)
            iops                 = optional(number)
            encryption_key       = optional(string)
            delete_all_snapshots = optional(bool)
          })
        )
      )
      ##############################################################################
      create_public_load_balancer      = optional(bool)         # Create public load balancer
      create_private_load_balancer     = optional(bool)         # Create privare load balancer
      load_balancer_security_group_ids = optional(list(string)) # security group IDs 
      pool_algorithm                   = optional(string)
      pool_protocol                    = optional(string)
      pool_health_delay                = optional(number)
      pool_health_retries              = optional(number)
      pool_health_timeout              = optional(number)
      pool_health_type                 = optional(string)
      pool_member_port                 = optional(number)
      listener_port                    = optional(number)
      listener_protocol                = optional(string)
      listener_connection_limit        = optional(number)
      ##############################################################################
      # List of security group names. Security group names must be specified in    #
      # either var.security_groups or ./json-config/template-virtual-servers.json  #
      # Servers can only be added to security groups in the same VPC               #
      ##############################################################################
      primary_security_group_names       = optional(list(string)) # for primary network interface
      load_balancer_security_group_names = optional(list(string)) # for load balancers
      ##############################################################################
    })
  )
  default = []
}

##############################################################################