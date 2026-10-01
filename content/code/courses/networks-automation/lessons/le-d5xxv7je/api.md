---
title: The REST API
version: 1
---

Every object in NetBox's web interface is also a URL under `/api/`. The routers are devices,
filtered by role:

```
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat ~/.netbox-token)" "https://netbox/api/dcim/devices/?role=router&brief=1" | jq
{
  "count": 3,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "url": "https://netbox/api/dcim/devices/1/",
      "display": "core1",
      "name": "core1",
      "description": ""
    },
    {
      "id": 2,
      "url": "https://netbox/api/dcim/devices/2/",
      "display": "edge1",
      "name": "edge1",
      "description": ""
    },
    {
      "id": 3,
      "url": "https://netbox/api/dcim/devices/3/",
      "display": "edge2",
      "name": "edge2",
      "description": ""
    }
  ]
}
```

The shape is the same on every list endpoint: **`count`, `next`, `previous` and `results`**, which
is lesson 2's pagination by offset. `next` is null because three devices fit in one page; with three
thousand, `next` would be the URL of the following page. `?brief=1` asks for the short form of
each object, its id, name and URL, instead of every field.

The token goes in the `Authorization` header, as lesson 2's did, and `--cacert` names the lab's
certificate authority, because NetBox is reached over HTTPS and its certificate is checked. The
token belongs to the user `ana` and can write; a read-only token would do for everything in this
section and the next, and that is what a script that only reads should be given.

Filters are query parameters, and most of them follow the relationships. The addresses that belong
to edge1 are the addresses assigned to an interface of the device called `edge1`:

```
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat ~/.netbox-token)" "https://netbox/api/ipam/ip-addresses/?device=edge1" | jq -r ".results[] | [.assigned_object.name, .address] | @tsv"
eth0	192.0.2.12/24
eth1	198.51.100.2/30
eth2	203.0.113.1/26
lo	203.0.113.252/32
```

`jq` turned the JSON into two columns. Everything lesson 10 needed for edge1, the interfaces and
their addresses, is already in NetBox; one thing is not, and section 05 finds out which.
