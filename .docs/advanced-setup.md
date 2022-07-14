# ICSE Landing Zone Advanced Setup

Advanced setup options for ICSE Landing Zone.

---

## Table of Contents

1. [Customixing Network ACLs](#customizing-network-acls)
2. [Worker Pools](#worker-pools)
    - [Detailed Worker Pools Using HCL](#detailed-worker-pools-using-hcl)
    - [Detailed Worker Pools Using JSON](#detailed-worker-pools-using-json)
3. [Customizing VSI and VPE Security Groups](#customizing-vsi-and-vpe-security-groups)
    - [Custom Security Group Rule Schema](#custom-rules-schema)
4. [Creating Custom VSI Deployments](#creating-custom-vsi-deployments)
    - [Custom Virtual Deployment Schema](#custom-virtual-deployment-schema)
5. [Security Groups](#security-groups)

---

## Customizing Network ACLs

This template allows users to optionally use the [detailed network acl rules module](https://github.com/Cloud-Schematics/detailed-network-acl-rules/detailed_acl_rules_module) to allow for fine-grained network allow rules.

Using this module, users can:
- Add rules to VPC ACLs to deny inbound and outbound traffic on any `tcp` or `udp` ports.
- Define any number of custom rules using HCL and the [detailed_acl_rules variable](../variables.advanced.tf.tf#35)
- Define any number of custom rules using JSON by adding them to [acl-rules.json](../advanced_setup/json-config/template-acl-rules.json) and setting the [get_detailed_acl_rules_from_json variable](../variables.tf#L210) to true.
    - This option is good for Schematics users, as it prevents needing to copy and paste HCL values into the GUI.

### Detailed Network ACL Rule Variables


Name                             | Description                                                                                                                                                                                                               | Default
-------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------
network_acls                     | Network ACLs to retrieve from data. This data is intended to be retrieved from the `vpc_network_acls` output from the ICSE Flexible VPC Network template (https://github.com/Cloud-Schematics/easy-flexible-vpc-network). | []
network_cidr                     | CIDR block to use as the source for global outbound rules and destination for global inbound rules.                                                                                                                       | 10.0.0.0/8
apply_new_rules_before_old_rules | When set to `true`, any new rules to be applied to existing Network ACLs will be added **before** existing rules and after any detailed rules that will be added. Otherwise, rules will be added after.                   | true
deny_all_tcp_ports               | Deny all inbound and outbound TCP traffic on each port in this list.                                                                                                                                                      | [22, 80]
deny_all_udp_ports               | Deny all inbound and outbound UDP traffic on each port in this list.                                                                                                                                                      | [22, 80]
get_detailed_acl_rules_from_json | Decode local file `acl_rules.json` for the automated creation of Network ACL rules.                                                                                                                                       | true
acl_rule_json                    | Decoded filedata for ACL rules                                                                                                                                                                                            | null
detailed_acl_rules               | List describing network ACLs and rules to add.                                                                                                                                                                            |


---

## Worker Pools

Worker pools can be configured either using HCL or JSON. To use JSON configuration set [use_worker_pool_json variable](../variables.advanced.tf#L83) to `true`.

### Detailed Worker Pools Using HCL

Detailed worker pools can be configured using the [detailed_worker_pools variable](../variables.advanced.tf#L89).

```terraform
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
  ...
}
```

---

### Detailed Worker Pools Using JSON

Worker pools can also be defined using the HCL schema by adding them into [template-worker-pools.json](../advanced_setup/json-config/template-worker-pools.json).

---

## Customizing VSI and VPE Security Groups

Users can customize security groups created for Quick Start VSI and VPEs with detailed networking rules by using:
 - HCL using [quickstart_vsi_detailed_security_group_rules variable](../variables.advanced.tf#L126) 
 - JSON unsing the [template-quickstart-security-group-rules.json](../advanced_setup/json-config/template-quickstart-security-group-rules.json) file by setting `use_quickstart_vsi_security_group_rules_json` to `true`.

Custom security group rules are managed in [/advanced_setup/security_group_rules.tf](../advanced_setup/security_group_rules.tf).

### Custom Rules Schema

Both HCL and JSON detailed rules use the same schema

```terraform
variable "quickstart_vsi_detailed_security_group_rules" {
  type = list(
    object({
      security_group_shortname = string # Shortname of security group ex. "workload-vsi-sg"
      # List of security group rules to create
      rules = list(
        object({
          name      = string # name
          direction = string # inbound or outbound
          remote    = string # CIDR block or IP address
          # Optionally create TCP, UDP or ICMP. Only one block can be set per rule
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
```
---

## Creating Custom VSI Deployments

Users can used advanced setup to create custom virtual server deployments. Custom virtual server workloads can be deployed using:
- HCL and the [detailed_vsi_deployments variable](../variables.advanced.tf#L223)
- JSON using the [template-virtual-servers.json file](./json-config/template-virtual-servers.json) and setting `use_detailed_vsi_deployment_json` to true.

### Custom Virtual Deployment Schema

Both HCL and JSON use the same schema for custom VSI deployments:

```terraform
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
```

---

## Security Groups

Users can create security groups for use with custom virtual server deployments. Security groups can be created using two methods:
- HCL using the [security_groups variable](../variables.advanced.tf#L173)
- JSON using the [template-security-groups.json file](../advanced_setup/json-config/template-security-groups.json) and setting the `use_security_group_json` variable to `true`.

Thos module uses the [ICSE VPC Security Group Module](github.com/Cloud-Schematics/vpc-security-group-module) to create security groups.

---

### Security Group Schema

Both HCL and JSON use the same schema for custom security groups

```terraform
  list(
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
```