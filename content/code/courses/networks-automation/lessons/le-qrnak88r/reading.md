---
title: Reading with ncclient
version: 1
---

Every script in this lesson imports one small module. It opens the session and builds the XML
the edits need, and it carries one more helper, `describe`, that later sections use to print one
interface from one datastore:

```schooling-example
{
  "language": "python",
  "file": "nc.py",
  "parts": [
    {
      "code": "from ncclient import manager\n\nIF = \"urn:ietf:params:xml:ns:yang:ietf-interfaces\"\nNS = {\"if\": IF}\n\n\ndef connect():\n    return manager.connect(host=\"nc1.example.net\", port=830, username=\"netops\",\n                           key_filename=\"/home/ana/.ssh/id_ed25519\", hostkey_verify=True)\n\n",
      "note": "**One helper, imported by every script in this lesson.** `ncclient` does the SSH, the hello and the framing; `hostkey_verify=True` checks nc1's key against `~/.ssh/known_hosts`, the same promise HTTPS made in lesson 2."
    },
    {
      "code": "def interface_config(body):\n    return (f'<config xmlns=\"urn:ietf:params:xml:ns:netconf:base:1.0\">'\n            f'<interfaces xmlns=\"{IF}\">{body}</interfaces></config>')\n\n\ndef describe(m, source, name):\n    \"\"\"The description and enabled leaves of one interface, read from a datastore.\"\"\"\n    xpath = f\"/if:interfaces/if:interface[if:name='{name}']\"\n    data = m.get_config(source=source, filter=(\"xpath\", (NS, xpath))).data\n    desc = data.findtext(\".//if:description\", default=\"(none)\", namespaces=NS)\n    enabled = data.findtext(\".//if:enabled\", namespaces=NS)\n    return f\"{source:<9} {name}: description={desc!r} enabled={enabled}\"",
      "note": "**Every edit in this lesson is a `<config>` wrapping part of the ietf-interfaces tree.** The outer element belongs to NETCONF's namespace and the inner ones to the model's; section 06 shows what happens when the first is left out."
    }
  ]
}
```

Reading the configuration, and the capabilities the server announced:

```schooling-example
{
  "language": "python",
  "file": "read.py",
  "parts": [
    {
      "code": "from nc import NS, connect\n\nwith connect() as m:"
    },
    {
      "code": "    for c in (\"candidate\", \"confirmed-commit\", \"validate\"):\n        print(c, any(f\":{c}:\" in cap for cap in m.server_capabilities))",
      "note": "**The session starts with a hello**, and `ncclient` keeps what the server said it can do. Three capabilities decide what the rest of this lesson may use."
    },
    {
      "code": "    reply = m.get_config(source=\"running\", filter=(\"xpath\", (NS, \"/if:interfaces/if:interface/if:description\")))",
      "note": "**A filter asks for part of the tree.** This one is XPath: every interface's description, which brings its name along because the name is the list's key. The prefix `if:` has to be mapped to the model's namespace, and `NS` is that map."
    },
    {
      "code": "    for i in reply.data.findall(\".//if:interface\", NS):\n        print(i.findtext(\"if:name\", namespaces=NS), \"-\", i.findtext(\"if:description\", namespaces=NS))",
      "note": "**The reply is XML, and reading it needs the namespace too.** `findall` with `if:` finds the model's elements; without the prefix it would find nothing and say nothing."
    }
  ]
}
```

```
ana@ctl:~$ python read.py
candidate True
confirmed-commit True
validate True
eth0 - management
eth1 - uplink to core1
```

**The filter decides how much comes back.** A `get-config` without one returns the whole
configuration, which on a real router is thousands of lines. NETCONF has two kinds of filter.
The **subtree** filter of the previous section is XML shaped like the part you want. The
**XPath** filter here is an expression, and it needs the server to announce `xpath` in its hello,
which `nc1` does.

Only `eth0` and `eth1` came back. `eth2` exists, but it has no description, and the filter asked
for descriptions. **An element that is not set is absent**, not empty: there is no
`<description/>` for a leaf nobody configured, and a script that expects one has to handle its
absence.

The reply is an `lxml` element, and **finding anything in it needs the namespace**. `NS` maps the
prefix `if` to the model's namespace, and `findall(".//if:interface", NS)` finds the interfaces.
Leave out the prefix and `findall(".//interface")` returns an empty list, silently, because no
element called `interface` exists in no namespace. That silence is the classic NETCONF bug.
