---
title: XML and namespaces
version: 1
---

XML's structure is elements inside elements, with text inside the innermost. What makes NETCONF's
XML difficult is not the structure, it is the **namespaces**. Lesson 3 met the trap once; here it
is in isolation, on a reply shaped like the ones `nc1` sends:

```schooling-example
{
  "language": "python",
  "file": "xml_read.py",
  "parts": [
    {
      "code": "import xml.etree.ElementTree as ET\n\nREPLY = \"\"\"<data xmlns=\"urn:ietf:params:xml:ns:netconf:base:1.0\">\n  <interfaces xmlns=\"urn:ietf:params:xml:ns:yang:ietf-interfaces\">\n    <interface>\n      <name>eth1</name>\n      <description>uplink to core1</description>\n      <ipv4 xmlns=\"urn:ietf:params:xml:ns:yang:ietf-ip\">\n        <address><ip>198.51.100.2</ip><prefix-length>30</prefix-length></address>\n      </ipv4>\n    </interface>\n  </interfaces>\n</data>\"\"\"\n\nroot = ET.fromstring(REPLY)"
    },
    {
      "code": "print(root[0][0].tag)\nprint(root.findall(\".//interface\"))",
      "note": "**Every element's real name includes its namespace.** ElementTree writes it in braces, which is why a search for `interface` alone finds nothing."
    },
    {
      "code": "NS = {\"if\": \"urn:ietf:params:xml:ns:yang:ietf-interfaces\", \"ip\": \"urn:ietf:params:xml:ns:yang:ietf-ip\"}\nfor i in root.findall(\".//if:interface\", NS):\n    print(i.findtext(\"if:name\", namespaces=NS), i.findtext(\"ip:ipv4/ip:address/ip:prefix-length\", namespaces=NS))",
      "note": "**A map from prefixes to namespaces fixes it.** The prefixes are the script's own choice; only the namespaces have to match."
    }
  ]
}
```

```
ana@ctl:~$ python xml_read.py
{urn:ietf:params:xml:ns:yang:ietf-interfaces}interface
[]
eth1 30
```

The first line printed is the element's **real name**: the namespace in braces, then the local
name. That is the name ElementTree compares against, so `findall(".//interface")` asks for an
element called `interface` in **no** namespace, and there is none. The empty list on the second
line is the whole problem, and the silence is what makes it expensive: nothing raises an error,
and a loop over an empty list does nothing.

The third line is the fix. A dictionary maps short prefixes to namespaces, and every search uses
the prefixes. **The prefixes are the script's own**: the document could use `if`, `ns0` or no
prefix at all, and the search still matches, because only the namespace is compared. `ip:` reaches
into the `ietf-ip` part of the tree, where the address and its prefix length are.

The rules that follow for every script that reads NETCONF:

- **Declare every namespace you read from**, once, in one dictionary.
- **Treat an empty result as suspicious.** An interface list that comes back empty from a device
  that certainly has interfaces is almost always a namespace, not a device.
- **Use a filter on the device side** where you can, as lesson 3 did, so the reply holds only what
  you need and the search has less to get wrong.
