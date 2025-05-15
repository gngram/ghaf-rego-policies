# Centralized Policy Management Framework for Ghaf

## 1. Overview

This document outlines the architecture for a **centralized policy management system** in Ghaf. The design ensures that VMs can query and enforce security and operational policies without directly accessing the policy engine (OPA). The existing `givc-admin` service now acts as a secure policy gateway too. A command line option has been added to 'givc-cli' to query a policy.  

## 2. Architectural Goals

- **Centralized Policy Evaluation:** All policy decisions are made centrally for consistency and auditability.
- **Secure channel** VMs can use existing `givc-cli` option to query any policy. We use existing mTLS secured gRPC implemented by `givc-admin`.
- **Minimal Overhead:** Any application/service can safely cache the policies if they have mechanism to accept policy update notification to minimize the transactions.
- **Complex Query Handling:** Provides mechanism to add new commands, which can be used instead of complex queries.
- **Live Policy Enforcement:** The application will provide mechanism to update the policy in a live system.
- **Extensibility:** Designed to support various use cases.

## 3. High-Level Component Diagram

![Components of Ghaf Policy Manager](./policy-management.png)

```plantuml
@startuml
skinparam componentStyle rectangle

' Start node
circle "boot" as StartCircle #black

' Actor
actor "User / System Event" as User

' Colored node: ghaf-host
node "ghaf-host" as GhafHost #lightgray {
  component vhotplug.service #darkgray
}

' Colored node: Admin VM
node "Admin VM" as AdminVM #cyan {
  component givc_admin #lightblue
  component OPA_server #lightgreen
}

' Colored node: VMx
node "VMx" as VMxNode #lightyellow {
  component qmu.qmpclient #orange
}

' Arrows
StartCircle --> vhotplug.service : [1] service startup
vhotplug.service --> givc_admin : [2] policy_query: fetch vhotplug_rules
givc_admin --> OPA_server : [3] json query (policy_path, get_rules)
OPA_server --> givc_admin : [4] Query_Result
givc_admin --> vhotplug.service : [5] Query_Result
vhotplug.service --> vhotplug.service : [6] Query_Result -> config (cached)
User --> vhotplug.service : [7] Device addition
vhotplug.service --> qmu.qmpclient : [8] Device addition
@enduml
```

## 4. Component Descriptions

### OPA Server (Admin VM)
- The Open Policy Agent is responsible for evaluating all policy queries.
- Uses Rego-based policies stored on URL, and verifies it's hash.

### Existing givc-admin (Admin VM)
- Additional command with subcommands introduced to query any policy.

###  Policy based vHotPlug rules 
- Sends `policy_query` requests to `givc-admin` at service startup.
- Interprets and caches policy decisions locally to act on user/system events.
- Executes actions such as device passthrough based on the policy rules.


## 5. Design Decisions

### Use of `givc-admin` Interface (Not Direct OPA Exposure)

| Reason              | Justification                                                                 |
|---------------------|--------------------------------------------------------------------------------|
| **givc-admin gateway**  | No need to setup separate secure network for policy evaluation. Using `givc-admin`, we can validate, sanitize, and normalize queries before they reach OPA. |
| **Auditing**         | We can enables centralized logging of all policy interactions.                      |
| **Modularity**       | Easier to update or scale OPA behind `givc-admin` without changing client services. |

## 6. Example Policy Query Flow (vHotplug Use Case)

1. `vhotplug.service` starts and sends a policy query to `givc-admin`.
2. `givc-admin` forwards this as a JSON request to `OPA_server`.
3. `OPA_server` evaluates the query and returns a decision.
4. `givc-admin` relays the result back to the requesting service.
5. The service configures itself according to the policy (e.g., allow only USB class X).
6. When a device is added, the cached configuration is used to permit or deny the operation.
7. (Future Update) When there is any policy update notification update the cached policy.

## 7. Benefits

- Policy enforcement is **centralized**, **auditable**, and **extensible**.
- The architecture is **modular**, allowing additional services to become policy-aware.

## 8. Future Enhancements

- Use OPAL for dynamic policy updates.
- Add **policy versioning and rollback** mechanisms.

## 9. Extra:
### More generic usbhotplug rules:
```json
{
  "rules": {
    "_blacklist_" : [ 
      "List of blacklisted devices.",
      "Format: vendor_id : [list of products].",
      "       ~vendor_id : [list of products].",
      "When starts with ~, all the products of the vendor will be blacklisted except the listed ones.",
      "Vendor and product IDs must be 4 digit hex in 0x00ab format."
    ],
    "blacklist": {
       "0xbadb" : ["0xdada"],
       "~0xbabb" : ["0xcaca"]
    },

    "_whitelist_" : [ 
      "List of devices and VMs which are allowed to access it.",
      "Format: <vendor_id:product_id> : [list of allowed vms].",
      "        <vendor_id:*> : [list of allowed vm].",
      "* indicates all products of the vendor.",
      "vendor and product IDs must be 4 digit hex in 0x00ab format."
    ],
    "whitelist" : {
      "0x0b95:0x1790" : ["net-vm"]
    },



    "_class_rules_" : [ 
      "Device with specific class, subclass, and protocol and it's mapping to VMs.",
      "Format: <class:subclass:protocol> : [list of allowed vms].",
      "* can be used for subclass and protocol.",
      "* indicates all values of that category is accepted.",
      "Must be 2 digit hex in 0x0a format."
    ],
    "class_rules" : {
        "0x01:*:*" : ["audio-vm"],
        "0x03:*:0x01" : ["gui-vm"],
        "0x03:*:0x02" : ["gui-vm"],
        "0x08:0x06:*" : ["gui-vm"],
        "0x0b:*:*" : ["gui-vm"],
        "0x11:*:*" : ["gui-vm"],
        "0xe0:0x01:0x01" : ["gui-vm"],
        "0x02:06:*" : ["net-vm"],
        "0x0e:*:*" : ["chrome-vm"]
    },

    "_device_filter_" : [ 
      "Listed devices will be filtered out from the vm.",
      "Format: <vm-name> : [list of <vendor_id:product_id>].",
      "Vendor and product IDs must be 4 digit hex in 0x00ab format."
    ],
    "device_filter" : {
        "chrome-vm": ["0x04f2:0xb751", "0x5986:0x2145", "0x30c9:0x0052", "0x30c9:0x005f"]
    }
  }
}

```
