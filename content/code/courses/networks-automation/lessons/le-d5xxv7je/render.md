---
title: Configurations rendered from NetBox
version: 1
---

Lesson 10's template is unchanged. What changes is where its dictionary comes from:

```schooling-example
{
  "language": "python",
  "file": "render_nb.py",
  "parts": [
    {
      "code": "import ipaddress\nimport pathlib\n\nfrom jinja2 import Environment, FileSystemLoader, StrictUndefined\n\nfrom nb import connect\n\n\ndef network(address):\n    return str(ipaddress.ip_interface(address).network)\n\n\nenv = Environment(loader=FileSystemLoader(\"templates\"), trim_blocks=True, lstrip_blocks=True,\n                  keep_trailing_newline=True, undefined=StrictUndefined)\nenv.filters[\"network\"] = network\ntemplate = env.get_template(\"frr.j2\")\nnb = connect()\npathlib.Path(\"configs\").mkdir(exist_ok=True)\n\nfor device in nb.dcim.devices.filter(role=\"router\"):\n    addresses = {ip.assigned_object.name: ip.address for ip in nb.ipam.ip_addresses.filter(device_id=device.id)}"
    },
    {
      "code": "    data = {\n        \"hostname\": device.name,\n        \"loopback\": addresses[\"lo\"].split(\"/\")[0],\n        \"interfaces\": [\n            {\"name\": i.name, \"description\": i.description, \"address\": addresses[i.name],\n             \"ospf\": i.custom_fields[\"ospf\"]}\n            for i in nb.dcim.interfaces.filter(device_id=device.id, mgmt_only=False)\n            if i.name != \"lo\"\n        ],\n    }\n    text = template.render(data)\n    pathlib.Path(f\"configs/{device.name}.conf\").write_text(text)\n    print(f\"NetBox -> configs/{device.name}.conf, {len(text.splitlines())} lines\")",
      "note": "**The same dictionary lesson 10 read from YAML**, built from NetBox: the name, the loopback without its `/32`, and every interface that is not for management, with its description, address and OSPF role."
    }
  ]
}
```

```
ana@ctl:~$ cd sot && python render_nb.py
NetBox -> configs/core1.conf, 34 lines
NetBox -> configs/edge1.conf, 34 lines
NetBox -> configs/edge2.conf, 34 lines
ana@ctl:~$ cd sot && for h in core1 edge1 edge2; do ssh netops@$h "show running-config" | tail -n +5 | diff -q - configs/$h.conf > /dev/null && echo "$h: same"; done
core1: same
edge1: same
edge2: same
```

**Three routers, configurations rendered from NetBox, identical to what is running.** That is the
check to make on the day the source of truth changes, and it is the same comparison lesson 10 made
with YAML. Anything NetBox held differently from the routers, an address typed into the wrong
interface or a description with a trailing space, would have shown up here as a router that was
not `same`, before anything was pushed.

Two filters in the script carry decisions. `mgmt_only=False` leaves out `eth0`, which the template
does not configure; the management network is set up when a router is installed, not by the
template. And `i.name != "lo"` leaves out the loopback, which the template writes on its own from
`loopback`. Both rules are visible in one place, which is the reason to write them in the script
rather than to remember them.

The data files from lesson 10 can now be deleted. Keeping them would be keeping two sources of
truth, and the second one is always the one that is out of date.
