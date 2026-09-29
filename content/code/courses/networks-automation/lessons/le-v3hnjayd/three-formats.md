---
title: One interface, three formats
version: 1
---

Network automation reads and writes three text formats all day, and each came from a different
place. **XML** is what NETCONF speaks. **JSON** is what REST APIs, RESTCONF and gNMI speak. **YAML**
is what people write by hand: inventories, Ansible playbooks, the intended state kept in a
repository. The same interface, `eth1`, from all three:

```schooling-example
{
  "language": "python",
  "file": "three.py",
  "parts": [
    {
      "code": "import json\n\nimport requests\nimport yaml\n\nfrom nc import NS, connect\n\nwith connect() as m:\n    xml = m.get_config(source=\"running\", filter=(\"xpath\", (NS, \"/if:interfaces/if:interface[if:name='eth1']\"))).data_xml\nprint(xml)\n\nr = requests.get(\"https://nc1.example.net/restconf/data/ietf-interfaces:interfaces/interface=eth1\",\n                 headers={\"Accept\": \"application/yang-data+json\"}, verify=\"lab-ca.pem\", timeout=10)\nprint(r.text)\n",
      "note": "**The same interface from two protocols.** NETCONF answers in XML, RESTCONF in JSON; the helper from lesson 3 opens the NETCONF session."
    },
    {
      "code": "print(json.dumps(yaml.safe_load(open(\"eth1.yaml\")), indent=1))",
      "note": "**And a YAML file a person wrote.** `safe_load` turns it into the same kind of Python dictionary `json.loads` gives."
    }
  ]
}
```

```
ana@ctl:~$ python three.py
<?xml version="1.0" encoding="UTF-8"?><data xmlns="urn:ietf:params:xml:ns:netconf:base:1.0" xmlns:nc="urn:ietf:params:xml:ns:netconf:base:1.0"><interfaces xmlns="urn:ietf:params:xml:ns:yang:ietf-interfaces"><interface xmlns:ianaift="urn:ietf:params:xml:ns:yang:iana-if-type"><name>eth1</name><description>uplink to core1</description><type>ianaift:ethernetCsmacd</type><enabled>true</enabled></interface></interfaces></data>
{
   "ietf-interfaces:interface": [
      {
         "name": "eth1",
         "description": "uplink to core1",
         "type": "iana-if-type:ethernetCsmacd",
         "enabled": true
      }
   ]
}

{
 "name": "eth1",
 "description": "uplink to core1",
 "type": "ethernetCsmacd",
 "enabled": true,
 "ipv4": {
  "address": [
   {
    "ip": "198.51.100.2",
    "prefix-length": 30
   }
  ]
 }
}
```

Read the three answers side by side and the differences are not in the data. **They are in what
each format can say about it.**

- The XML carries **namespaces**, and the value of `type` carries a prefix of its own. Nothing in
  the text says whether `interface` is one element or the first of many.
- The JSON says `interface` is a list, with square brackets, even with one entry in it, and
  writes the module's name in the key, `ietf-interfaces:interface`, which is RFC 7951's way of
  doing what the namespaces did.
- The YAML says what its author wanted and nothing more. `type` is `ethernetCsmacd` with no
  module at all, because a person writing an inventory does not think in modules, and there is an
  `ipv4` address that `nc1` does not have. **A file a person writes is intent; the device's
  answer is fact**, and lesson 11 is about noticing when the two differ.

`yaml.safe_load` turned the YAML into the same kind of Python dictionary the JSON would have given.
Once parsed, a script cannot tell which format the data came from, which is the point: **the
formats are for storage and transport, and the program works on the dictionary.** The trouble all
happens at the edges, in parsing and in writing back, and that is where this lesson looks.
