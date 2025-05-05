package ghaf.usb.hotplug_rules

# Convert vendor+product to a key
vendor_product_key(v, p) = sprintf("%s:%s", [v, p])

# Blacklists
blacklist_global_map := {
  "0x1d6b:0x0002": true
}

blacklist_per_vm_map := {
  "vm_secure": {
    "0xdead:0xbeef": true
  }
}

# More flexible allow structure
allowed_rules := {
  "0x08": [
    {"subclass": ["0x02", "0x06"], "vms": ["vm_storage"]}
  ],
  "0x0e": [
    {"subclass": ["0x01", "0x02"], "vms": ["vm_camera"]}
  ],
  "0x03": [
    {"subclass": ["0x01"], "vms": ["vm_input", "vm_secure"]}
  ],
  "0x0a": [
    {"subclass_range": ["0x00", "0x05"], "vms": ["vm_special"]}
  ]
}

# Global blacklist
device_globally_blacklisted {
  vendor_product_key := vendor_product_key(input.device.vendor_id, input.device.product_id)
  blacklist_global_map[vendor_product_key]
}

# Per-VM blacklist
device_blacklisted_for_vm {
  some vm_bl := blacklist_per_vm_map[input.vm]
  vendor_product_key := vendor_product_key(input.device.vendor_id, input.device.product_id)
  vm_bl[vendor_product_key]
}

# Allow rule check supporting subclass lists and ranges
device_allowed_for_vm {
  rules := allowed_rules[input.device.class]
  some rule
  rule := rules[_]
  allowed_vm := input.vm

  # Match if subclass is listed
  rule.subclass[_] == input.device.subclass
  rule.vms[_] == allowed_vm
}

device_allowed_for_vm {
  rules := allowed_rules[input.device.class]
  some rule
  rule := rules[_]
  allowed_vm := input.vm

  # Match if subclass is in range
  rule.subclass_range = [low, high]
  low <= input.device.subclass
  input.device.subclass <= high
  rule.vms[_] == allowed_vm
}

# Final allow rule
allow {
  not device_globally_blacklisted
  not device_blacklisted_for_vm
  device_allowed_for_vm
}

# Export rules for local eval
rules := {
  "blacklist_global_map": blacklist_global_map,
  "blacklist_per_vm_map": blacklist_per_vm_map,
  "allowed_rules": allowed_rules
}

decision := {
  "vm": input.vm,
  "device": input.device,
  "allowed": allow,
  "reasons": {
    "global_blacklisted": device_globally_blacklisted,
    "vm_blacklisted": device_blacklisted_for_vm,
    "vm_class_allowed": device_allowed_for_vm
  }
}
