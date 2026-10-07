---
title: NetBox from Python
version: 2
---

The scripts of this lesson live in `~/sot` on `ctl`. Two files come unchanged from lesson 10's
`~/tpl`, the template and `push.py`, and are copied in at the start:

```
ana@ctl:~$ mkdir -p sot/inventory && cp -r tpl/templates tpl/push.py sot/
```

`pynetbox` wraps the API in Python objects: an endpoint is an attribute, a filter is a method, a
result is an object whose fields are attributes. Every script in this lesson connects through one
small module:

```schooling-example
{
  "language": "python",
  "file": "nb.py",
  "parts": [
    {
      "code": "import pynetbox\n\n\ndef connect():"
    },
    {
      "code": "    nb = pynetbox.api(\"https://netbox\", token=open(\"/home/ana/.netbox-token\").read().strip())\n    nb.http_session.verify = \"/home/ana/lab-ca.pem\"\n    return nb",
      "note": "**One place that knows how to reach NetBox**: the address, the token from its file, and the lab's certificate authority, so that every script in this lesson verifies the server it talks to."
    }
  ]
}
```

With it, the routers and their addresses:

```schooling-example
{
  "language": "python",
  "file": "show.py",
  "parts": [
    {
      "code": "from nb import connect\n\nnb = connect()"
    },
    {
      "code": "for device in nb.dcim.devices.filter(role=\"router\"):\n    print(f\"{device.name}  site={device.site.slug}  platform={device.platform.slug}  mgmt={device.primary_ip4}\")",
      "note": "**Filters are the API's query parameters.** `filter(role=\"router\")` is `?role=router` on `/api/dcim/devices/`, and pynetbox follows the pages for you."
    },
    {
      "code": "    for ip in nb.ipam.ip_addresses.filter(device_id=device.id):\n        print(f\"    {ip.assigned_object.name:5} {ip.address}\")",
      "note": "**Objects link to objects.** An address is assigned to an interface, which belongs to a device; the filter by `device_id` walks that link from the other end."
    }
  ]
}
```

```
ana@ctl:~$ cd sot && python show.py
core1  site=core  platform=frr  mgmt=192.0.2.11/24
    eth0  192.0.2.11/24
    eth1  198.51.100.1/30
    eth2  198.51.100.5/30
    lo    203.0.113.251/32
edge1  site=branch-1  platform=frr  mgmt=192.0.2.12/24
    eth0  192.0.2.12/24
    eth1  198.51.100.2/30
    eth2  203.0.113.1/26
    lo    203.0.113.252/32
edge2  site=branch-2  platform=frr  mgmt=192.0.2.13/24
    eth0  192.0.2.13/24
    eth1  198.51.100.6/30
    eth2  203.0.113.65/26
    lo    203.0.113.253/32
```

Two things in that output are NetBox's model at work. `device.site.slug` followed a link from the
device to its site without another line of code; pynetbox fetched what was needed. And
`primary_ip4` is NetBox's answer to the question "which address do I use to reach this device",
which is the management address on `eth0`. Section 08 uses exactly that to build an inventory.

**Each loop is a request per device**, and that is worth noticing before it is three thousand
devices. NetBox's filters take lists, `device_id=[1, 2, 3]`, so the addresses of every router can
come back in one request; for the three in the lab, the simple loop is clearer.
