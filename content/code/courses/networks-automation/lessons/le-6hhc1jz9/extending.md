---
title: Models that extend models
version: 1
---

`ietf-interfaces` has no IP addresses in it, and that is deliberate: an interface can carry IPv4,
IPv6, MPLS or none of them. The addresses are in another module, `ietf-ip`, which **augments** the
interface list: it adds its own nodes inside a node another module owns.

```
ana@ctl:~$ grep -n -A3 "augment \"/if:interfaces/if:interface\" {" ietf/ietf-ip.yang | head -4
148:  augment "/if:interfaces/if:interface" {
149-    description
150-      "IP parameters on interfaces.
151-
```

Asked for the tree of both modules together, `pyang` shows the added nodes in place, each with the
prefix of the module that added it:

```
ana@ctl:~$ pyang -f tree -p ietf:iana ietf/ietf-interfaces.yang ietf/ietf-ip.yang --tree-path /interfaces/interface/ipv4
module: ietf-interfaces
  +--rw interfaces
     +--rw interface* [name]
        +--rw ip:ipv4!
           +--rw ip:enabled?      boolean
           +--rw ip:forwarding?   boolean
           +--rw ip:mtu?          uint16
           +--rw ip:address* [ip]
           |  +--rw ip:ip                     inet:ipv4-address-no-zone
           |  +--rw (ip:subnet)
           |  |  +--:(ip:prefix-length)
           |  |  |  +--rw ip:prefix-length?   uint8
           |  |  +--:(ip:netmask)
           |  |     +--rw ip:netmask?         yang:dotted-quad {ipv4-non-contiguous-netmasks}?
           |  +--ro ip:origin?                ip-address-origin
           +--rw ip:neighbor* [ip]
              +--rw ip:ip                    inet:ipv4-address-no-zone
              +--rw ip:link-layer-address    yang:phys-address
              +--ro ip:origin?               neighbor-origin
```

`ip:ipv4` sits inside `interface` although `ietf-interfaces` has never heard of it. That is why the
XML of lesson 3 declared a second namespace on `<ipv4>`, and why the RESTCONF JSON wrote
`"ietf-ip:ipv4"`: **each node carries the name of the module that defined it**, not the module it
sits in. The `!` after `ipv4` marks a presence container, one whose mere existence means
something: here, that IPv4 is configured on the interface.

**OpenConfig draws the same interface differently.** Its model separates what was asked for from
what is happening into two containers under every interface:

```
ana@ctl:~$ pyang -f tree -p openconfig openconfig/interfaces/openconfig-interfaces.yang --tree-depth 5 | head -24
module: openconfig-interfaces
  +--rw interfaces
     +--rw interface* [name]
        +--rw name                  -> ../config/name
        +--rw config
        |  +--rw name?            string
        |  +--rw type             identityref
        |  +--rw mtu?             uint16
        |  +--rw loopback-mode?   oc-opt-types:loopback-mode-type
        |  +--rw description?     string
        |  +--rw enabled?         boolean
        +--ro state
        |  +--ro name?            string
        |  +--ro type             identityref
        |  +--ro mtu?             uint16
        |  +--ro loopback-mode?   oc-opt-types:loopback-mode-type
        |  +--ro description?     string
        |  +--ro enabled?         boolean
        |  +--ro ifindex?         uint32
        |  +--ro admin-status     enumeration
        |  +--ro oper-status      enumeration
        |  +--ro last-change?     oc-types:timeticks64
        |  +--ro logical?         boolean
        |  +--ro management?      boolean
```

`config` and `state` hold the same leaves, plus in `state` the ones only the device knows. That
is the shape lesson 4 read through gNMI, and why a description set in `config` appeared in `state`.

**And every vendor has native models**, which cover everything its software can do and follow no
one else's layout. FRR ships 37 of its own:

```
ana@ctl:~$ pyang -f tree -p /usr/share/yang /usr/share/yang/frr-interface.yang 2>/dev/null | head -12
module: frr-interface
  +--rw lib
     +--rw interface* [name]
        +--rw name           string
        +--ro vrf?           frr-vrf:vrf-ref
        +--rw description?   string
        +--ro state
           +--ro if-index?      int32
           +--ro mtu?           uint16
           +--ro mtu6?          uint32
           +--ro speed?         uint32
           +--ro metric?        uint32
ana@ctl:~$ ls /usr/share/yang | grep -c "^frr-"
37
```

The trade-off is the same on every device. Standard models, IETF or OpenConfig, work across
vendors and cover the common part. Native models cover everything and tie the automation to one
vendor. Most networks end up using a standard model where it is enough, and the native one for the
rest.

A vendor can also declare where it departs from a standard model, in a **deviation**: this leaf is
not supported, that range is narrower here. A client that reads the device's deviations knows in
advance which parts of the standard to avoid.
