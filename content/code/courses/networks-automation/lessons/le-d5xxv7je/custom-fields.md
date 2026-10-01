---
title: What NetBox does not have
version: 1
---

The template from lesson 10 needs four things for each interface: the name, the description, the
address and the OSPF role. NetBox has the first three. Fed from NetBox, the rendering stops
before it starts:

```
ana@ctl:~$ cd sot && python render_nb.py 2>&1 | tail -1
KeyError: 'ospf'
```

**NetBox models the network, not one network's design**, so a fact like "this link runs OSPF as
point-to-point" has nowhere to go until somebody adds it. A **custom field** does: a field defined
once, on a kind of object, that appears on every object of that kind, in the web interface and in
the API alike.

```schooling-example
{
  "language": "python",
  "file": "ospf_field.py",
  "parts": [
    {
      "code": "from nb import connect\n\nnb = connect()"
    },
    {
      "code": "choices = nb.extras.custom_field_choice_sets.create(\n    name=\"OSPF interface\", extra_choices=[[\"point-to-point\", \"point-to-point\"], [\"passive\", \"passive\"]])\nnb.extras.custom_fields.create(\n    name=\"ospf\", label=\"OSPF\", type=\"select\", object_types=[\"dcim.interface\"], choice_set=choices.id)\n\nOSPF = {(\"core1\", \"eth1\"): \"point-to-point\", (\"core1\", \"eth2\"): \"point-to-point\",\n        (\"edge1\", \"eth1\"): \"point-to-point\", (\"edge1\", \"eth2\"): \"passive\",\n        (\"edge2\", \"eth1\"): \"point-to-point\", (\"edge2\", \"eth2\"): \"passive\"}\nfor (device, name), role in OSPF.items():\n    interface = nb.dcim.interfaces.get(device=device, name=name)",
      "note": "**NetBox has no field for an interface's OSPF role, so one is added.** A choice set lists the values allowed; the custom field puts it on every interface."
    },
    {
      "code": "    interface.custom_fields[\"ospf\"] = role\n    interface.save()\n    print(f\"{device} {name}: ospf={role}\")",
      "note": "**A write is a change to the object and a save.** pynetbox sends only the fields that changed, as a PATCH."
    }
  ]
}
```

```
ana@ctl:~$ cd sot && python ospf_field.py
core1 eth1: ospf=point-to-point
core1 eth2: ospf=point-to-point
edge1 eth1: ospf=point-to-point
edge1 eth2: ospf=passive
edge2 eth1: ospf=point-to-point
edge2 eth2: ospf=passive
```

A choice set rather than free text means NetBox checks the value on the way in. The same field,
written through the API with a value that is not in the set:

```
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat ~/.netbox-token)" "https://netbox/api/dcim/interfaces/?device=edge1&name=eth2" | jq ".results[0].id"
7
ana@ctl:~$ curl -s --cacert lab-ca.pem -X PATCH -H "Authorization: Bearer $(cat ~/.netbox-token)" -H "Content-Type: application/json" -d "{\"custom_fields\": {\"ospf\": \"p2p\"}}" https://netbox/api/dcim/interfaces/7/ | jq
{
  "__all__": [
    "Invalid value for custom field 'ospf': Invalid choice (p2p) for choice set OSPF interface."
  ]
}
```

**The wrong value was refused at the source**, with a message that names the field and the choice
set. In lesson 10's YAML, `ospf: p2p` would have been accepted by everything up to the template,
where `{% if i.ospf == "point-to-point" %}` would have quietly written no OSPF line at all. A
source of truth that validates is one where that mistake cannot be made, instead of one where it is
found later.

The six values written here are the same as lesson 10's YAML. Moving data into NetBox should
change where it lives and nothing about what it says, and the next section checks exactly that.
