---
title: Reading a model as a tree
version: 1
---

A YANG file is long. `ietf-interfaces.yang` is mostly descriptions and references, and the
structure is hard to see in it. **`pyang -f tree` prints only the structure**, and it is how most
people read a model for the first time:

```
ana@ctl:~$ pyang -f tree -p ietf:iana ietf/ietf-interfaces.yang
module: ietf-interfaces
  +--rw interfaces
  |  +--rw interface* [name]
  |     +--rw name                        string
  |     +--rw description?                string
  |     +--rw type                        identityref
  |     +--rw enabled?                    boolean
  |     +--rw link-up-down-trap-enable?   enumeration {if-mib}?
  |     +--ro admin-status                enumeration {if-mib}?
  |     +--ro oper-status                 enumeration
  |     +--ro last-change?                yang:date-and-time
  |     +--ro if-index                    int32 {if-mib}?
  |     +--ro phys-address?               yang:phys-address
  |     +--ro higher-layer-if*            interface-ref
  |     +--ro lower-layer-if*             interface-ref
  |     +--ro speed?                      yang:gauge64
  |     +--ro statistics
  |        +--ro discontinuity-time    yang:date-and-time
  |        +--ro in-octets?            yang:counter64
  |        +--ro in-unicast-pkts?      yang:counter64
  |        +--ro in-broadcast-pkts?    yang:counter64
  |        +--ro in-multicast-pkts?    yang:counter64
  |        +--ro in-discards?          yang:counter32
  |        +--ro in-errors?            yang:counter32
  |        +--ro in-unknown-protos?    yang:counter32
  |        +--ro out-octets?           yang:counter64
  |        +--ro out-unicast-pkts?     yang:counter64
  |        +--ro out-broadcast-pkts?   yang:counter64
  |        +--ro out-multicast-pkts?   yang:counter64
  |        +--ro out-discards?         yang:counter32
  |        +--ro out-errors?           yang:counter32
  x--ro interfaces-state
     x--ro interface* [name]
        x--ro name               string
        x--ro type               identityref
        x--ro admin-status       enumeration {if-mib}?
        x--ro oper-status        enumeration
        x--ro last-change?       yang:date-and-time
        x--ro if-index           int32 {if-mib}?
        x--ro phys-address?      yang:phys-address
        x--ro higher-layer-if*   interface-state-ref
        x--ro lower-layer-if*    interface-state-ref
        x--ro speed?             yang:gauge64
        x--ro statistics
           x--ro discontinuity-time    yang:date-and-time
           x--ro in-octets?            yang:counter64
           x--ro in-unicast-pkts?      yang:counter64
           x--ro in-broadcast-pkts?    yang:counter64
           x--ro in-multicast-pkts?    yang:counter64
           x--ro in-discards?          yang:counter32
           x--ro in-errors?            yang:counter32
           x--ro in-unknown-protos?    yang:counter32
           x--ro out-octets?           yang:counter64
           x--ro out-unicast-pkts?     yang:counter64
           x--ro out-broadcast-pkts?   yang:counter64
           x--ro out-multicast-pkts?   yang:counter64
           x--ro out-discards?         yang:counter32
           x--ro out-errors?           yang:counter32
```

Each line is a node, and the symbols are a small language of their own:

| mark | means |
|---|---|
| `+--rw` | configuration: read and write |
| `+--ro` | state: read only, reported by the device |
| `x--` | deprecated: still there, replaced by something else |
| `*` after a name | a list or a leaf-list, which can have many entries |
| `[name]` | the key of a list |
| `?` after a name | optional |
| `{if-mib}?` | only present if the device supports the feature `if-mib` |

So `interface* [name]` is a list keyed by `name`; `description?` is an optional string; `type`
has no `?` because every interface must have one, which is exactly the refusal lesson 3 met when
it created `eth3` without it. `oper-status` is `ro`: nobody configures whether a link is up.

**The whole `interfaces-state` tree is marked `x`.** It is how this model used to report state:
a second tree, read only, beside the configuration. The 2018 revision moved state into the same
tree as configuration, marked `ro`, and kept the old tree deprecated so existing clients would not
break. Section 06 comes back to it.

The type column names built-in types, `string`, `boolean`, `int32`, and types defined in other
modules with a prefix: `yang:counter64` comes from `ietf-yang-types`. A counter type tells a
program the value only grows and may wrap, which is what lesson 4's collector needed to know.
