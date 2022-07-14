# IBM Cloud Solution Engineering Flexible VPC Network Template

Create flexible VPC networks in 1, 2, or 3 zones.

![ICSE Landing Zone](./images/3-zone.png)

---

## Table of Contents

1. [Resource Groups](#resource-groups)
    - [Default Resource Groups](#default-resource-groups)
    - [Using Existing Resource Groups](#using-existing-resource-groups)
2. [VPC Configuration](#vpc-configuration)
    - [Flexible Network Expansion](#easily-expand-your-architecturefrom-one-to-three-zones)
    - [Network Subnet CIDR Configuration](#network-subnet-cidr-configuration)
    - [Adding Public Gateways](#adding-public-gateways)
    - [Adding VPN Gateways](#adding-vpn-gateways)
3. [Transit Gateway](#transit-gateway)
4. [Network Access Control Lists](#network-access-control-lists)
    - [Cluster Rules](#cluster-rules)
    - [Detailed Network ACL Rules](#detailed-network-acl-rules)
8. [Naming Convention](#naming-convention)

---

## Resource Groups

This template has two options for resource groups, creating new groups for all infrastructure or using existing resource groups. Resource groups are handled in [resource_groups.tf](../resource_groups.tf).

### Default Resource Groups

By default, a resource group will be created for each vpc in the [vpc_names variable](../variables.tf#L44). The default value `["management", "workload"]` creates two VPCs, with a resource group for each of that VPC's components.

Cloud services will be provisioned in the name that is first in `vpc_names` and is considered to be the management resource group (regardless of name).

### Using Existing Resource Groups

To use existing resource groups as part of your architecture use the [existing_resource_groups variable](./variables.tf#L60). Each element in this list is matched to the corresponding VPC in `vpc_names`.

#### Using Existing Groups for All Resources

```terraform
vpc_names                = ["management", "workload"]
existing_resource_groups = ["existing-mgmt-rg", "existing-wkld-rg"]
```

#### Using Existing Groups for Some Resources

To create some resource groups but not others, use an empty string `""` in the matching VPC index in `existing_resource_groups`. This example shows creating a new management resource group while using an existing resource group for the workload VPC.

```terraform
vpc_names                = ["management", "workload"]
existing_resource_groups = ["", "existing-wkld-rg"]
```

---

## VPC Configuration

This template uses the following variables to configure Resource Groups, VPCs, network addresses, and subnet creation. A resource group will be dynamically created for each VPC.

Name                                | Type         | Description                                                                                                                                                                                  | Sensitive | Default
----------------------------------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------------------------------
zones                               | number       | Number of zones for each VPC. Can be 1, 2, or 3                                                                                                                                              |           | 3
vpc_names                           | list(string) | Names for VPCs to create. A resource group will be dynamically created for each VPC by default.                                                                                              |           | `["management", "workload"]`
vpc_subnet_tiers                    | list(string) | List of names for subnet tiers to add to each VPC. For each tier, a subnet will be created in each zone of each VPC. Each tier of subnet will have a unique access control list on each VPC. |           | `["vsi", "vpe"]`
vpc_subnet_tiers_add_public_gateway | list(string) | List of subnet tiers where a public gateway will be attached. Public gateways will be created in each VPC using these network tiers.                                                         |           | `["vpn"]`
vpcs_add_vpn_subnet                 | list(string) | List of VPCs to add a subnet and VPN gateway. VPCs must be defined in `var.vpc_names`. A subnet and address prefix will be added in zone 1 for the VPN Gateway.                              |           | `["management"]`

---

### Easily expand your architecturefrom one to three zones

Dynamically increase zones by increasing the `zones` variables. Networks are configured to ensure that network addresses within this template won't overlap.

One Zone | Three Zones
---------|-------------
![ICSE Landing Zone](./images/1-zone.png) | ![ICSE Landing Zone](./images/3-zone.png)

---

### Network Subnet CIDR Configuration

A subnet and network prefix are created for each subnet tier in `var.vpc_subnet_tiers` in each VPC. These subnets and network addresses dynamically created to allow for expansion and to ensure that network addresses don't overlap. Network addresses for each subnet tier are calculated using the following template:

```
10.x0.y0.0/24

x = (Index of VPC Name in `var.vpc_names` * 3) + zone
y = Index of subnet tier in `var.vpc_subnet_tiers` + 1
```

This formatting reserves IP Ranges to allow for adding additional zones in the future by increasing `var.zones` and additional subnet tiers by adding names to `var.vpc_subnet_tiers`

#### Two VPCs with two subnet tiers in a single zone

VPC        | Zone |  Subnet Tier | CIDR Block
-----------|------| -------------|----------
management | 1    |  vsi         | 10.10.10.0/24
management | 1    |  vpe         | 10.10.20.0/24
workload   | 1    |  vsi         | 10.40.10.0/24
workload   | 1    |  vpe         | 10.40.20.0/24

#### Two VPCs with two subnet tiers in three zones

VPC        | Zone |  Subnet Tier | CIDR Block
-----------|------| -------------|----------
management | 1    |  vsi         | 10.10.10.0/24
management | 1    |  vpe         | 10.10.20.0/24
management | 2    |  vsi         | 10.20.10.0/24
management | 2    |  vpe         | 10.20.20.0/24
management | 3    |  vsi         | 10.30.10.0/24
management | 3    |  vpe         | 10.30.20.0/24
workload   | 1    |  vsi         | 10.40.10.0/24
workload   | 1    |  vpe         | 10.40.20.0/24
workload   | 2    |  vsi         | 10.50.10.0/24
workload   | 2    |  vpe         | 10.50.20.0/24
workload   | 3    |  vsi         | 10.60.10.0/24
workload   | 3    |  vpe         | 10.60.20.0/24

---

### Adding Public Gateways

Public gateways can be attached to subnet tiers across each VPC by using the `vpc_subnet_tiers_add_public_gateway` variable. A public gateway will be created in each zone and will be attached to the desired subnets.

---

### Adding VPN Gateways

VPCs listed in the `vpcs_add_vpn_subnet` variable will have a subnet created in Zone 1 of that VPC, and a VPN Gateway created on that subnet. The CIDR block `10.0.x0.0/24` is reserved for VPN Gateways in each VPC.

---

## Transit Gateway

Use the following variables to manage Transit Gateway resources

Name                                | Type         | Description                                                                                                                                                                                  | Sensitive | Default
----------------------------------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------------------------------
enable_transit_gateway              | bool         | Create transit gateway                                                                                                                                                                       |           | true
transit_gateway_connections         | list(string) | List of VPC names from `var.vpc_names` to connect via a single transit gateway. To not use transit gateway, provide an empty list.                                                           |           | ["management", "workload"]

---

## Network Access Control Lists

A Network [Access Control List](https://cloud.ibm.com/docs/vpc?topic=vpc-using-acls) is created for each subnet tier in each VPC. Allow rules for all of these network ACLs are managed by the following variables:

Name                                | Type         | Description                                                                                                                                                                                  | Sensitive | Default
----------------------------------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------------------------------
add_cluster_rules                   | bool         | Automatically add needed ACL rules to allow each network to create and manage Openshift and IKS clusters.                                                                                    |           | true
global_inbound_allow_list           | list(string) | List of CIDR blocks where inbound traffic will be allowed. These allow rules will be added to each network acl.                                                                              |           | [ "10.0.0.0/8", "161.26.0.0/16" ]
global_outbound_allow_list          | list(string) | List of CIDR blocks where outbound traffic will be allowed. These allow rules will be added to each network acl.                                                                             |           | [ "0.0.0.0/0" ]
global_inbound_deny_list            | list(string) | List of CIDR blocks where inbound traffic will be denied. These deny rules will be added to each network acl. Deny rules will be added after all allow rules.                                |           | [ "0.0.0.0/0" ]
global_outbound_deny_list           | list(string) | List of CIDR blocks where outbound traffic will be denied. These deny rules will be added to each network acl. Deny rules will be added after all allow rules.                               |           | []

### Default Allow Rules

Name                                                     | CIDR            | Direction
---------------------------------------------------------|-----------------|----------
Allow all internal VPC network traffic                   | `10.0.0.0/8`    | Inbound
Allow inbound traffic from IBM private service endpoints | `161.26.0.0/16` | Inbound
Allow all outbound traffic                               | `0.0.0.0/0`     | Outbound

### Default Deny Rules

Name                                                     | CIDR            | Direction
---------------------------------------------------------|-----------------|----------
All not-allowed traffic                                  | `0.0.0.0/0`     | Inbound

---

### Cluster Rules

In order to make sure that clusters can be created on VPCs, by default the following rules are added to ACLs where clusters are provisioned. For more information about controlling OpenShift cluster traffic with ACLs, see the documentation [here](https://cloud.ibm.com/docs/openshift?topic=openshift-vpc-acls).

Rule                                               | Action | TCP / UDP | Direction | Source        | Source Port   | Destination   | Destination Port
---------------------------------------------------|--------|-----------|-----------|---------------|---------------|---------------|-------------------
Create Worker Nodes                                | Allow  | Any       | inbound   | 161.26.0.0/16 | any           | 10.0.0.0/8    | any
Communicate with Service Instances                 | Allow  | Any       | inbound   | 166.8.0.0/14  | any           | 10.0.0.0/8    | any
Allow Incling Application Traffic                  | Allow  | TCP       | inbound   | 10.0.0.0/8    | 30000 - 32767 | 10.0.0.0/8    | any
Expose Applications Using Load Balancer or Ingress | Allow  | TCP       | inbound   | 10.0.0.0/8    | any           | 10.0.0.0/8    | 443
Create Worker Nodes                                | Allow  | Any       | outbound  | 10.0.0.0/8    | any           | 161.26.0.0/16 | any
Communicate with Service Instances                 | Allow  | Any       | outbound  | 10.0.0.0/8    | any           | 166.8.0.0/14  | any
Allow Incling Application Traffic                  | Allow  | TCP       | outbound  | 10.0.0.0/8    | any           | 10.0.0.0/8    | 30000 - 32767
Expose Applications Using Load Balancer or Ingress | Allow  | TCP       | outbound  | 10.0.0.0/8    | 443           | 10.0.0.0/8    | any

---

### Detailed Network ACL Rules

Users can add custom rules to ACLs created by this template. For more information see [advanced setup](./advanced-setup.md#L21).

---

## Naming Convention

Each resource created using this template has the prefix in `var.prefix` prepended to the resource service instance name.

Resource Type                     | Name Format
----------------------------------|---------------
Resource Group                    | `<prefix>-<vpc_name>-rg`
Object Storage                    | `<prefix>-cos-<random_suffix>`
Object Storage Buckets            | `<prefix>-<vpc_name>-<flow-logs or atracker>-bucket-<random_suffix>`
Key Management                    | `<prefix>-kms`
Key Management Key                | `<prefix>-bucket-key`
Transit Gateway                   | `<prefix>-transit-gateway`
Transit Gateway Connections       | `<prefix>-<vpc_name>-hub-connection`
Public Gateways                   | `<prefix>-<vpc_name>-public-gateway-zone-<zone>`
Network ACLs                      | `<prefix>-<vpc_name>-<subnet_tier_name>-acl`
Subnets                           | `<prefix>-<vpc_name>-<subnet_tier_name>-<zone>`
VPN Gateways                      | `<prefix>-<vpc_name>-vpn-gateway`
VPCs                              | `<prefix>-<vpc_name>-vpc`
Flow Logs Collectors              | `<prefix>-<vpc_name>-flow-logs`
Atracker                          | `<prefix>-atracker`
Virtual Private Endpoint Gateways | `<prefix>-<vpc_name>-<service>-endpoint-gateway`