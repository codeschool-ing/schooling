---
title: Paths
version: 1
---

gNMI names data with a **path**, written like a file path through the YANG tree: container,
list, key in square brackets, leaf. `/interfaces/interface[name=eth1]/state/oper-status` is the
operational state of `eth1`:

```
ana@ctl:~$ gnmic -a edge1.example.net:9339 get --path "/interfaces/interface[name=eth1]/state/oper-status"
[
  {
    "source": "edge1.example.net:9339",
    "timestamp": 1790681185316367229,
    "time": "2026-09-29T08:26:25.316367229-03:00",
    "updates": [
      {
        "Path": "interfaces/interface[name=eth1]/state/oper-status",
        "values": {
          "interfaces/interface/state/oper-status": "UP"
        }
      }
    ]
  }
]
```

The reply carries a **timestamp** in nanoseconds since 1970, set by the device when it read the
value; `gnmic` adds the same instant in a readable form. Every value gNMI sends has one, and
section 08 is about why that matters.

**OpenConfig separates `config` from `state`.** Under each interface, `config` holds what somebody
asked for and `state` holds what the device is doing: the same leaves, `enabled` or `mtu`, plus
the ones that only exist as state, such as `oper-status` and `counters`. A description set
through `config` shows up in `state` once applied; an interface enabled in `config` can still be
`DOWN` in `state` because the cable is unplugged. Monitoring reads `state`.

A key can be a **wildcard**. `name=*` asks for every interface, and the reply has one update per
match, each with its own full path:

```
ana@ctl:~$ gnmic -a edge1.example.net:9339 get --path "/interfaces/interface[name=*]/state/counters/in-octets"
[
  {
    "source": "edge1.example.net:9339",
    "timestamp": 1790681185402065380,
    "time": "2026-09-29T08:26:25.40206538-03:00",
    "updates": [
      {
        "Path": "interfaces/interface[name=eth0]/state/counters/in-octets",
        "values": {
          "interfaces/interface/state/counters/in-octets": 9441
        }
      },
      {
        "Path": "interfaces/interface[name=eth1]/state/counters/in-octets",
        "values": {
          "interfaces/interface/state/counters/in-octets": 1858
        }
      },
      {
        "Path": "interfaces/interface[name=eth2]/state/counters/in-octets",
        "values": {
          "interfaces/interface/state/counters/in-octets": 0
        }
      },
      {
        "Path": "interfaces/interface[name=lo]/state/counters/in-octets",
        "values": {
          "interfaces/interface/state/counters/in-octets": 0
        }
      }
    ]
  }
]
```

A path can also stop at a container. Then the value is the whole subtree, as one JSON object:

```
ana@ctl:~$ gnmic -a edge1.example.net:9339 get --path "/interfaces/interface[name=eth1]/config"
[
  {
    "source": "edge1.example.net:9339",
    "timestamp": 1790681185471864500,
    "time": "2026-09-29T08:26:25.4718645-03:00",
    "updates": [
      {
        "Path": "interfaces/interface[name=eth1]/config",
        "values": {
          "interfaces/interface/config": {
            "description": "uplink to core1",
            "enabled": true,
            "mtu": 1500,
            "name": "eth1"
          }
        }
      }
    ]
  }
]
```

**A path that matches nothing is an error**, not an empty answer. There is no `eth9`:

```
ana@ctl:~$ gnmic -a edge1.example.net:9339 get --path "/interfaces/interface[name=eth9]/state"
target "edge1.example.net:9339" Get request failed: "edge1.example.net:9339" GetRequest failed: rpc error: code = NotFound desc = nothing at /interfaces/interface[name=eth9]/state
Error: one or more requests failed
```

`NotFound` names the path. A device answers the same code for an interface that does not exist
and for a path its model version does not have, which is the reason to read the capabilities
first.
