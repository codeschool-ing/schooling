---
title: One transaction, checked against the model
version: 1
---

The YANG model says what a valid configuration is: that `prefix-length` in `ietf-ip` is a number
from 0 to 32, that every interface in `ietf-interfaces` has a `type`. **The candidate is allowed to
be invalid while it is being edited**; it has to be valid to become running. `validate` asks
without committing:

```schooling-example
{
  "language": "python",
  "file": "invalid.py",
  "parts": [
    {
      "code": "from ncclient.operations import RPCError\n\nfrom nc import connect, interface_config\n\nBAD = \"\"\"<interface><name>eth2</name>\n  <ipv4 xmlns=\"urn:ietf:params:xml:ns:yang:ietf-ip\">\n    <address><ip>192.0.2.99</ip><prefix-length>33</prefix-length></address>\n  </ipv4></interface>\"\"\"\n\nwith connect() as m:\n    m.edit_config(target=\"candidate\", config=interface_config(BAD))\n    print(\"edit-config: ok\")"
    },
    {
      "code": "    try:\n        m.validate(source=\"candidate\")\n    except RPCError as e:\n        print(\"validate:\", e.tag)\n        print(\" \", e.message)\n    m.discard_changes()\n    print(\"discard-changes: ok\")",
      "note": "**`validate` checks the whole candidate against the model** without applying it. `RPCError` carries the error's tag, its message and the path of the leaf that failed."
    }
  ]
}
```

```
ana@ctl:~$ python invalid.py
edit-config: ok
validate: bad-element
  Number 33 out of range: 0 - 32: yang node: "leaf prefix-length" with parent: "choice subnet" in file "/etc/clixon/yang/ietf-ip.yang" error-path: /interfaces/interface[name="eth2"]/ipv4/address[ip="192.0.2.99"]/prefix-length
discard-changes: ok
```

The edit itself was accepted: the candidate is a draft, and drafts are allowed to be wrong.
`validate` then refused it with an **error tag**, `bad-element`, a message naming the range the
model allows, and the **path** of the leaf that broke it. A script can act on all three, and
lesson 13 makes validating before committing a step of every change.

**A commit is all or nothing.** Two changes in one edit, one fine and one missing the mandatory
`type`:

```schooling-example
{
  "language": "python",
  "file": "transaction.py",
  "parts": [
    {
      "code": "from ncclient.operations import RPCError\n\nfrom nc import connect, describe, interface_config\n\nwith connect() as m:"
    },
    {
      "code": "    m.edit_config(target=\"candidate\", config=interface_config(\n        \"<interface><name>eth1</name><description>uplink to core1, port 7</description></interface>\"\n        \"<interface><name>eth3</name></interface>\"))\n    try:\n        m.commit()\n    except RPCError as e:\n        print(\"commit:\", e.tag, \"-\", e.message.split(\".\")[0])",
      "note": "**Two changes in one edit.** The first is fine. The second creates `eth3` without a `type`, which the model says every interface must have."
    },
    {
      "code": "    print(describe(m, \"running\", \"eth1\"))\n    print(describe(m, \"candidate\", \"eth1\"))\n    m.discard_changes()\n    print(describe(m, \"candidate\", \"eth1\"))",
      "note": "**Nothing was applied**: not the broken half, and not the good one. The edit is still in the candidate until it is discarded, which a script must do before the next person's commit picks it up."
    }
  ]
}
```

```
ana@ctl:~$ python transaction.py
commit: missing-element - Missing mandatory XML type node
running   eth1: description='uplink to core1' enabled=true
candidate eth1: description='uplink to core1, port 7' enabled=true
candidate eth1: description='uplink to core1' enabled=true
```

The commit was refused, and running kept the old description of `eth1` even though that half of
the edit was valid. That is the transaction: **the device is never left between two
configurations**. The last two lines show the other half of the lesson. The rejected edit was
still sitting in the candidate after the failure, and only `discard-changes` removed it. A script
that forgets that step leaves its mistake for the next commit to pick up.

One error happens before any of this, and it is not the model's. The XML has two namespaces in
it: `<config>` is NETCONF's own element and belongs to `urn:ietf:params:xml:ns:netconf:base:1.0`,
while everything inside it belongs to the model. Leave the first out:

```
ana@ctl:~$ python -c 'from nc import connect; connect().edit_config(target="candidate", config="<config><interfaces xmlns=\"urn:ietf:params:xml:ns:yang:ietf-interfaces\"/></config>")' 2>&1 | tail -1
ncclient.operations.rpc.RPCError: Missing namespace
```

**`Missing namespace`**, and the server is right. That is why `interface_config` in `nc.py`
writes both.
