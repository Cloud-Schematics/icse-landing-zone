# Cloud Services

This template creates the following resources:
- Key Protect
- Cloud Object Storage

These resources are created in the management resource group, the resource group where components for the first VPC in `var.vpc_names`.

---

## Table of Contents

1. [Cloud Services](#cloud-services)
    - [Key Management](#key-management)
        - [Using HPCS](#optional-use-an-existing-hyper-protect-crypto-services-instance-for-key-management)
    - [Cloud Object Storage](#cloud-object-storage)
6. [Logging and Monitoring](#logging-and-monitoring) 
    - [Flow Logs Collectors](#flow-logs-collectors)
    - [Atracker](#atracker)
7. [Virtual Private Endpoints](#virtual-private-endpoints)

---

### Key Management

This module by default creates a single Key Protect instance and an encryption key used for each Object Storage bucket created. A service authorization is also created to allow keys from this instance to be used to enrypt Block Storage for VPC.

#### (Optional) Use an existing Hyper Protect Crypto Services instance for key management

The following variables can be used to have keys and service authorizations use an existing HPCS instance.

Name                                | Type         | Description                                                                                                                                                                                  | Sensitive | Default
----------------------------------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------------------------------
existing_hs_crypto_name             | string       | OPTIONAL - Get data for an existing HPCS instance. If you want a KMS instance to be created, leave as `null`.                                                                                |           | null
existing_hs_crypto_resource_group   | string       | OPTIONAL - Resource group name for an existing HPCS instance. Use only with `existing_hs_crypto_name`.                                                                                       |           | null

---

### Cloud Object Storage

This template creates a single Cloud Object Storage instance. A service authorization policy is created to allow Object Storage buckets to be encrypted with the key management key. To prevent duplicate resource names, a randomized suffix can be added to all Object Storage resources by setting the `cos_use_random_suffix` variable to `true`.

#### Object Storage Buckets

An object storage bucket is created for each VPC for Flow Logs storage. If enabled, a bucket is also created for Atracker storage. Each bucket is encrypted using the key management encryption key.

---

## Logging and Monitoring

This template uses [Atracker](https://cloud.ibm.com/docs/activity-tracker?topic=activity-tracker-at_events) and [Flow Logs](https://cloud.ibm.com/docs/vpc?topic=vpc-flow-logs) for logging and monitoring services at the VPC level.

### Flow Logs Collectors

When each VPC is created it is attached to a Flow Logs Collector. Logs are stored in the corresponding Object Storage bucket.

### Atracker

By setting the `enable_atracker` variable to `true`, an Atracker target will be created. To add a route for Atracker, set the `add_atracker_route` variable to `true`. 

---

## Virtual Private Endpoints

Set the `enable_virtual_private_endpoints` variable to `true` to enable the creation of Virtual Private Endpoints for cloud servies. This template uses the [ICSE VPE Module](github.com/Cloud-Schematics/vpe-module) to create Reserved IPs and Gateways.

### Example Architecture with Enabled VPE

![vpn-nw](.docs/vpe-nw.png)

### VPE Varaibles

Name                                     | Type         | Description                                                                                            | Sensitive | Default
---------------------------------------- | ------------ | ------------------------------------------------------------------------------------------------------ | --------- | -------------------------------
enable_virtual_private_endpoints         | bool         | Enable virtual private endpoints.                                                                      |           | false
vpe_services                             | list(string) | List of VPE Services to use to create endpoint gateways.                                               |           | ["cloud-object-storage", "kms"]
vpcs_create_endpoint_gateway_on_vpe_tier | list(string) | Create a Virtual Private Endpoint for supported services on each `vpe` tier of VPC names in this list. |           | ["management", "workload"]

### VPE Failure States

Configuration for this template will fail if `enable_virtual_private_endpoints` is true and `vpe` is not found in `subnet_tiers`.