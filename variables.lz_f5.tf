##############################################################################
#                                                                            #
#                       F5 BIG-IP Setup Variables                            #
#                                                                            #
##############################################################################

##############################################################################
# Edge VPC Variables
##############################################################################

variable "add_edge_vpc" {
  description = "Create an edge VPC network and resource group. Conflicts with `create_edge_network_on_management_vpc`."
  type        = bool
  default     = false
}

variable "create_edge_network_on_management_vpc" {
  description = "Create edge network components on management VPC and in management resource group. Conflicts with `add_edge_vpc`."
  type        = bool
  default     = false
}

variable "provision_f5_vsi" {
  description = "Create F5 VSI on edge VPC. To provision network without virtual server deployments, set to `false`."
  type        = bool
  default     = true
}

##############################################################################

##############################################################################
# Subnet Variables
##############################################################################

variable "f5_create_vpn_1_subnet_tier" {
  description = "Create VPN-1 subnet tier."
  type        = bool
  default     = true
}

variable "f5_create_vpn_2_subnet_tier" {
  description = "Create VPN-1 subnet tier."
  type        = bool
  default     = true
}

variable "f5_bastion_subnet_zones" {
  description = "Create Bastion subnet tier for each zone in this list. Bastion subnets created cannot exceed number of zones in `var.zones`. These subnets are reserved for future bastion VSI deployment."
  type        = number
  default     = 1

  validation {
    error_message = "Bastion subnet zones can be 0, 1, 2, or 3."
    condition     = var.f5_bastion_subnet_zones >= 0 && var.f5_bastion_subnet_zones < 4
  }
}

variable "vpn_firewall_type" {
  description = "F5 deployment type if provisioning edge VPC. Can be `full-tunnel`, `waf`, or `vpn-and-waf`."
  type        = string
  default     = "full-tunnel"

  validation {
    error_message = "Bastion type must be `full-tunnel`, `waf`, or `vpn-and-waf`."
    condition     = contains(["full-tunnel", "waf", "vpn-and-waf"], var.vpn_firewall_type)
  }
}

##############################################################################

##############################################################################
# VPE Services
##############################################################################

variable "f5_create_vpe_subnet_tier" {
  description = "Create VPE subnet tier on edge VPC. Will be automatically disabled for edge deployments on the management network."
  type        = bool
  default     = true
}

##############################################################################

##############################################################################
# F5 Variables
##############################################################################

variable "workload_cidr_blocks" {
  description = "List of workload CIDR blocks. This is used to create security group rules for the F5 management interface."
  type        = list(string)
  default     = []
}

variable "f5_image_name" {
  description = "Image name for f5 deployments. Must be null or one of `f5-bigip-15-1-5-1-0-0-14-all-1slot`,`f5-bigip-15-1-5-1-0-0-14-ltm-1slot`, `f5-bigip-16-1-2-2-0-0-28-ltm-1slot`,`f5-bigip-16-1-2-2-0-0-28-all-1slot`]."
  type        = string
  default     = "f5-bigip-16-1-2-2-0-0-28-all-1slot"

  validation {
    error_message = "Invalid F5 image name. Must be of `f5-bigip-15-1-5-1-0-0-14-all-1slot`,`f5-bigip-15-1-5-1-0-0-14-ltm-1slot`, `f5-bigip-16-1-2-2-0-0-28-ltm-1slot`,`f5-bigip-16-1-2-2-0-0-28-all-1slot`]."
    condition = contains(
      [
        "f5-bigip-15-1-5-1-0-0-14-all-1slot",
        "f5-bigip-15-1-5-1-0-0-14-ltm-1slot",
        "f5-bigip-16-1-2-2-0-0-28-ltm-1slot",
        "f5-bigip-16-1-2-2-0-0-28-all-1slot"
      ], var.f5_image_name
    )
  }
}

variable "f5_instance_profile" {
  description = "F5 vsi instance profile. Use the IBM Cloud CLI command `ibmcloud is instance-profiles` to see available image profiles."
  type        = string
  default     = "cx2-4x8"
}

variable "hostname" {
  description = "The F5 BIG-IP hostname"
  type        = string
  default     = "f5-ve-01"
}

variable "domain" {
  description = "The F5 BIG-IP domain name"
  type        = string
  default     = "local"
}

variable "default_route_interface" {
  description = "The F5 BIG-IP interface name for the default route. Leave null to auto assign."
  type        = string
  default     = null
}

variable "tmos_admin_password" {
  description = "admin account password for the F5 BIG-IP instance"
  type        = string
  sensitive   = true
  default     = null

  validation {
    error_message = "Value for tmos_password must be at least 15 characters, contain one numeric, one uppercase, and one lowercase character."
    condition = var.tmos_admin_password == null ? true : (
      length(var.tmos_admin_password) >= 15
      && can(regex("[A-Z]", var.tmos_admin_password))
      && can(regex("[a-z]", var.tmos_admin_password))
      && can(regex("[0-9]", var.tmos_admin_password))
    )
  }
}

variable "license_type" {
  description = "How to license, may be 'none','byol','regkeypool','utilitypool'"
  type        = string
  default     = "none"

  validation {
    error_message = "License type may be one of 'none','byol','regkeypool','utilitypool'."
    condition     = contains(["none", "byol", "regkeypool", "utilitypool"], var.license_type)
  }
}

variable "byol_license_basekey" {
  description = "Bring your own license registration key for the F5 BIG-IP instance"
  type        = string
  default     = null
}

variable "license_host" {
  description = "BIGIQ IP or hostname to use for pool based licensing of the F5 BIG-IP instance"
  type        = string
  default     = null
}

variable "license_username" {
  description = "BIGIQ username to use for the pool based licensing of the F5 BIG-IP instance"
  type        = string
  default     = null
}

variable "license_password" {
  description = "BIGIQ password to use for the pool based licensing of the F5 BIG-IP instance"
  type        = string
  default     = null
}

variable "license_pool" {
  description = "BIGIQ license pool name of the pool based licensing of the F5 BIG-IP instance"
  type        = string
  default     = null
}

variable "license_sku_keyword_1" {
  description = "BIGIQ primary SKU for ELA utility licensing of the F5 BIG-IP instance"
  type        = string
  default     = null
}

variable "license_sku_keyword_2" {
  description = "BIGIQ secondary SKU for ELA utility licensing of the F5 BIG-IP instance"
  type        = string
  default     = null
}

variable "license_unit_of_measure" {
  description = "BIGIQ utility pool unit of measurement"
  type        = string
  default     = "hourly"
}

variable "do_declaration_url" {
  description = "URL to fetch the f5-declarative-onboarding declaration"
  type        = string
  default     = "null"
}

variable "as3_declaration_url" {
  description = "URL to fetch the f5-appsvcs-extension declaration"
  type        = string
  default     = "null"
}

variable "ts_declaration_url" {
  description = "URL to fetch the f5-telemetry-streaming declaration"
  type        = string
  default     = "null"
}

variable "phone_home_url" {
  description = "The URL to POST status when BIG-IP is finished onboarding"
  type        = string
  default     = "null"
}

variable "template_source" {
  description = "The terraform template source for phone_home_url_metadata"
  type        = string
  default     = "f5devcentral/ibmcloud_schematics_bigip_multinic_declared"
}

variable "template_version" {
  description = "The terraform template version for phone_home_url_metadata"
  type        = string
  default     = "20210201"
}

variable "app_id" {
  description = "The terraform application id for phone_home_url_metadata"
  type        = string
  default     = "null"
}

variable "tgactive_url" {
  type        = string
  description = "The URL to POST L3 addresses when tgactive is triggered"
  default     = ""
}

variable "tgstandby_url" {
  description = "The URL to POST L3 addresses when tgstandby is triggered"
  type        = string
  default     = "null"
}

variable "tgrefresh_url" {
  description = "The URL to POST L3 addresses when tgrefresh is triggered"
  type        = string
  default     = "null"
}

variable "enable_f5_management_fip" {
  description = "Enable F5 management interface floating IP. Conflicts with `enable_f5_external_fip`, VSI can only have one floating IP per instance."
  type        = bool
  default     = false
}

variable "enable_f5_external_fip" {
  description = "Enable F5 external interface floating IP. Conflicts with `enable_f5_management_fip`, VSI can only have one floating IP per instance."
  type        = bool
  default     = false
}

##############################################################################