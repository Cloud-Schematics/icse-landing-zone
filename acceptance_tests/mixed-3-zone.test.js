const tfxjs = require("tfxjs");
const template = new tfxjs("../", {
  ibmcloud_api_key: process.env.API_KEY,
  region: "us-south",
  prefix: "at",
  tags: ["icse", "landing-zone"],
  zones: 3,
  cluster_type: "openshift",
  cluster_vpcs: ["workload"],
  cluster_subnet_tier: ["vsi"],
  cluster_zones: 3,
  kube_version: "default",
  flavor: "bx2.16x64",
  workers_per_zone: 2,
  entitlement: "cloud_pak",
  vsi_vpcs: ["management"],
  vsi_subnet_tier: ["vsi"],
  vsi_per_subnet: 1,
  vsi_zones: 3,
  image_name: "ibm-ubuntu-18-04-6-minimal-amd64-3",
  profile: "bx2-2x8",
  disable_public_service_endpoint: false,
});

template.clone("./mixed-test-clone", (tfx, done) => {
  tfx.plan("ICSE Landing Zone 3 Zone Mixed Deployment", () => {
    tfx.module(
      "Root Module",
      "root_module",
      tfx.resource("Ssh Key 0", "ibm_is_ssh_key.ssh_key[0]", {
        name: "at-ssh-key",
      }),
      tfx.resource("Cluster Key 0", "ibm_kms_key.cluster_key[0]", {
        endpoint_type: "public",
        force_delete: false,
        key_name: "at-cluster-key",
        key_ring_id: "default",
        standard_key: false,
      }),
      tfx.resource("Vsi Key", "ibm_kms_key.vsi_key", {
        endpoint_type: "public",
        force_delete: false,
        key_name: "at-vsi-key",
        key_ring_id: "default",
        standard_key: false,
      }),
      tfx.resource(
        "Resource Group Management",
        'ibm_resource_group.resource_group["management"]',
        {
          name: "at-management-rg",
        }
      ),
      tfx.resource(
        "Resource Group Workload",
        'ibm_resource_group.resource_group["workload"]',
        {
          name: "at-workload-rg",
        }
      )
    );

    tfx.module(
      "Clusters Workload",
      'module.clusters["workload"]',
      tfx.resource("Cluster", "ibm_container_vpc_cluster.cluster", {
        disable_public_service_endpoint: false,
        flavor: "bx2.16x64",
        force_delete_storage: false,
        image_security_enforcement: false,
        kms_config: [
          {
            private_endpoint: true,
          },
        ],
        kube_version: "4.10.22_openshift",
        name: "at-roks-cluster",
        tags: ["icse", "landing-zone"],
        taints: [],
        timeouts: {
          create: "3h",
          delete: "2h",
          update: "3h",
        },
        update_all_workers: false,
        wait_for_worker_update: true,
        wait_till: "IngressReady",
        worker_count: 2,
        zones: [
          {
            name: "us-south-1",
          },
          {
            name: "us-south-2",
          },
          {
            name: "us-south-3",
          },
        ],
      })
    );

    tfx.module(
      "Cloud Object Storage",
      "module.icse_vpc_network.module.services.module.cloud_object_storage",
      tfx.resource(
        "Bucket Atracker Bucket",
        'ibm_cos_bucket.bucket["atracker-bucket"]',
        {
          abort_incomplete_multipart_upload_days: [],
          activity_tracking: [],
          archive_rule: [],
          endpoint_type: "public",
          expire_rule: [],
          force_delete: true,
          metrics_monitoring: [],
          noncurrent_version_expiration: [],
          object_versioning: [],
          region_location: "us-south",
          retention_rule: [],
          storage_class: "standard",
        }
      ),
      tfx.resource(
        "Bucket Management Flow Logs Bucket",
        'ibm_cos_bucket.bucket["management-flow-logs-bucket"]',
        {
          abort_incomplete_multipart_upload_days: [],
          activity_tracking: [],
          archive_rule: [],
          endpoint_type: "public",
          expire_rule: [],
          force_delete: true,
          metrics_monitoring: [],
          noncurrent_version_expiration: [],
          object_versioning: [],
          region_location: "us-south",
          retention_rule: [],
          storage_class: "standard",
        }
      ),
      tfx.resource(
        "Bucket Workload Flow Logs Bucket",
        'ibm_cos_bucket.bucket["workload-flow-logs-bucket"]',
        {
          abort_incomplete_multipart_upload_days: [],
          activity_tracking: [],
          archive_rule: [],
          endpoint_type: "public",
          expire_rule: [],
          force_delete: true,
          metrics_monitoring: [],
          noncurrent_version_expiration: [],
          object_versioning: [],
          region_location: "us-south",
          retention_rule: [],
          storage_class: "standard",
        }
      ),
      tfx.resource("Cos Cos", 'ibm_resource_instance.cos["cos"]', {
        location: "global",
        plan: "standard",
        service: "cloud-object-storage",
        tags: ["icse", "landing-zone"],
      }),
      tfx.resource("Random Cos Suffix", "random_string.random_cos_suffix", {
        length: 8,
        lower: true,
        min_lower: 0,
        min_numeric: 0,
        min_special: 0,
        min_upper: 0,
        number: true,
        numeric: true,
        special: false,
        upper: false,
      })
    );

    tfx.module(
      "Key Management Key Management",
      'module.icse_vpc_network.module.services.module.key_management["key_management"]',
      tfx.resource(
        "Block Storage Policy 0",
        "ibm_iam_authorization_policy.block_storage_policy[0]",
        {
          description:
            "Allow block storage volumes to be encrypted by Key Management instance.",
          roles: ["Reader", "Authorization Delegator"],
          source_resource_type: "share",
          source_service_name: "is",
          target_service_name: "kms",
        }
      ),
      tfx.resource(
        "Server Protect Policy 0",
        "ibm_iam_authorization_policy.server_protect_policy[0]",
        {
          description:
            "Allow block storage volumes to be encrypted by Key Management instance.",
          roles: ["Reader"],
          source_service_name: "server-protect",
          target_service_name: "kms",
        }
      ),
      tfx.resource("Key Bucket Key", 'ibm_kms_key.key["bucket-key"]', {
        force_delete: true,
        key_name: "at-bucket-key",
        key_ring_id: "default",
        standard_key: false,
      }),
      tfx.resource("Kms 0", "ibm_resource_instance.kms[0]", {
        location: "us-south",
        name: "at-kms",
        plan: "tiered-pricing",
        service: "kms",
      })
    );

    tfx.module(
      "Vpc",
      "module.icse_vpc_network.module.vpc",
      tfx.resource("Format Output", "data.external.format_output", {
        program: [
          "python3",
          ".terraform/modules/icse_vpc_network.vpc/scripts/output.py",
          null,
        ],
      }),
      tfx.resource(
        "Connection Management",
        'ibm_tg_connection.connection["management"]',
        {
          name: "at-management-hub-connection",
          network_type: "vpc",
          timeouts: {
            create: "30m",
            delete: "30m",
            update: null,
          },
        }
      ),
      tfx.resource(
        "Connection Workload",
        'ibm_tg_connection.connection["workload"]',
        {
          name: "at-workload-hub-connection",
          network_type: "vpc",
          timeouts: {
            create: "30m",
            delete: "30m",
            update: null,
          },
        }
      ),
      tfx.resource("Transit Gateway 0", "ibm_tg_gateway.transit_gateway[0]", {
        global: false,
        location: "us-south",
        name: "at-transit-gateway",
        timeouts: {
          create: "30m",
          delete: "30m",
          update: null,
        },
      })
    );

    tfx.module(
      "Vpcs Management",
      'module.icse_vpc_network.module.vpc.module.vpcs["management"]',
      tfx.resource("Vpc", "ibm_is_vpc.vpc", {
        address_prefix_management: "auto",
        classic_access: false,
        name: "at-management-vpc",
        tags: ["icse", "landing-zone"],
      })
    );

    tfx.module(
      "Public Gateways",
      'module.icse_vpc_network.module.vpc.module.vpcs["management"].module.public_gateways',
      tfx.resource(
        "Gateway Zone 1",
        'ibm_is_public_gateway.gateway["zone-1"]',
        {
          name: "at-management-public-gateway-zone-1",
          zone: "us-south-1",
        }
      ),
      tfx.resource(
        "Gateway Zone 2",
        'ibm_is_public_gateway.gateway["zone-2"]',
        {
          name: "at-management-public-gateway-zone-2",
          zone: "us-south-2",
        }
      ),
      tfx.resource(
        "Gateway Zone 3",
        'ibm_is_public_gateway.gateway["zone-3"]',
        {
          name: "at-management-public-gateway-zone-3",
          zone: "us-south-3",
        }
      )
    );

    tfx.module(
      "Network Acls",
      'module.icse_vpc_network.module.vpc.module.vpcs["management"].module.network_acls',
      tfx.resource("Acl Vpe Acl", 'ibm_is_network_acl.acl["vpe-acl"]', {
        name: "at-management-vpe-acl",
        rules: [
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "roks-create-worker-nodes-inbound",
            source: "161.26.0.0/16",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "161.26.0.0/16",
            direction: "outbound",
            icmp: [],
            name: "roks-create-worker-nodes-outbound",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "roks-nodes-to-service-inbound",
            source: "166.8.0.0/14",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "166.8.0.0/14",
            direction: "outbound",
            icmp: [],
            name: "roks-nodes-to-service-outbound",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "allow-app-incoming-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 65535,
                port_min: 1,
                source_port_max: 30000,
                source_port_min: 30000,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "outbound",
            icmp: [],
            name: "allow-app-outgoing-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 32767,
                port_min: 30000,
                source_port_max: 65535,
                source_port_min: 1,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "allow-lb-incoming-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 443,
                port_min: 443,
                source_port_max: 65535,
                source_port_min: 1,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "outbound",
            icmp: [],
            name: "allow-lb-outgoing-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 65535,
                port_min: 1,
                source_port_max: 443,
                source_port_min: 443,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "vpe-allow-inbound-1",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "vpe-allow-inbound-2",
            source: "161.26.0.0/16",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "0.0.0.0/0",
            direction: "outbound",
            icmp: [],
            name: "vpe-allow-outbound-1",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "deny",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "vpe-deny-inbound-1",
            source: "0.0.0.0/0",
            tcp: [],
            udp: [],
          },
        ],
      }),
      tfx.resource("Acl Vpn Acl", 'ibm_is_network_acl.acl["vpn-acl"]', {
        name: "at-management-vpn-acl",
        rules: [
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "roks-create-worker-nodes-inbound",
            source: "161.26.0.0/16",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "161.26.0.0/16",
            direction: "outbound",
            icmp: [],
            name: "roks-create-worker-nodes-outbound",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "roks-nodes-to-service-inbound",
            source: "166.8.0.0/14",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "166.8.0.0/14",
            direction: "outbound",
            icmp: [],
            name: "roks-nodes-to-service-outbound",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "allow-app-incoming-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 65535,
                port_min: 1,
                source_port_max: 30000,
                source_port_min: 30000,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "outbound",
            icmp: [],
            name: "allow-app-outgoing-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 32767,
                port_min: 30000,
                source_port_max: 65535,
                source_port_min: 1,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "allow-lb-incoming-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 443,
                port_min: 443,
                source_port_max: 65535,
                source_port_min: 1,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "outbound",
            icmp: [],
            name: "allow-lb-outgoing-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 65535,
                port_min: 1,
                source_port_max: 443,
                source_port_min: 443,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "vpn-allow-inbound-1",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "vpn-allow-inbound-2",
            source: "161.26.0.0/16",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "0.0.0.0/0",
            direction: "outbound",
            icmp: [],
            name: "vpn-allow-outbound-1",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "deny",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "vpn-deny-inbound-1",
            source: "0.0.0.0/0",
            tcp: [],
            udp: [],
          },
        ],
      }),
      tfx.resource("Acl Vsi Acl", 'ibm_is_network_acl.acl["vsi-acl"]', {
        name: "at-management-vsi-acl",
        rules: [
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "roks-create-worker-nodes-inbound",
            source: "161.26.0.0/16",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "161.26.0.0/16",
            direction: "outbound",
            icmp: [],
            name: "roks-create-worker-nodes-outbound",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "roks-nodes-to-service-inbound",
            source: "166.8.0.0/14",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "166.8.0.0/14",
            direction: "outbound",
            icmp: [],
            name: "roks-nodes-to-service-outbound",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "allow-app-incoming-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 65535,
                port_min: 1,
                source_port_max: 30000,
                source_port_min: 30000,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "outbound",
            icmp: [],
            name: "allow-app-outgoing-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 32767,
                port_min: 30000,
                source_port_max: 65535,
                source_port_min: 1,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "allow-lb-incoming-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 443,
                port_min: 443,
                source_port_max: 65535,
                source_port_min: 1,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "outbound",
            icmp: [],
            name: "allow-lb-outgoing-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 65535,
                port_min: 1,
                source_port_max: 443,
                source_port_min: 443,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "vsi-allow-inbound-1",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "vsi-allow-inbound-2",
            source: "161.26.0.0/16",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "0.0.0.0/0",
            direction: "outbound",
            icmp: [],
            name: "vsi-allow-outbound-1",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "deny",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "vsi-deny-inbound-1",
            source: "0.0.0.0/0",
            tcp: [],
            udp: [],
          },
        ],
      })
    );

    tfx.module(
      "Subnets",
      'module.icse_vpc_network.module.vpc.module.vpcs["management"].module.subnets',
      tfx.resource(
        "Subnet At Management Vpe 1",
        'ibm_is_subnet.subnet["at-management-vpe-1"]',
        {
          ip_version: "ipv4",
          ipv4_cidr_block: "10.10.20.0/24",
          name: "at-management-vpe-1",
          tags: ["icse", "landing-zone"],
          zone: "us-south-1",
        }
      ),
      tfx.resource(
        "Subnet At Management Vpe 2",
        'ibm_is_subnet.subnet["at-management-vpe-2"]',
        {
          ip_version: "ipv4",
          ipv4_cidr_block: "10.20.20.0/24",
          name: "at-management-vpe-2",
          tags: ["icse", "landing-zone"],
          zone: "us-south-2",
        }
      ),
      tfx.resource(
        "Subnet At Management Vpe 3",
        'ibm_is_subnet.subnet["at-management-vpe-3"]',
        {
          ip_version: "ipv4",
          ipv4_cidr_block: "10.30.20.0/24",
          name: "at-management-vpe-3",
          tags: ["icse", "landing-zone"],
          zone: "us-south-3",
        }
      ),
      tfx.resource(
        "Subnet At Management Vpn 1",
        'ibm_is_subnet.subnet["at-management-vpn-1"]',
        {
          ip_version: "ipv4",
          ipv4_cidr_block: "10.0.30.0/24",
          name: "at-management-vpn-1",
          tags: ["icse", "landing-zone"],
          zone: "us-south-1",
        }
      ),
      tfx.resource(
        "Subnet At Management Vsi 1",
        'ibm_is_subnet.subnet["at-management-vsi-1"]',
        {
          ip_version: "ipv4",
          ipv4_cidr_block: "10.10.10.0/24",
          name: "at-management-vsi-1",
          tags: ["icse", "landing-zone"],
          zone: "us-south-1",
        }
      ),
      tfx.resource(
        "Subnet At Management Vsi 2",
        'ibm_is_subnet.subnet["at-management-vsi-2"]',
        {
          ip_version: "ipv4",
          ipv4_cidr_block: "10.20.10.0/24",
          name: "at-management-vsi-2",
          tags: ["icse", "landing-zone"],
          zone: "us-south-2",
        }
      ),
      tfx.resource(
        "Subnet At Management Vsi 3",
        'ibm_is_subnet.subnet["at-management-vsi-3"]',
        {
          ip_version: "ipv4",
          ipv4_cidr_block: "10.30.10.0/24",
          name: "at-management-vsi-3",
          tags: ["icse", "landing-zone"],
          zone: "us-south-3",
        }
      ),
      tfx.resource(
        "Subnet Prefix At Management Vpe 1",
        'ibm_is_vpc_address_prefix.subnet_prefix["at-management-vpe-1"]',
        {
          cidr: "10.10.20.0/24",
          is_default: false,
          name: "at-management-vpe-1",
          zone: "us-south-1",
        }
      ),
      tfx.resource(
        "Subnet Prefix At Management Vpe 2",
        'ibm_is_vpc_address_prefix.subnet_prefix["at-management-vpe-2"]',
        {
          cidr: "10.20.20.0/24",
          is_default: false,
          name: "at-management-vpe-2",
          zone: "us-south-2",
        }
      ),
      tfx.resource(
        "Subnet Prefix At Management Vpe 3",
        'ibm_is_vpc_address_prefix.subnet_prefix["at-management-vpe-3"]',
        {
          cidr: "10.30.20.0/24",
          is_default: false,
          name: "at-management-vpe-3",
          zone: "us-south-3",
        }
      ),
      tfx.resource(
        "Subnet Prefix At Management Vpn 1",
        'ibm_is_vpc_address_prefix.subnet_prefix["at-management-vpn-1"]',
        {
          cidr: "10.0.30.0/24",
          is_default: false,
          name: "at-management-vpn-1",
          zone: "us-south-1",
        }
      ),
      tfx.resource(
        "Subnet Prefix At Management Vsi 1",
        'ibm_is_vpc_address_prefix.subnet_prefix["at-management-vsi-1"]',
        {
          cidr: "10.10.10.0/24",
          is_default: false,
          name: "at-management-vsi-1",
          zone: "us-south-1",
        }
      ),
      tfx.resource(
        "Subnet Prefix At Management Vsi 2",
        'ibm_is_vpc_address_prefix.subnet_prefix["at-management-vsi-2"]',
        {
          cidr: "10.20.10.0/24",
          is_default: false,
          name: "at-management-vsi-2",
          zone: "us-south-2",
        }
      ),
      tfx.resource(
        "Subnet Prefix At Management Vsi 3",
        'ibm_is_vpc_address_prefix.subnet_prefix["at-management-vsi-3"]',
        {
          cidr: "10.30.10.0/24",
          is_default: false,
          name: "at-management-vsi-3",
          zone: "us-south-3",
        }
      )
    );

    tfx.module(
      "Vpn Gateway",
      'module.icse_vpc_network.module.vpc.module.vpcs["management"].module.vpn_gateway',
      tfx.resource("Gateway 0", "ibm_is_vpn_gateway.gateway[0]", {
        mode: "route",
        name: "at-management-vpn-gateway",
        tags: ["icse", "landing-zone"],
        timeouts: {
          delete: "1h",
          create: null,
        },
      })
    );

    tfx.module(
      "Vpcs Workload",
      'module.icse_vpc_network.module.vpc.module.vpcs["workload"]',
      tfx.resource("Vpc", "ibm_is_vpc.vpc", {
        address_prefix_management: "auto",
        classic_access: false,
        name: "at-workload-vpc",
        tags: ["icse", "landing-zone"],
      })
    );

    tfx.module(
      "Public Gateways",
      'module.icse_vpc_network.module.vpc.module.vpcs["workload"].module.public_gateways',
      tfx.resource(
        "Gateway Zone 1",
        'ibm_is_public_gateway.gateway["zone-1"]',
        {
          name: "at-workload-public-gateway-zone-1",
          zone: "us-south-1",
        }
      ),
      tfx.resource(
        "Gateway Zone 2",
        'ibm_is_public_gateway.gateway["zone-2"]',
        {
          name: "at-workload-public-gateway-zone-2",
          zone: "us-south-2",
        }
      ),
      tfx.resource(
        "Gateway Zone 3",
        'ibm_is_public_gateway.gateway["zone-3"]',
        {
          name: "at-workload-public-gateway-zone-3",
          zone: "us-south-3",
        }
      )
    );

    tfx.module(
      "Network Acls",
      'module.icse_vpc_network.module.vpc.module.vpcs["workload"].module.network_acls',
      tfx.resource("Acl Vpe Acl", 'ibm_is_network_acl.acl["vpe-acl"]', {
        name: "at-workload-vpe-acl",
        rules: [
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "roks-create-worker-nodes-inbound",
            source: "161.26.0.0/16",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "161.26.0.0/16",
            direction: "outbound",
            icmp: [],
            name: "roks-create-worker-nodes-outbound",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "roks-nodes-to-service-inbound",
            source: "166.8.0.0/14",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "166.8.0.0/14",
            direction: "outbound",
            icmp: [],
            name: "roks-nodes-to-service-outbound",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "allow-app-incoming-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 65535,
                port_min: 1,
                source_port_max: 30000,
                source_port_min: 30000,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "outbound",
            icmp: [],
            name: "allow-app-outgoing-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 32767,
                port_min: 30000,
                source_port_max: 65535,
                source_port_min: 1,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "allow-lb-incoming-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 443,
                port_min: 443,
                source_port_max: 65535,
                source_port_min: 1,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "outbound",
            icmp: [],
            name: "allow-lb-outgoing-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 65535,
                port_min: 1,
                source_port_max: 443,
                source_port_min: 443,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "vpe-allow-inbound-1",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "vpe-allow-inbound-2",
            source: "161.26.0.0/16",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "0.0.0.0/0",
            direction: "outbound",
            icmp: [],
            name: "vpe-allow-outbound-1",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "deny",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "vpe-deny-inbound-1",
            source: "0.0.0.0/0",
            tcp: [],
            udp: [],
          },
        ],
      }),
      tfx.resource("Acl Vsi Acl", 'ibm_is_network_acl.acl["vsi-acl"]', {
        name: "at-workload-vsi-acl",
        rules: [
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "roks-create-worker-nodes-inbound",
            source: "161.26.0.0/16",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "161.26.0.0/16",
            direction: "outbound",
            icmp: [],
            name: "roks-create-worker-nodes-outbound",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "roks-nodes-to-service-inbound",
            source: "166.8.0.0/14",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "166.8.0.0/14",
            direction: "outbound",
            icmp: [],
            name: "roks-nodes-to-service-outbound",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "allow-app-incoming-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 65535,
                port_min: 1,
                source_port_max: 30000,
                source_port_min: 30000,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "outbound",
            icmp: [],
            name: "allow-app-outgoing-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 32767,
                port_min: 30000,
                source_port_max: 65535,
                source_port_min: 1,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "allow-lb-incoming-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 443,
                port_min: 443,
                source_port_max: 65535,
                source_port_min: 1,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "outbound",
            icmp: [],
            name: "allow-lb-outgoing-traffic-requests",
            source: "10.0.0.0/8",
            tcp: [
              {
                port_max: 65535,
                port_min: 1,
                source_port_max: 443,
                source_port_min: 443,
              },
            ],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "vsi-allow-inbound-1",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "vsi-allow-inbound-2",
            source: "161.26.0.0/16",
            tcp: [],
            udp: [],
          },
          {
            action: "allow",
            destination: "0.0.0.0/0",
            direction: "outbound",
            icmp: [],
            name: "vsi-allow-outbound-1",
            source: "10.0.0.0/8",
            tcp: [],
            udp: [],
          },
          {
            action: "deny",
            destination: "10.0.0.0/8",
            direction: "inbound",
            icmp: [],
            name: "vsi-deny-inbound-1",
            source: "0.0.0.0/0",
            tcp: [],
            udp: [],
          },
        ],
      })
    );

    tfx.module(
      "Subnets",
      'module.icse_vpc_network.module.vpc.module.vpcs["workload"].module.subnets',
      tfx.resource(
        "Subnet At Workload Vpe 1",
        'ibm_is_subnet.subnet["at-workload-vpe-1"]',
        {
          ip_version: "ipv4",
          ipv4_cidr_block: "10.40.20.0/24",
          name: "at-workload-vpe-1",
          tags: ["icse", "landing-zone"],
          zone: "us-south-1",
        }
      ),
      tfx.resource(
        "Subnet At Workload Vpe 2",
        'ibm_is_subnet.subnet["at-workload-vpe-2"]',
        {
          ip_version: "ipv4",
          ipv4_cidr_block: "10.50.20.0/24",
          name: "at-workload-vpe-2",
          tags: ["icse", "landing-zone"],
          zone: "us-south-2",
        }
      ),
      tfx.resource(
        "Subnet At Workload Vpe 3",
        'ibm_is_subnet.subnet["at-workload-vpe-3"]',
        {
          ip_version: "ipv4",
          ipv4_cidr_block: "10.60.20.0/24",
          name: "at-workload-vpe-3",
          tags: ["icse", "landing-zone"],
          zone: "us-south-3",
        }
      ),
      tfx.resource(
        "Subnet At Workload Vsi 1",
        'ibm_is_subnet.subnet["at-workload-vsi-1"]',
        {
          ip_version: "ipv4",
          ipv4_cidr_block: "10.40.10.0/24",
          name: "at-workload-vsi-1",
          tags: ["icse", "landing-zone"],
          zone: "us-south-1",
        }
      ),
      tfx.resource(
        "Subnet At Workload Vsi 2",
        'ibm_is_subnet.subnet["at-workload-vsi-2"]',
        {
          ip_version: "ipv4",
          ipv4_cidr_block: "10.50.10.0/24",
          name: "at-workload-vsi-2",
          tags: ["icse", "landing-zone"],
          zone: "us-south-2",
        }
      ),
      tfx.resource(
        "Subnet At Workload Vsi 3",
        'ibm_is_subnet.subnet["at-workload-vsi-3"]',
        {
          ip_version: "ipv4",
          ipv4_cidr_block: "10.60.10.0/24",
          name: "at-workload-vsi-3",
          tags: ["icse", "landing-zone"],
          zone: "us-south-3",
        }
      ),
      tfx.resource(
        "Subnet Prefix At Workload Vpe 1",
        'ibm_is_vpc_address_prefix.subnet_prefix["at-workload-vpe-1"]',
        {
          cidr: "10.40.20.0/24",
          is_default: false,
          name: "at-workload-vpe-1",
          zone: "us-south-1",
        }
      ),
      tfx.resource(
        "Subnet Prefix At Workload Vpe 2",
        'ibm_is_vpc_address_prefix.subnet_prefix["at-workload-vpe-2"]',
        {
          cidr: "10.50.20.0/24",
          is_default: false,
          name: "at-workload-vpe-2",
          zone: "us-south-2",
        }
      ),
      tfx.resource(
        "Subnet Prefix At Workload Vpe 3",
        'ibm_is_vpc_address_prefix.subnet_prefix["at-workload-vpe-3"]',
        {
          cidr: "10.60.20.0/24",
          is_default: false,
          name: "at-workload-vpe-3",
          zone: "us-south-3",
        }
      ),
      tfx.resource(
        "Subnet Prefix At Workload Vsi 1",
        'ibm_is_vpc_address_prefix.subnet_prefix["at-workload-vsi-1"]',
        {
          cidr: "10.40.10.0/24",
          is_default: false,
          name: "at-workload-vsi-1",
          zone: "us-south-1",
        }
      ),
      tfx.resource(
        "Subnet Prefix At Workload Vsi 2",
        'ibm_is_vpc_address_prefix.subnet_prefix["at-workload-vsi-2"]',
        {
          cidr: "10.50.10.0/24",
          is_default: false,
          name: "at-workload-vsi-2",
          zone: "us-south-2",
        }
      ),
      tfx.resource(
        "Subnet Prefix At Workload Vsi 3",
        'ibm_is_vpc_address_prefix.subnet_prefix["at-workload-vsi-3"]',
        {
          cidr: "10.60.10.0/24",
          is_default: false,
          name: "at-workload-vsi-3",
          zone: "us-south-3",
        }
      )
    );

    tfx.module(
      "Flow Logs[0]",
      "module.icse_vpc_network.module.flow_logs[0]",
      tfx.resource(
        "Flow Logs Policy Cos",
        'ibm_iam_authorization_policy.flow_logs_policy["cos"]',
        {
          description:
            "Allow flow logs write access cloud object storage instance",
          roles: ["Writer"],
          source_resource_type: "flow-log-collector",
          source_service_name: "is",
          target_service_name: "cloud-object-storage",
        }
      ),
      tfx.resource(
        "Flow Logs Management",
        'ibm_is_flow_log.flow_logs["management"]',
        {
          active: true,
          name: "at-management-flow-logs",
        }
      ),
      tfx.resource(
        "Flow Logs Workload",
        'ibm_is_flow_log.flow_logs["workload"]',
        {
          active: true,
          name: "at-workload-flow-logs",
        }
      )
    );

    tfx.module(
      "Activity Tracker",
      "module.icse_vpc_network.module.activity_tracker",
      tfx.resource(
        "Atracker Target 0",
        "ibm_atracker_target.atracker_target[0]",
        {
          cos_endpoint: [
            {
              endpoint:
                "s3.private.us-south.cloud-object-storage.appdomain.cloud",
              service_to_service_enabled: null,
            },
          ],
          logdna_endpoint: [],
          name: "at-atracker",
          target_type: "cloud_object_storage",
        }
      ),
      tfx.resource(
        "Atracker Cos Key 0",
        "ibm_resource_key.atracker_cos_key[0]",
        {
          name: "at-atracker-cos-bind-key",
          role: "Writer",
          tags: ["icse", "landing-zone"],
        }
      )
    );

    tfx.module(
      "Security Groups Management Vpe",
      'module.security_groups["management-vpe"]',
      tfx.resource(
        "Security Group Management Vpe Sg",
        'ibm_is_security_group.security_group["management-vpe-sg"]',
        {
          name: "at-management-vpe-sg",
          tags: ["icse", "landing-zone"],
        }
      )
    );

    tfx.module(
      "Security Group Rules Management Vpe Sg",
      'module.security_groups["management-vpe"].module.security_group_rules["management-vpe-sg"]',
      tfx.resource(
        "Rule Management Vpe Sg Allow In 1",
        'ibm_is_security_group_rule.rule["management-vpe-sg-allow-in-1"]',
        {
          direction: "inbound",
          icmp: [],
          ip_version: "ipv4",
          remote: "10.0.0.0/8",
          tcp: [],
          udp: [],
        }
      ),
      tfx.resource(
        "Rule Management Vpe Sg Allow In 2",
        'ibm_is_security_group_rule.rule["management-vpe-sg-allow-in-2"]',
        {
          direction: "inbound",
          icmp: [],
          ip_version: "ipv4",
          remote: "161.26.0.0/16",
          tcp: [],
          udp: [],
        }
      ),
      tfx.resource(
        "Rule Management Vpe Sg Allow Out 1",
        'ibm_is_security_group_rule.rule["management-vpe-sg-allow-out-1"]',
        {
          direction: "outbound",
          icmp: [],
          ip_version: "ipv4",
          remote: "0.0.0.0/0",
          tcp: [],
          udp: [],
        }
      )
    );

    tfx.module(
      "Security Groups Management Vsi",
      'module.security_groups["management-vsi"]',
      tfx.resource(
        "Security Group Management Vsi Sg",
        'ibm_is_security_group.security_group["management-vsi-sg"]',
        {
          name: "at-management-vsi-sg",
          tags: ["icse", "landing-zone"],
        }
      )
    );

    tfx.module(
      "Security Group Rules Management Vsi Sg",
      'module.security_groups["management-vsi"].module.security_group_rules["management-vsi-sg"]',
      tfx.resource(
        "Rule Management Vsi Sg Allow In 1",
        'ibm_is_security_group_rule.rule["management-vsi-sg-allow-in-1"]',
        {
          direction: "inbound",
          icmp: [],
          ip_version: "ipv4",
          remote: "10.0.0.0/8",
          tcp: [],
          udp: [],
        }
      ),
      tfx.resource(
        "Rule Management Vsi Sg Allow In 2",
        'ibm_is_security_group_rule.rule["management-vsi-sg-allow-in-2"]',
        {
          direction: "inbound",
          icmp: [],
          ip_version: "ipv4",
          remote: "161.26.0.0/16",
          tcp: [],
          udp: [],
        }
      ),
      tfx.resource(
        "Rule Management Vsi Sg Allow Out 1",
        'ibm_is_security_group_rule.rule["management-vsi-sg-allow-out-1"]',
        {
          direction: "outbound",
          icmp: [],
          ip_version: "ipv4",
          remote: "0.0.0.0/0",
          tcp: [],
          udp: [],
        }
      )
    );

    tfx.module(
      "Security Groups Workload Vpe",
      'module.security_groups["workload-vpe"]',
      tfx.resource(
        "Security Group Workload Vpe Sg",
        'ibm_is_security_group.security_group["workload-vpe-sg"]',
        {
          name: "at-workload-vpe-sg",
          tags: ["icse", "landing-zone"],
        }
      )
    );

    tfx.module(
      "Security Group Rules Workload Vpe Sg",
      'module.security_groups["workload-vpe"].module.security_group_rules["workload-vpe-sg"]',
      tfx.resource(
        "Rule Workload Vpe Sg Allow In 1",
        'ibm_is_security_group_rule.rule["workload-vpe-sg-allow-in-1"]',
        {
          direction: "inbound",
          icmp: [],
          ip_version: "ipv4",
          remote: "10.0.0.0/8",
          tcp: [],
          udp: [],
        }
      ),
      tfx.resource(
        "Rule Workload Vpe Sg Allow In 2",
        'ibm_is_security_group_rule.rule["workload-vpe-sg-allow-in-2"]',
        {
          direction: "inbound",
          icmp: [],
          ip_version: "ipv4",
          remote: "161.26.0.0/16",
          tcp: [],
          udp: [],
        }
      ),
      tfx.resource(
        "Rule Workload Vpe Sg Allow Out 1",
        'ibm_is_security_group_rule.rule["workload-vpe-sg-allow-out-1"]',
        {
          direction: "outbound",
          icmp: [],
          ip_version: "ipv4",
          remote: "0.0.0.0/0",
          tcp: [],
          udp: [],
        }
      )
    );

    tfx.module(
      "Virtual Private Endpoints Management",
      'module.virtual_private_endpoints["management"]',
      tfx.resource(
        "Ip At Management Vpe 1 Cloud Object Storage Gateway 1 Ip",
        'ibm_is_subnet_reserved_ip.ip["at-management-vpe-1-cloud-object-storage-gateway-1-ip"]',
        {}
      ),
      tfx.resource(
        "Ip At Management Vpe 1 Kms Gateway 1 Ip",
        'ibm_is_subnet_reserved_ip.ip["at-management-vpe-1-kms-gateway-1-ip"]',
        {}
      ),
      tfx.resource(
        "Ip At Management Vpe 2 Cloud Object Storage Gateway 2 Ip",
        'ibm_is_subnet_reserved_ip.ip["at-management-vpe-2-cloud-object-storage-gateway-2-ip"]',
        {}
      ),
      tfx.resource(
        "Ip At Management Vpe 2 Kms Gateway 2 Ip",
        'ibm_is_subnet_reserved_ip.ip["at-management-vpe-2-kms-gateway-2-ip"]',
        {}
      ),
      tfx.resource(
        "Ip At Management Vpe 3 Cloud Object Storage Gateway 3 Ip",
        'ibm_is_subnet_reserved_ip.ip["at-management-vpe-3-cloud-object-storage-gateway-3-ip"]',
        {}
      ),
      tfx.resource(
        "Ip At Management Vpe 3 Kms Gateway 3 Ip",
        'ibm_is_subnet_reserved_ip.ip["at-management-vpe-3-kms-gateway-3-ip"]',
        {}
      ),
      tfx.resource(
        "Vpe Management Cloud Object Storage",
        'ibm_is_virtual_endpoint_gateway.vpe["management-cloud-object-storage"]',
        {
          name: "at-management-cloud-object-storage-endpoint-gateway",
          target: [
            {
              crn: "crn:v1:bluemix:public:cloud-object-storage:global:::endpoint:s3.direct.us-south.cloud-object-storage.appdomain.cloud",
              name: null,
              resource_type: "provider_cloud_service",
            },
          ],
        }
      ),
      tfx.resource(
        "Vpe Management Kms",
        'ibm_is_virtual_endpoint_gateway.vpe["management-kms"]',
        {
          name: "at-management-kms-endpoint-gateway",
          target: [
            {
              crn: "crn:v1:bluemix:public:kms:us-south:::endpoint:private.us-south.kms.cloud.ibm.com",
              name: null,
              resource_type: "provider_cloud_service",
            },
          ],
        }
      ),
      tfx.resource(
        "Endpoint Gateway Ip At Management Vpe 1 Cloud Object Storage Gateway 1 Ip",
        'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["at-management-vpe-1-cloud-object-storage-gateway-1-ip"]',
        {}
      ),
      tfx.resource(
        "Endpoint Gateway Ip At Management Vpe 1 Kms Gateway 1 Ip",
        'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["at-management-vpe-1-kms-gateway-1-ip"]',
        {}
      ),
      tfx.resource(
        "Endpoint Gateway Ip At Management Vpe 2 Cloud Object Storage Gateway 2 Ip",
        'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["at-management-vpe-2-cloud-object-storage-gateway-2-ip"]',
        {}
      ),
      tfx.resource(
        "Endpoint Gateway Ip At Management Vpe 2 Kms Gateway 2 Ip",
        'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["at-management-vpe-2-kms-gateway-2-ip"]',
        {}
      ),
      tfx.resource(
        "Endpoint Gateway Ip At Management Vpe 3 Cloud Object Storage Gateway 3 Ip",
        'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["at-management-vpe-3-cloud-object-storage-gateway-3-ip"]',
        {}
      ),
      tfx.resource(
        "Endpoint Gateway Ip At Management Vpe 3 Kms Gateway 3 Ip",
        'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["at-management-vpe-3-kms-gateway-3-ip"]',
        {}
      )
    );

    tfx.module(
      "Virtual Private Endpoints Workload",
      'module.virtual_private_endpoints["workload"]',
      tfx.resource(
        "Ip At Workload Vpe 1 Cloud Object Storage Gateway 1 Ip",
        'ibm_is_subnet_reserved_ip.ip["at-workload-vpe-1-cloud-object-storage-gateway-1-ip"]',
        {}
      ),
      tfx.resource(
        "Ip At Workload Vpe 1 Kms Gateway 1 Ip",
        'ibm_is_subnet_reserved_ip.ip["at-workload-vpe-1-kms-gateway-1-ip"]',
        {}
      ),
      tfx.resource(
        "Ip At Workload Vpe 2 Cloud Object Storage Gateway 2 Ip",
        'ibm_is_subnet_reserved_ip.ip["at-workload-vpe-2-cloud-object-storage-gateway-2-ip"]',
        {}
      ),
      tfx.resource(
        "Ip At Workload Vpe 2 Kms Gateway 2 Ip",
        'ibm_is_subnet_reserved_ip.ip["at-workload-vpe-2-kms-gateway-2-ip"]',
        {}
      ),
      tfx.resource(
        "Ip At Workload Vpe 3 Cloud Object Storage Gateway 3 Ip",
        'ibm_is_subnet_reserved_ip.ip["at-workload-vpe-3-cloud-object-storage-gateway-3-ip"]',
        {}
      ),
      tfx.resource(
        "Ip At Workload Vpe 3 Kms Gateway 3 Ip",
        'ibm_is_subnet_reserved_ip.ip["at-workload-vpe-3-kms-gateway-3-ip"]',
        {}
      ),
      tfx.resource(
        "Vpe Workload Cloud Object Storage",
        'ibm_is_virtual_endpoint_gateway.vpe["workload-cloud-object-storage"]',
        {
          name: "at-workload-cloud-object-storage-endpoint-gateway",
          target: [
            {
              crn: "crn:v1:bluemix:public:cloud-object-storage:global:::endpoint:s3.direct.us-south.cloud-object-storage.appdomain.cloud",
              name: null,
              resource_type: "provider_cloud_service",
            },
          ],
        }
      ),
      tfx.resource(
        "Vpe Workload Kms",
        'ibm_is_virtual_endpoint_gateway.vpe["workload-kms"]',
        {
          name: "at-workload-kms-endpoint-gateway",
          target: [
            {
              crn: "crn:v1:bluemix:public:kms:us-south:::endpoint:private.us-south.kms.cloud.ibm.com",
              name: null,
              resource_type: "provider_cloud_service",
            },
          ],
        }
      ),
      tfx.resource(
        "Endpoint Gateway Ip At Workload Vpe 1 Cloud Object Storage Gateway 1 Ip",
        'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["at-workload-vpe-1-cloud-object-storage-gateway-1-ip"]',
        {}
      ),
      tfx.resource(
        "Endpoint Gateway Ip At Workload Vpe 1 Kms Gateway 1 Ip",
        'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["at-workload-vpe-1-kms-gateway-1-ip"]',
        {}
      ),
      tfx.resource(
        "Endpoint Gateway Ip At Workload Vpe 2 Cloud Object Storage Gateway 2 Ip",
        'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["at-workload-vpe-2-cloud-object-storage-gateway-2-ip"]',
        {}
      ),
      tfx.resource(
        "Endpoint Gateway Ip At Workload Vpe 2 Kms Gateway 2 Ip",
        'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["at-workload-vpe-2-kms-gateway-2-ip"]',
        {}
      ),
      tfx.resource(
        "Endpoint Gateway Ip At Workload Vpe 3 Cloud Object Storage Gateway 3 Ip",
        'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["at-workload-vpe-3-cloud-object-storage-gateway-3-ip"]',
        {}
      ),
      tfx.resource(
        "Endpoint Gateway Ip At Workload Vpe 3 Kms Gateway 3 Ip",
        'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["at-workload-vpe-3-kms-gateway-3-ip"]',
        {}
      )
    );

    tfx.module(
      "Vsi Management Vsi Vsi 2",
      'module.vsi_deployment["management-vsi"].module.vsi["management-vsi-vsi-2"]',
      tfx.resource("Vsi", "ibm_is_instance.vsi", {
        boot_volume: [
          {
            snapshot: null,
          },
        ],
        force_action: false,
        image: "r006-25cce64f-b8d7-4e86-a975-2721cfebe98b",
        name: "at-management-vsi-vsi-2",
        primary_network_interface: [
          {
            allow_ip_spoofing: false,
          },
        ],
        profile: "bx2-2x8",
        wait_before_delete: true,
        zone: "us-south-2",
      })
    );

    tfx.module(
      "Vsi Management Vsi Vsi 1",
      'module.vsi_deployment["management-vsi"].module.vsi["management-vsi-vsi-1"]',
      tfx.resource("Vsi", "ibm_is_instance.vsi", {
        boot_volume: [
          {
            snapshot: null,
          },
        ],
        force_action: false,
        image: "r006-25cce64f-b8d7-4e86-a975-2721cfebe98b",
        name: "at-management-vsi-vsi-1",
        primary_network_interface: [
          {
            allow_ip_spoofing: false,
          },
        ],
        profile: "bx2-2x8",
        wait_before_delete: true,
        zone: "us-south-1",
      })
    );

    tfx.module(
      "Vsi Management Vsi Vsi 3",
      'module.vsi_deployment["management-vsi"].module.vsi["management-vsi-vsi-3"]',
      tfx.resource("Vsi", "ibm_is_instance.vsi", {
        boot_volume: [
          {
            snapshot: null,
          },
        ],
        force_action: false,
        image: "r006-25cce64f-b8d7-4e86-a975-2721cfebe98b",
        name: "at-management-vsi-vsi-3",
        primary_network_interface: [
          {
            allow_ip_spoofing: false,
          },
        ],
        profile: "bx2-2x8",
        wait_before_delete: true,
        zone: "us-south-3",
      })
    );
    done();
  });
});
