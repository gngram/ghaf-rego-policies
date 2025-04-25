package ghaf.usb.hotplug_rules

import future.keywords.in

default rules = []

rules = [
    guivm_rule,
    netvm_rule,
    chromevm_rule,
    audiovm_rule
]

guivm_rule = {
    "name": "GUIVM",
    "qmpSocket": "/var/lib/microvms/gui-vm/gui-vm.sock",
    "usbPassthrough": [
        {
            "class": 3,
            "protocol": 1,
            "description": "HID Keyboard"
        },
        {
            "class": 3,
            "protocol": 2,
            "description": "HID Mouse"
        },
        {
            "class": 11,
            "description": "Chip/SmartCard (e.g. YubiKey)"
        },
        {
            "class": 224,
            "subclass": 1,
            "protocol": 1,
            "description": "Bluetooth",
            "disable": true
        },
        {
            "class": 8,
            "subclass": 6,
            "description": "Mass Storage - SCSI (USB drives)"
        },
        {
            "class": 17,
            "description": "USB-C alternate modes supported by device"
        }
    ],
    "evdevPassthrough": {
        "enable": true,
        "pcieBusPrefix": "rp"
    }
}

netvm_rule = {
    "name": "NetVM",
    "qmpSocket": "/var/lib/microvms/net-vm/net-vm.sock",
    "usbPassthrough": [
        {
            "class": 2,
            "subclass": 6,
            "description": "Communications - Ethernet Networking"
        },
        {
            "vendorId": "0b95",
            "productId": "1790",
            "description": "ASIX Elec. Corp. AX88179 UE306 Ethernet Adapter"
        }
    ]
}

chromevm_rule = {
    "name": "ChromeVM",
    "qmpSocket": "/var/lib/microvms/chrome-vm/chrome-vm.sock",
    "usbPassthrough": [
        {
            "class": 14,
            "description": "Video (USB Webcams)",
            "ignore": [
                {
                    "vendorId": "04f2",
                    "productId": "b751",
                    "description": "Lenovo X1 Integrated Camera"
                },
                {
                    "vendorId": "5986",
                    "productId": "2145",
                    "description": "Lenovo X1 Integrated Camera"
                },
                {
                    "vendorId": "30c9",
                    "productId": "0052",
                    "description": "Lenovo X1 Integrated Camera"
                },
                {
                    "vendorId": "30c9",
                    "productId": "005f",
                    "description": "Lenovo X1 Integrated Camera"
                }
            ]
        }
    ]
}
audiovm_rule = {
    "name": "AudioVM",
    "qmpSocket": "/var/lib/microvms/audio-vm/audio-vm.sock",
    "usbPassthrough": [
        {
            "class": 1,
            "description": "Audio"
        }
    ]
}

get_rules = rules if {
  true
}
