---
title: A model, and data that fits it
version: 1
---

Lessons 3 and 4 kept meeting names that came from somewhere: `ietf-interfaces`, `ietf-ip`,
`openconfig-interfaces`. Each is a **YANG module**, a file that describes what a piece of
configuration and state looks like: which items exist, how they nest, what type each value has
and which values are allowed. **The module is the schema; a device's configuration is data that
fits it.** A YANG model says there is a list of interfaces keyed by name and that each has a
description; `nc1`'s configuration says there is an interface called `eth1` whose description is
`uplink to core1`.

YANG, RFC 7950, was written for NETCONF, and it outgrew it. The same model describes the data
whichever protocol carries it, which is why lesson 3 could write `eth2`'s description over
RESTCONF and read it back over NETCONF without either knowing about the other:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"One YANG model, ietf-interfaces, and the same leaf, the description of eth1, as three protocols carry it. NETCONF writes it as XML elements in the model&#x27;s namespace. RESTCONF writes it as JSON with the module name as a prefix, and puts the path in the URL. gNMI names it with a path of elements and keys.\"><defs><marker id=\"om-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"250\" y=\"16\" width=\"220\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the model</text><text x=\"360.0\" y=\"48.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">module ietf-interfaces</text><text x=\"360.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">container interfaces</text><text x=\"360.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">list interface [name]</text><text x=\"360.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">leaf description</text><rect x=\"6\" y=\"180\" width=\"228\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">NETCONF</text><text x=\"120.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;interfaces xmlns=&quot;…ietf-interfaces&quot;&gt;</text><text x=\"120.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;interface&gt;&lt;name&gt;eth1&lt;/name&gt;</text><text x=\"120.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;description&gt;uplink…&lt;/description&gt;</text><path d=\"M360 114 L120 176\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#om-ah)\"></path><rect x=\"246\" y=\"180\" width=\"228\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">RESTCONF</text><text x=\"360.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">…/ietf-interfaces:interfaces/</text><text x=\"360.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">interface=eth1/description</text><text x=\"360.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">{&quot;ietf-interfaces:description&quot;: …}</text><path d=\"M360 114 L360 176\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#om-ah)\"></path><rect x=\"486\" y=\"180\" width=\"228\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">gNMI</text><text x=\"600.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/interfaces/</text><text x=\"600.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">interface[name=eth1]/</text><text x=\"600.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">description</text><path d=\"M360 114 L600 176\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#om-ah)\"></path><text x=\"360\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the protocol changes the spelling, not the data</text></svg>", "caption": "The model is written once. Each protocol derives its names from it."}
```

That is the practical value for automation. **Everything a program needs to know about a device's
data is in the model**: the names it may use in a path, the type of every value, the values the
device will refuse. A script that reads the model can check its own data before sending it, and
a tool can generate the client, the documentation or the CLI from it. Clixon, the software behind
`nc1`, can generate a CLI from its models, and `gnmic`'s interactive mode completes paths from them.

The models themselves come from three kinds of publisher, and a network engineer meets all three:

| publisher | examples | written for |
|---|---|---|
| standards bodies | `ietf-interfaces`, `ietf-ip`, `ietf-routing` | every vendor, agreed slowly |
| operator groups | `openconfig-interfaces`, `openconfig-bgp` | what large operators need, versioned fast |
| each vendor | FRR's `frr-interface`, and every vendor's own | everything that device can do |

The IETF modules used in this lesson are the ones `pyang` installs beside itself, 69 of them:

```
ana@ctl:~$ ls ietf | head -8; ls ietf | wc -l
ietf-access-control-list.yang
ietf-acldns.yang
ietf-alarms-x733.yang
ietf-alarms.yang
ietf-datastores.yang
ietf-dslite.yang
ietf-ethertypes.yang
ietf-hardware-state.yang
69
```
