---
title: Converting between formats
version: 1
---

A script often has data in one format and needs it in another: a NETCONF reply to be stored as
JSON, a YAML inventory to be sent to a REST API. **JSON and YAML convert cleanly into each other**,
because both describe the same things: mappings, lists, strings, numbers, booleans and null. Load
one, dump the other.

**XML does not convert cleanly into either**, because it describes different things. An element
can have attributes and text at once, names carry namespaces, and nothing marks a list.
`xmltodict` is the usual bridge, and the last difference shows up at once:

```schooling-example
{
  "language": "python",
  "file": "single.py",
  "parts": [
    {
      "code": "import json\n\nimport xmltodict\n\nONE = \"<interfaces><interface><name>eth1</name></interface></interfaces>\"\nTWO = \"<interfaces><interface><name>eth1</name></interface><interface><name>eth2</name></interface></interfaces>\"\n"
    },
    {
      "code": "print(json.dumps(xmltodict.parse(ONE)))\nprint(json.dumps(xmltodict.parse(TWO)))",
      "note": "**XML does not say whether an element is a list.** One `<interface>` comes out as a dictionary, two as a list, and a loop written for one breaks on the other."
    },
    {
      "code": "print(json.dumps(xmltodict.parse(ONE, force_list=(\"interface\",))))",
      "note": "**`force_list` names the elements that are lists**, which is what the YANG model would have said."
    }
  ]
}
```

```
ana@ctl:~$ python single.py
{"interfaces": {"interface": {"name": "eth1"}}}
{"interfaces": {"interface": [{"name": "eth1"}, {"name": "eth2"}]}}
{"interfaces": {"interface": [{"name": "eth1"}]}}
```

One `<interface>` became a dictionary; two became a list of dictionaries. **The same code path
receives two different types depending on how many interfaces a device happens to have**, and a
`for i in data["interfaces"]["interface"]` written against the second iterates over the keys of the
first. It passes every test on a lab router with three interfaces and fails on the one branch
router that has a single uplink.

`force_list` names the elements that are always lists, and then one interface comes back as a
list of one. What the script really needs to know is which elements are lists, and **that is
exactly what the YANG model says**: `interface*` in the tree of lesson 5. That is why the formats
derived from a model avoid the problem instead of patching it: the RESTCONF JSON of lesson 3 wrote
`interface` as a list with one entry, because the model said it was a list.

Round trips lose things. XML to JSON loses the namespaces unless the converter keeps them, JSON to
YAML loses nothing, and YAML to JSON loses comments, which YAML has and JSON does not. A file a
person maintains should stay in the format they maintain it in, and conversions should happen on
the way to a device, not on the way back to the repository.
