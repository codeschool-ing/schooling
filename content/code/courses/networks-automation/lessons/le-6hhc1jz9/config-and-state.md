---
title: Configuration and state
version: 1
---

Every node in a model is either **configuration**, what an operator asks for, or **state**, what
the device reports. In YANG the difference is one statement, `config false`, and in the tree it is
`rw` against `ro`. The difference decides what a protocol lets you do with a node:

| | configuration (`rw`) | state (`ro`) |
|---|---|---|
| NETCONF | `get-config` and `edit-config` | only `get` |
| RESTCONF | read and write | read only |
| gNMI | `Set` and read | read only |
| comes from | the operator | the device |

The IETF models have been through two ways of arranging it. The older one, still visible in the
`x--` nodes of `ietf-interfaces`, kept state in a separate tree, `interfaces-state`, so the same
interface appeared twice. Since **NMDA**, the Network Management Datastore Architecture of 2018,
state lives beside configuration in the same tree, and the protocol decides which you are reading:
the `running` datastore holds only configuration, and a datastore called `operational` holds
everything the device is actually using, configured or learnt.

**OpenConfig solved the same problem with its `config` and `state` containers**, and lesson 4 used
them. Neither arrangement is wrong. What matters to a script is knowing which one the model it
reads uses, because asking `running` for `oper-status` returns nothing, and asking OpenConfig's
`config` for a counter does too.

The practical rule: **configure through configuration nodes, monitor through state nodes, and
compare the two to find a problem.** An interface whose configuration says enabled and whose state
says down is the first thing a troubleshooting script should report.
