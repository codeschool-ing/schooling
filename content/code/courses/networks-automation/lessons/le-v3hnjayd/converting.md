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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Three formats and the conversions between them. JSON and YAML, side by side, convert into each other cleanly, since both hold mappings, lists, strings, numbers, booleans and null; YAML to JSON loses only comments. XML, below, converts into either with losses: attributes and namespaces have no place to go, and nothing in XML says which elements are lists, so one interface and two interfaces come out as different types. The YANG model, at the right, is what says which elements are lists.\"><defs><marker id=\"cv-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"30\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">JSON</text><text x=\"120.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no comments</text><rect x=\"320\" y=\"30\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">YAML</text><text x=\"400.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">comments</text><path d=\"M202 58 L316 58\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cv-ah)\"></path><path d=\"M316 76 L202 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#cv-ah)\"></path><text x=\"260\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">clean</text><text x=\"260\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">comments lost</text><rect x=\"180\" y=\"170\" width=\"160\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">XML</text><text x=\"260.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">attributes, namespaces</text><text x=\"260.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no list marker</text><path d=\"M220 168 L130 104\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#cv-ah)\"></path><path d=\"M300 168 L390 104\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#cv-ah)\"></path><text x=\"120\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lossy</text><rect x=\"540\" y=\"100\" width=\"160\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"620.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the YANG model</text><text x=\"620.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">says which nodes</text><text x=\"620.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">are lists</text><path d=\"M538 160 L344 205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#cv-ah)\"></path></svg>", "caption": "JSON and YAML hold the same kinds of thing; XML holds more, and says less about lists."}
```

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
