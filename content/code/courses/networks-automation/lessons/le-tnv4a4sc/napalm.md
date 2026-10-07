---
title: NAPALM, the same methods everywhere
version: 2
---

Netmiko still leaves the script speaking each vendor's language: the commands, the output format and
the error messages all differ. **NAPALM puts one interface over all of them.** A driver per platform
implements the same methods, so `get_facts()` returns the same dictionary with the same keys from a
Juniper, an Arista or a Cisco router, and the script never sees a command.

NAPALM ships drivers for EOS, IOS, IOS-XR, Junos and NX-OS, and other platforms have community
drivers, found by name: `get_network_driver("xyz")` imports a package called `napalm_xyz`. **There is
none for FRR**, so the lab has one, `napalm_frr`, the driver the previous section printed; it logs in
with Netmiko and uses FRR's own tool, `frr-reload.py`, to work out configuration changes. What this section shows is
NAPALM's interface, which is the same whatever the driver.

```schooling-example
{
  "language": "python",
  "file": "facts.py",
  "parts": [
    {
      "code": "import json\n\nfrom napalm import get_network_driver\n"
    },
    {
      "code": "driver = get_network_driver(\"frr\")\nwith driver(\"edge1\", \"netops\", None, optional_args={\"key_file\": \"/home/ana/.ssh/id_ed25519\"}) as dev:\n    print(json.dumps(dev.get_facts(), indent=2))\n    print(json.dumps(dev.get_interfaces_ip(), indent=2))",
      "note": "**NAPALM asks for a driver by name** and gets a class with the same methods on every platform: `get_facts`, `get_interfaces`, `load_merge_candidate`. Here the name is `frr`, the lab's driver, because NAPALM ships none for FRR; with `eos` or `junos` the rest of the file would not change."
    }
  ]
}
```

```
ana@ctl:~$ python facts.py
{
  "hostname": "edge1",
  "fqdn": "edge1.example.net",
  "vendor": "FRRouting",
  "model": "FRR",
  "os_version": "8.4.4",
  "serial_number": "",
  "uptime": -1.0,
  "interface_list": [
    "eth0",
    "eth1",
    "eth2",
    "lo"
  ]
}
{
  "eth0": {
    "ipv4": {
      "192.0.2.12": {
        "prefix_length": 24
      }
    }
  },
  "eth1": {
    "ipv4": {
      "198.51.100.2": {
        "prefix_length": 30
      }
    }
  },
  "eth2": {
    "ipv4": {
      "203.0.113.1": {
        "prefix_length": 26
      }
    }
  },
  "lo": {
    "ipv4": {
      "203.0.113.252": {
        "prefix_length": 32
      }
    }
  }
}
```

Two getters, two dictionaries in a documented shape. `uptime` is `-1.0` because FRR does not report
how long the router has been up, and the driver says so with NAPALM's convention for an unknown value
rather than inventing one. **That is the trade NAPALM makes**: the same keys everywhere, and some of
them empty on platforms that cannot fill them.

The getters cover what most scripts read: interfaces, their addresses and counters, ARP and MAC
tables, BGP neighbours, LLDP neighbours, the configuration. A script written against them runs on
every platform with a driver, and lesson 13's checks use them for exactly that reason.
