---
title: Changing a value with Set
version: 1
---

`Set` changes configuration, and it writes to `config`, never to `state`. **One `Set` can carry
several changes, and the device applies them all or none**, the same promise as a NETCONF commit
without the candidate to prepare it in. `gnmic set` with one update:

```
ana@ctl:~$ gnmic -a edge1.example.net:9339 set --update-path "/interfaces/interface[name=eth2]/config/description" --update-value "branch 1 LAN"
{
  "source": "edge1.example.net:9339",
  "timestamp": 1790681213416429796,
  "time": "2026-09-29T08:26:53.416429796-03:00",
  "results": [
    {
      "operation": "UPDATE",
      "path": "interfaces/interface[name=eth2]/config/description"
    }
  ]
}
ana@ctl:~$ ssh netops@edge1 "show running-config" | grep -A1 "interface eth2"
interface eth2
 description branch 1 LAN
```

The router's own configuration, read through its CLI, has the line FRR would have written if a
person had typed it. That is because the target turned the `Set` into the same `vtysh` command,
which is also what makes the two ways of changing the router agree.

Each change in a `Set` is one of three kinds. **`update` merges** the value into what is there,
**`replace` makes the subtree exactly** what was sent, and **`delete` removes it**. They are the
gNMI names for what NETCONF called merge, replace and delete in lesson 3.

A device refuses what it does not support. The lab's target accepts `description` and `enabled`
under `config` and nothing else, and it says so:

```
ana@ctl:~$ gnmic -a edge1.example.net:9339 set --update-path "/interfaces/interface[name=eth2]/config/mtu" --update-value 9000
target "edge1.example.net:9339" set request failed: target "edge1.example.net:9339" SetRequest failed: rpc error: code = InvalidArgument desc = mtu cannot be set here
Error: one or more requests failed
```

`InvalidArgument`, with a sentence. Real devices support far more of the model, and they refuse
the rest the same way. **gNMI `Set` is used less than NETCONF for configuration** in practice:
it has no candidate, no validate and no confirmed commit, so changes that need those stay on
NETCONF, and gNMI is used for what it was built for, which is watching.
