---
title: Writing a module
version: 1
---

Models are not only for devices. The lab's branches are data too, and describing them in YANG gives
them the same checks a device applies. A module for them:

```
module example-branches {
  yang-version 1.1;
  namespace "urn:example:branches";
  prefix br;

  import ietf-inet-types { prefix inet; }

  description "The branches of the lab's network, as data.";

  revision 2026-09-29 { description "First version."; }

  typedef branch-id {
    type uint16 { range "1..999"; }
    description "A branch's number, as the finance team assigns it.";
  }

  container branches {
    list branch {
      key "id";
      must "status != 'active' or dns-server" {
        error-message "an active branch needs at least one DNS server";
      }
      leaf id { type branch-id; }
      leaf name {
        type string { length "1..32"; }
        mandatory true;
      }
      leaf lan {
        type inet:ipv4-prefix;
        mandatory true;
      }
      leaf edge-router { type string; }
      leaf-list dns-server {
        type inet:ipv4-address;
        max-elements 2;
      }
      leaf status {
        type enumeration {
          enum planned;
          enum active;
          enum closed;
        }
        default planned;
      }
    }
  }
}
```

Every piece is one of the previous sections: a `typedef` with a `range`, a `list` keyed by `id`, a
`mandatory` name with a `length`, a `lan` typed with `inet:ipv4-prefix` imported from
`ietf-inet-types`, a `leaf-list` of at most two DNS servers, and an `enumeration` with a `default`.
One statement is new. **`must` is a rule across nodes**, an XPath expression that has to be true
for every branch: here, a branch that is `active` needs at least one `dns-server`.

`pyang` checks the module itself, and prints nothing when it is valid:

```
ana@ctl:~$ pyang -p ietf example-branches.yang; echo "exit status $?"
exit status 0
ana@ctl:~$ pyang -f tree -p ietf example-branches.yang
module: example-branches
  +--rw branches
     +--rw branch* [id]
        +--rw id             branch-id
        +--rw name           string
        +--rw lan            inet:ipv4-prefix
        +--rw edge-router?   string
        +--rw dns-server*    inet:ipv4-address
        +--rw status?        enumeration
```

A typo in a type name, and `pyang` points at the line:

```
ana@ctl:~$ sed 's/type uint16 {/type unit16 {/' example-branches.yang > broken.yang
ana@ctl:~$ pyang -p ietf broken.yang; echo "exit status $?"
broken.yang:1: warning: unexpected modulename "example-branches" in broken.yang, should be "broken"
broken.yang:13: error: type "unit16" not found in module "example-branches"
exit status 1
```

The warning is `pyang` noticing the file name no longer matches the module's name, which is a
convention and not a rule. The error is the real finding. **Checking the model is the first half;
the second is checking data against it.** Three branches in the JSON encoding RFC 7951 defines,
the one RESTCONF used in lesson 3:

```json
{
  "example-branches:branches": {
    "branch": [
      {
        "id": 1,
        "name": "Branch 1",
        "lan": "203.0.113.0/26",
        "edge-router": "edge1",
        "dns-server": ["192.0.2.53"],
        "status": "active"
      },
      {
        "id": 2,
        "name": "Branch 2",
        "lan": "203.0.113.64/26",
        "edge-router": "edge2",
        "dns-server": ["192.0.2.53"],
        "status": "active"
      },
      {
        "id": 3,
        "name": "Branch 3",
        "lan": "203.0.113.128/26"
      }
    ]
  }
}
```

`yanglint`, from libyang, validates data against a model, and again silence means valid:

```
ana@ctl:~$ yanglint -p ietf example-branches.yang branches.json; echo "exit status $?"
exit status 0
ana@ctl:~$ yanglint -f json -p ietf example-branches.yang branches.json | tail -9
      },
      {
        "id": 3,
        "name": "Branch 3",
        "lan": "203.0.113.128/26"
      }
    ]
  }
}
```

Asked to print the data back, it returns it as parsed; branch 3 kept only what the file gave it.
**Now four ways to break it**, each caught by one line of the module:

```
ana@ctl:~$ sed 's/"id": 3,/"id": 1000,/' branches.json > bad-id.json
ana@ctl:~$ yanglint -p ietf example-branches.yang bad-id.json; echo "exit status $?"
libyang err : Unsatisfied range - value "1000" is out of the allowed range. (Data location "/example-branches:branches/branch/id", line number 21.)
YANGLINT[E]: Failed to parse input data file "bad-id.json".
exit status 7
```

```
ana@ctl:~$ sed 's#203.0.113.128/26#203.0.113.128/33#' branches.json > bad-lan.json
ana@ctl:~$ yanglint -p ietf example-branches.yang bad-lan.json; echo "exit status $?"
libyang err : Unsatisfied pattern - "203.0.113.128/33" does not conform to "(([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])/(([0-9])|([1-2][0-9])|(3[0-2]))". (Data location "/example-branches:branches/branch[id='3']/lan", line number 24.)
YANGLINT[E]: Failed to parse input data file "bad-lan.json".
exit status 7
```

```
ana@ctl:~$ python3 -c 'import json; d=json.load(open("branches.json")); b=d["example-branches:branches"]["branch"][2]; b["status"]="active"; json.dump(d, open("bad-dns.json","w"))'
ana@ctl:~$ yanglint -p ietf example-branches.yang bad-dns.json; echo "exit status $?"
libyang err : an active branch needs at least one DNS server (Data location "/example-branches:branches/branch[id='3']".)
YANGLINT[E]: Failed to parse input data file "bad-dns.json".
exit status 7
```

```
ana@ctl:~$ python3 -c 'import json; d=json.load(open("branches.json")); del d["example-branches:branches"]["branch"][1]["name"]; json.dump(d, open("bad-name.json","w"))'
ana@ctl:~$ yanglint -p ietf example-branches.yang bad-name.json; echo "exit status $?"
libyang err : Mandatory node "name" instance does not exist. (Schema location "/example-branches:branches/branch/name".)
YANGLINT[E]: Failed to parse input data file "bad-name.json".
exit status 7
```

The range of `branch-id`, the pattern inside `inet:ipv4-prefix`, the `must` with its own
`error-message`, and `mandatory`. Each error names where in the data it found the problem, and
`yanglint` exits with a non-zero status, which is what makes it a step in a pipeline. **Lesson 13
validates the network's intended data exactly like this**, before anything reaches a device.
