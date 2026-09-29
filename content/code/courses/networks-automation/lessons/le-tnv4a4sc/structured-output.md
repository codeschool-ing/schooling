---
title: Asking for data instead of a screen
version: 1
---

The fix for screen-scraping is not a better regular expression. **It is asking the device for
structured output**, which most platforms can now give for most `show` commands. FRR answers in JSON
when the command ends in `json`:

```
ana@ctl:~$ ssh netops@core1 "show ip ospf neighbor json" | head -14
{
  "neighbors":{
    "203.0.113.252":[
      {
        "priority":1,
        "state":"Full\/-",
        "nbrPriority":1,
        "nbrState":"Full\/-",
        "converged":"Full",
        "role":"DROther",
        "upTimeInMsec":11922,
        "deadTimeMsecs":38346,
        "routerDeadIntervalTimerDueMsec":38346,
        "upTime":"11.922s",
```

Every value is named: `nbrState` is `Full/-`, `upTimeInMsec` is a number of milliseconds rather than a
string to parse. The same question on every router, through Netmiko, parsed with `json.loads`:

```schooling-example
{
  "language": "python",
  "file": "neighbours.py",
  "parts": [
    {
      "code": "import json\n\nfrom netmiko import ConnectHandler\n\nROUTERS = [\"core1\", \"edge1\", \"edge2\"]\n\nfor name in ROUTERS:\n    router = ConnectHandler(device_type=\"cisco_ios\", host=name, username=\"netops\",\n                            use_keys=True, key_file=\"/home/ana/.ssh/id_ed25519\")"
    },
    {
      "code": "    data = json.loads(router.send_command(\"show ip ospf neighbor json\"))\n    router.disconnect()\n    for neighbour, entries in data[\"neighbors\"].items():\n        for n in entries:\n            print(f\"{name:6} sees {neighbour:15} on {n['ifaceName']:18} state {n['nbrState']}\")",
      "note": "**Ask the router for JSON instead of a screen.** FRR answers most `show` commands in JSON when the command ends in `json`, and then the output is data with named fields rather than columns to cut out."
    }
  ]
}
```

```
ana@ctl:~$ python neighbours.py
core1  sees 203.0.113.252   on eth1:198.51.100.1  state Full/-
core1  sees 203.0.113.253   on eth2:198.51.100.5  state Full/-
edge1  sees 203.0.113.251   on eth1:198.51.100.2  state Full/-
edge2  sees 203.0.113.251   on eth1:198.51.100.6  state Full/-
```

Four adjacencies, two on `core1` and one on each edge, all `Full`. **No text was cut**, and nothing
here breaks if FRR adds a field to its JSON.

Where a device has no structured output, the usual tool is **TextFSM** with the community's
**ntc-templates**: a template per command and platform that turns the screen into a list of
dictionaries, and Netmiko runs it with `use_textfsm=True`. It is screen-scraping done carefully and
shared, and it is still screen-scraping: the template is only right for the output it was written
against. **Prefer the device's own JSON or XML where it exists**, then an API, and a template last.
