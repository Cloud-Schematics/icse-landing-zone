# Edge VPC Network and F5 BIG-IP

An edge VPC network and components for F5 BIG-IP can optionally be created for your network infrastructure deployment. This template uses the [ICSE F5 Deployment Module](https://github.com/Cloud-Schematics/icse-f5-deployment-module) to provision edge network components and F5 VSI.

![edge-f5-network](.docs/images/edge-f5.png)

---

## Table of Contents

1. [Prerequisites](#Prerequisites)
2. [Inherited Values](#inherited-values)
3. [Subnets](#subnets)
    - [Reserved Subnet Address Prefixes](#reserved-subnet-address-prefixes)
4. [Virtual Private Endpoints](#virtual-private-endpoints)
5. [Bastion Subnet Zones](#bastion-subnet-zones)
6. [Virtual Servers](#virutal-servers)
7. [F5 User Data Template Values](#f5-user-data-template-values)
8. [Security Groups](#security-groups)
    - [F5 Bastion Interface Security Group](#f5-bastion-interface-security-group)
    - [F5 External Security Group](#f5-external-security-group)
    - [F5 Management Security Group](#f5-management-security-group)
    - [F5 Workload Security Group](#f5-workload-security-group)
9. [Edge Network and F5 Variables](#edge-network-and-f5-variables)
10. [F5 and Edge Outputs]()

---

## Prerequisites

1. F5 BIG-IP Virtual Edition license.
2. Additional IAM VPC Infrastructure Service service access of `IP Spoofing operator`
3. [Contact support](https://cloud.ibm.com/unifiedsupport/cases/form) to increase the quota for subnets per VPC. The below chart shows the number of subnets needed dependent on the F5 BIG-IP deployment but it is best to ask for 30 subnets per VPC if using 3 zones. The chart below notes the CIDR blocks and the zones that each type is deployed. The `vpn-1`, `vpn-2`, `bastion`, and `vpe` subnet tiers can be disabled.

---

## Inherited Values

### Edge VPC Inherited Values

When creating a new Edge VPC, global ACL inbound and outbound rules are automatically applied to the Edge VPC ACL.

### Management VPC Inherited Values

Any public gateways provisioned using the management VPC will be automatically used by the edge network, only one public gateway per zone can be provisioned in a single VPC.

---

## Subnets

Subnets are created based on the number of zones in your VPC and the network configuration pattern from the [vpn_firewall_type variable](./variables.tf#L173). Supported patterns are `full-tunnel`, `waf`, and `vpn-and-waf`.

Name          | Zone 1 CIDR Block | Zone 2 CIDR Block | Zone 3 CIDR Block | WAF   | Full Tunnel   | VPN and WAF   | Variable
--------------| ------------------|-------------------|-------------------|:-----:|:-------------:|:-------------:| ---------
vpn-1         | 10.5.10.0/24      | 10.6.10.0/24      | 10.7.10.0/24      | ✅    | ✅             | ✅            | `create_vpn_1_subnet_tier`
vpn-2         | 10.5.20.0/24      | 10.6.20.0/24      | 10.7.20.0/24      | ✅    | ✅             | ✅            | `create_vpn_2_subnet_tier`
f5-management | 10.5.30.0/24      | 10.6.30.0/24      | 10.7.30.0/24      | ✅    | ✅             | ✅            | n/a
f5-external   | 10.5.40.0/24      | 10.6.40.0/24      | 10.7.40.0/24      | ✅    | ✅             | ✅            | n/a
f5-workload   | 10.5.50.0/24      | 10.6.50.0/24      | 10.7.50.0/24      | ✅    | ❌             | ✅            | n/a
f5-bastion    | 10.5.60.0/24      | 10.6.60.0/24      | 10.7.60.0/24      | ❌    | ✅             | ✅            | n/a
bastion       | 10.5.70.0/24      | 10.6.70.0/24      | 10.7.70.0/24      | ✅    | ✅             | ✅            | `bastion_subnet_zones`
vpe           | 10.5.80.0/24      | 10.6.80.0/24      | 10.7.80.0/24      | ✅    | ✅             | ✅            | `create_vpe_subnet_tier`

### Reserved Subnet Address Prefixes

To ensure proper provisioning on an existing VPC or are planning to connect your edge VPC to an existing transit gateway instance, ensure that the following subnet CIDR blocks are not currently in use by the network.

Zone | Prefix
-----|--------
1    | 10.5.0.0/16
2    | 10.6.0.0/16
3    | 10.7.0.0/16

---

## Virtual Private Endpoints

By setting the `f5_create_vpe_subnet_tier` virtual private endpoint gateways will be created on the Edge VPC for each service enabled for your main networks. This is automatically disabled when creating edge network components on the Management VPC).

---

## Flow Logs Collector

When creating a new edge VPC, a flow log collector bucket is created in the [Cloud Object Storage Config](../config.tf#L73). A flow log collector for the will be provisioned dynamically for the edge network.

---

## Bastion Subnet Zones

Users can create subnets reserved for bastion VSI deployments across 1, 2, or 3 zones. Bastion VSI zones will not be created if the number exceeds the `zones` variable.

Security group rules are dynamically added to the F5 management interface to allow for HTTPS and SSH connections from the bastion subnet tiers.

---

## Virutal Servers

F5 BIG-IP virtual servers are created dynamically based on the number of zones, template configuration, and desired pattern. The supported patterns are `full-tunnel`, `vpn`, and `waf`. A pattern must be selected using the [vpn_firewall_type variable](./variables.f5.tf#L70).

An encryption key will dynamically be created for the F5 servers using your chosen key management service.

--- 

## F5 User Data Template Values

The following variables are used to configure the F5 deployments onto the edge network virtual servers.

- The `tmos_admin_password` field must be at least 15 characters, contain one numberic, one uppercase, and one lowercase character.
- `license_type` must be `none`, `byol`, `regkeypool`, or `utilitypool`.

Name                    | Description                                                                    | Sensitive | Default
----------------------- | ------------------------------------------------------------------------------ | --------- | --------------------------------------------------------
hostname                | The F5 BIG-IP hostname                                                         |           | f5-ve-01
domain                  | The F5 BIG-IP domain name                                                      |           | local
default_route_interface | The F5 BIG-IP interface name for the default route. Leave null to auto assign. |           | null
tmos_admin_password     | admin account password for the F5 BIG-IP instance                              | true      | null
license_type            | How to license, may be 'none','byol','regkeypool','utilitypool'                |           | none
byol_license_basekey    | Bring your own license registration key for the F5 BIG-IP instance             |           | null
license_host            | BIGIQ IP or hostname to use for pool based licensing of the F5 BIG-IP instance |           | null
license_username        | BIGIQ username to use for the pool based licensing of the F5 BIG-IP instance   |           | null
license_password        | BIGIQ password to use for the pool based licensing of the F5 BIG-IP instance   |           | null
license_pool            | BIGIQ license pool name of the pool based licensing of the F5 BIG-IP instance  |           | null
license_sku_keyword_1   | BIGIQ primary SKU for ELA utility licensing of the F5 BIG-IP instance          |           | null
license_sku_keyword_2   | BIGIQ secondary SKU for ELA utility licensing of the F5 BIG-IP instance        |           | null
license_unit_of_measure | BIGIQ utility pool unit of measurement                                         |           | hourly
do_declaration_url      | URL to fetch the f5-declarative-onboarding declaration                         |           | null
as3_declaration_url     | URL to fetch the f5-appsvcs-extension declaration                              |           | null
ts_declaration_url      | URL to fetch the f5-telemetry-streaming declaration                            |           | null
phone_home_url          | The URL to POST status when BIG-IP is finished onboarding                      |           | null
template_source         | The terraform template source for phone_home_url_metadata                      |           | f5devcentral/ibmcloud_schematics_bigip_multinic_declared
template_version        | The terraform template version for phone_home_url_metadata                     |           | 20210201
app_id                  | The terraform application id for phone_home_url_metadata                       |           | null
tgactive_url            | The URL to POST L3 addresses when tgactive is triggered                        |           | 
tgstandby_url           | The URL to POST L3 addresses when tgstandby is triggered                       |           | null
tgrefresh_url           | The URL to POST L3 addresses when tgrefresh is triggered                       |           | null

---

## Security Groups

Security groups are dynamically created for F5 VSI interfaces. Configuration for these security groups can be found in [f5_security_group_config.tf](./f5_security_group_config.tf). Security groups are created in [main.tf](./main.tf#L50). Security groups are created **before** provisioning of virtual server instances.

---

### F5 Bastion Interface Security Group

This security group is created when using an F5 pattern that supports VPN. The following security group rules are added to each `f5-bastion` interface for each `bastion` subnet tier provisioned.

Protocol | Direction | Remote              | Source Port | Destination Port | Allow / Deny
---------|-----------|---------------------|-------------|------------------|---------------
TCP      | Inbound   | Bastion Subnet CIDR | 3023 - 3025 | Any              | Allow
TCP      | Inbound   | Bastion Subnet CIDR | 3080        | Any              | Allow
TCP      | Outbound  | Bastion Subnet CIDR | Any         | 3023 - 3025      | Allow
TCP      | Outbound  | Bastion Subnet CIDR | Any         | 3080             | Allow

---

### F5 External Security Group

This security group is created and attached to the `f5-external` VSI interface with the following rule:

Protocol | Direction | Remote              | Source Port | Destination Port | Allow / Deny
---------|-----------|---------------------|-------------|------------------|---------------
TCP      | Inbound   | 0.0.0.0/0           | Any         | 443              | Allow
TCP      | Outbound  | 0.0.0.0/0           | 443         | Any              | Allow

---

### F5 Management Security Group

This security group is created for and attached to the `f5-management` VSI interface. Rules marked with a `*` will have multiple rules created based on the number of bastion subnets created.

Protocol | Direction | Remote                                    | Source Port | Destination Port | Allow / Deny
---------|-----------|-------------------------------------------|-------------|------------------|---------------
TCP      | Outbound  | Each Bastion Subnet CIDR*                 | Any         | 443              | Allow
TCP      | Outbound  | Each Bastion Subnet CIDR*                 | Any         | 22               | Allow
Any      | Inbound   | IBM Internal Service CIDR (161.26.0.0/16) | Any         | Any              | Allow
TCP      | Outbound  | IBM Internal Service CIDR (161.26.0.0/16) | Any         | 443              | Allow
TCP      | Outbound  | IBM Internal Service CIDR (161.26.0.0/16) | Any         | 80               | Allow
TCP      | Outbound  | IBM Internal Service CIDR (161.26.0.0/16) | Any         | 53               | Allow
Any      | Inbound   | VPC Internal Traffic (10.0.0.0/8)         | Any         | Any              | Allow
Any      | Outbound  | VPC Internal Traffic (10.0.0.0/8)         | Any         | Any              | Allow

---

### F5 Workload Security Group

The `f5-workload` security group is created for patterns using `waf`. The following networking rules are created for the workload VSI interfaces. Rules marked with a `*` will have multiple rules created based on the [workload_cidr_blocks variable](./variables.tf#L220).

Protocol | Direction | Remote                                    | Source Port | Destination Port | Allow / Deny
---------|-----------|-------------------------------------------|-------------|------------------|---------------
TCP      | Outbound  | Each Workload Subnet CIDR*                | Any         | 443              | Allow
Any      | Inbound   | IBM Internal Service CIDR (161.26.0.0/16) | Any         | Any              | Allow
TCP      | Outbound  | IBM Internal Service CIDR (161.26.0.0/16) | Any         | 443              | Allow
TCP      | Outbound  | IBM Internal Service CIDR (161.26.0.0/16) | Any         | 80               | Allow
TCP      | Outbound  | IBM Internal Service CIDR (161.26.0.0/16) | Any         | 53               | Allow
Any      | Inbound   | VPC Internal Traffic (10.0.0.0/8)         | Any         | Any              | Allow
Any      | Outbound  | VPC Internal Traffic (10.0.0.0/8)         | Any         | Any              | Allow

---

## Edge Network and F5 Variables

Name                                  | Type   | Description                                                                                                                                                                                                  | Sensitive | Default
------------------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------- | --------------------------------------------------------
add_edge_vpc                          | bool   | Create an edge VPC network and resource group. Conflicts with `create_edge_network_on_management_vpc`.                                                                                                       |           | true
create_edge_network_on_management_vpc | bool   | Create edge network components on management VPC and in management resource group. Conflicts with `add_edge_vpc`.                                                                                            |           | false
f5_create_vpn_1_subnet_tier           | bool   | Create VPN-1 subnet tier.                                                                                                                                                                                    |           | true
f5_create_vpn_2_subnet_tier           | bool   | Create VPN-1 subnet tier.                                                                                                                                                                                    |           | true
f5_bastion_subnet_zones               | number | Create Bastion subnet tier for each zone in this list. Bastion subnets created cannot exceed number of zones in `var.zones`. These subnets are reserved for future bastion VSI deployment.                   |           | 1
f5_create_vpe_subnet_tier             | bool   | Create VPE subnet tier on edge VPC. Will be automatically disabled for edge deployments on the management network.                                                                                           |           | true
vpn_firewall_type                     | string | F5 deployment type if provisioning edge VPC. Can be `full-tunnel`, `waf`, or `vpn-and-waf`.                                                                                                                  |           | full-tunnel
f5_image_name                         | string | Image name for f5 deployments. Must be null or one of `f5-bigip-15-1-5-1-0-0-14-all-1slot`,`f5-bigip-15-1-5-1-0-0-14-ltm-1slot`, `f5-bigip-16-1-2-2-0-0-28-ltm-1slot`,`f5-bigip-16-1-2-2-0-0-28-all-1slot`]. |           | f5-bigip-16-1-2-2-0-0-28-all-1slot
f5_instance_profile                   | string | F5 vsi instance profile. Use the IBM Cloud CLI command `ibmcloud is instance-profiles` to see available image profiles.                                                                                      |           | cx2-4x8
hostname                              | string | The F5 BIG-IP hostname                                                                                                                                                                                       |           | f5-ve-01
domain                                | string | The F5 BIG-IP domain name                                                                                                                                                                                    |           | local
default_route_interface               | string | The F5 BIG-IP interface name for the default route. Leave null to auto assign.                                                                                                                               |           | null
tmos_admin_password                   | string | admin account password for the F5 BIG-IP instance                                                                                                                                                            | true      | null
license_type                          | string | How to license, may be 'none','byol','regkeypool','utilitypool'                                                                                                                                              |           | none
byol_license_basekey                  | string | Bring your own license registration key for the F5 BIG-IP instance                                                                                                                                           |           | null
license_host                          | string | BIGIQ IP or hostname to use for pool based licensing of the F5 BIG-IP instance                                                                                                                               |           | null
license_username                      | string | BIGIQ username to use for the pool based licensing of the F5 BIG-IP instance                                                                                                                                 |           | null
license_password                      | string | BIGIQ password to use for the pool based licensing of the F5 BIG-IP instance                                                                                                                                 |           | null
license_pool                          | string | BIGIQ license pool name of the pool based licensing of the F5 BIG-IP instance                                                                                                                                |           | null
license_sku_keyword_1                 | string | BIGIQ primary SKU for ELA utility licensing of the F5 BIG-IP instance                                                                                                                                        |           | null
license_sku_keyword_2                 | string | BIGIQ secondary SKU for ELA utility licensing of the F5 BIG-IP instance                                                                                                                                      |           | null
license_unit_of_measure               | string | BIGIQ utility pool unit of measurement                                                                                                                                                                       |           | hourly
do_declaration_url                    | string | URL to fetch the f5-declarative-onboarding declaration                                                                                                                                                       |           | null
as3_declaration_url                   | string | URL to fetch the f5-appsvcs-extension declaration                                                                                                                                                            |           | null
ts_declaration_url                    | string | URL to fetch the f5-telemetry-streaming declaration                                                                                                                                                          |           | null
phone_home_url                        | string | The URL to POST status when BIG-IP is finished onboarding                                                                                                                                                    |           | null
template_source                       | string | The terraform template source for phone_home_url_metadata                                                                                                                                                    |           | f5devcentral/ibmcloud_schematics_bigip_multinic_declared
template_version                      | string | The terraform template version for phone_home_url_metadata                                                                                                                                                   |           | 20210201
app_id                                | string | The terraform application id for phone_home_url_metadata                                                                                                                                                     |           | null
tgactive_url                          | string | The URL to POST L3 addresses when tgactive is triggered                                                                                                                                                      |           | 
tgstandby_url                         | string | The URL to POST L3 addresses when tgstandby is triggered                                                                                                                                                     |           | null
tgrefresh_url                         | string | The URL to POST L3 addresses when tgrefresh is triggered                                                                                                                                                     |           | null
enable_f5_management_fip              | bool   | Enable F5 management interface floating IP. Conflicts with `enable_f5_external_fip`, VSI can only have one floating IP per instance.                                                                         |           | false
enable_f5_external_fip                | bool   | Enable F5 external interface floating IP. Conflicts with `enable_f5_management_fip`, VSI can only have one floating IP per instance.                                                                         |           | false

---

## F5 and Edge Outputs

Name                | Description
------------------- | -------------------------------------------------------------------------------
f5_vpc_id           | ID of edge VPC
f5_network_acl      | Network ACL name and ID
f5_public_gateways  | Edge VPC public gateways
f5_subnet_zone_list | List of subnet ids, cidrs, names, and zones.
f5_subnet_tiers     | Map of subnet tiers where each key contains the subnet zone list for that tier.
f5_security_groups  | List of security groups created.
f5_virtual_servers  | List of virtual servers created by this module.