##############################################################################
# Teleport Variables
##############################################################################

variable "enable_teleport" {
  description = "Enable teleport VSI"
  type        = bool
  default     = true
}

variable "use_f5_bastion_subnets" {
  description = "Create teleport instances on the edge network subnets reserved for bastion hosts. Instances will only be created if `enable_teleport` is `true`."
  type        = bool
  default     = true
}

variable "teleport_vpc" {
  description = "Shortname of the VPC where teleport VSI will be provisioned. This value is ignored when `use_f5_bastion_subnets` is true."
  type        = string
  default     = "management"
}

variable "teleport_deployment_tier" {
  description = "Subnet tier where teleport VSI will be deployed. This value is ignored when `use_f5_bastion_subnets` is true."
  type        = string
  default     = "vsi"
}

variable "teleport_zones" {
  description = "Number of zones where teleport VSI will be provisioned. This value is ignored when `use_f5_bastion_subnets` is `true`."
  type        = number
  default     = 1

  validation {
    error_message = "Teleport zones must be 1, 2, or 3."
    condition     = var.teleport_zones > 0 && var.teleport_zones < 4
  }
}

##############################################################################

##############################################################################
# App ID Variables
##############################################################################

variable "appid_use_data" {
  description = "Get App ID information from data."
  type        = bool
  default     = false
}

variable "appid_name" {
  description = "App ID name. Use only if `use_data` is true."
  type        = string
  default     = null
}

variable "appid_resource_group_id" {
  description = "App ID resource group. Use only if `use_data` is true."
  type        = string
  default     = null
}

##############################################################################

##############################################################################
# Teleport Variables
##############################################################################

variable "teleport_profile" {
  description = "Machine type for Teleport VSI instances. Use the IBM Cloud CLI command `ibmcloud is instance-profiles` to see available image profiles."
  type        = string
  default     = "cx2-4x8"
}

variable "teleport_image_name" {
  description = "Teleport VSI image name. Use the IBM Cloud CLI command `ibmcloud is images` to see availabled images."
  type        = string
  default     = "ibm-ubuntu-18-04-6-minimal-amd64-2"
}

variable "teleport_add_floating_ip" {
  description = "Add a floating IP to the primary network interface for each server in the deployment."
  type        = bool
  default     = false
}

variable "teleport_license" {
  description = "The contents of the PEM license file"
  type        = string
  default     = null
}

variable "https_cert" {
  description = "The https certificate used by bastion host for teleport"
  type        = string
  default     = null
}

variable "https_key" {
  description = "The https private key used by bastion host for teleport"
  type        = string
  default     = null
}
variable "teleport_hostname" {
  description = "The name of the instance or bastion host"
  type        = string
  default     = null
}

variable "teleport_domain" {
  description = "The domain of the bastion host"
  type        = string
  default     = "domain.domain"
}

variable "teleport_version" {
  description = "Version of Teleport Enterprise to use"
  type        = string
  default     = "7.1.0"
}

variable "message_of_the_day" {
  description = "Banner message that is exposed to the user at authentication time"
  type        = string
  default     = null
}

variable "claims_to_roles" {
  description = "A list of maps that contain the user email and the role you want to associate with them"
  type = list(
    object({
      email = string
      roles = list(string)
    })
  )
  default = []
}

##############################################################################