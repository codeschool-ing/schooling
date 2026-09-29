---
title: Pagination
version: 1
---

A list can be longer than one answer should carry. A router's routing table can hold a million
routes; a controller can manage ten thousand devices. **So a list resource answers one page at a
time**, and says how to ask for the next:

```
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat .token)" "https://edge1.example.net/api/v1/interfaces?limit=2"
{
  "count": 4,
  "next": "https://edge1.example.net/api/v1/interfaces?limit=2&offset=2",
  "previous": null,
  "results": [
    {
      "name": "eth0",
      "description": "",
      "enabled": true,
      "oper_status": "up",
      "mtu": 1500,
      "mac_address": "52:54:00:00:02:0c",
      "addresses": [
        "192.0.2.12/24"
      ]
    },
    {
      "name": "eth1",
      "description": "uplink to core1",
      "enabled": true,
      "oper_status": "up",
      "mtu": 1500,
      "mac_address": "52:54:00:33:64:02",
      "addresses": [
        "198.51.100.2/30"
      ]
    }
  ]
}
```

`count` is the total, 4. `results` holds this page, two interfaces because the request asked for
`limit=2`. `next` is the address of the following page, and `previous` of the one before; the
first page has no previous, so it is `null`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Reading four interfaces two at a time. The client asks for limit=2 and gets eth0 and eth1, a count of 4 and a next link with offset=2. It asks for that link and gets eth2 and lo, with next set to null, which is how it knows it has everything.\"><defs><marker id=\"pg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ana&#x27;s script on ctl</text><text x=\"570\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">edge1&#x27;s API</text><path d=\"M150 38 L150 318\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M570 38 L570 318\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M152 64 L566 78\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><text x=\"360\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /interfaces?limit=2</text><path d=\"M568 104 L154 118\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><rect x=\"200\" y=\"124\" width=\"320\" height=\"58\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">page 1 of 2</text><text x=\"360.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&quot;count&quot;: 4,  results: eth0, eth1</text><text x=\"360.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&quot;next&quot;: &quot;…?limit=2&amp;offset=2&quot;</text><path d=\"M152 198 L566 212\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><text x=\"360\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">GET /interfaces?limit=2&amp;offset=2</text><path d=\"M568 238 L154 252\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pg-ah)\"></path><rect x=\"200\" y=\"258\" width=\"320\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">page 2 of 2</text><text x=\"360.0\" y=\"291.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">results: eth2, lo   &quot;next&quot;: null</text><text x=\"20\" y=\"283\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">null: stop</text></svg>", "caption": "Two requests for four interfaces. The client follows next until it is null, and never computes an offset itself."}
```

This style is called **offset pagination**: `offset` says how many items to skip. It is what
NetBox uses in lesson 12, and many controllers do the same. Other APIs page with a **cursor**, an
opaque string the server hands back, or with a `Link` header instead of a field in the body. The
rule for the client is the same in all of them: **follow the link the server gives you, and do
not build the next address yourself.** A client that computes `offset=2` itself breaks the day
the server changes how it pages; one that follows `next` does not notice.

`Device.all` in `devapi.py` is that rule as a generator: it yields the items of a page, then
fetches `next`, until `next` is `null`. The caller sees a stream of routes and never a page:

```schooling-example
{
  "language": "python",
  "file": "routes.py",
  "parts": [
    {
      "code": "from devapi import Device\n\nedge1 = Device(\"edge1\")"
    },
    {
      "code": "for route in edge1.all(\"/routes\", limit=3):\n    hops = \", \".join(h.get(\"ip\") or h[\"interface\"] for h in route[\"next_hops\"])\n    mark = \">\" if route[\"selected\"] else \" \"\n    print(f\"{mark} {route['prefix']:<18} {route['protocol']:<10} via {hops}\")",
      "note": "**`limit=3` asks for small pages**, so the lab's handful of routes needs several. The loop does not know how many pages there were."
    }
  ]
}
```

```
ana@ctl:~$ python routes.py
  192.0.2.0/24       ospf       via 198.51.100.1
> 192.0.2.0/24       connected  via eth0
> 192.0.2.128/25     static     via 198.51.100.1
  198.51.100.0/30    ospf       via eth1
> 198.51.100.0/30    connected  via eth1
> 198.51.100.4/30    ospf       via 198.51.100.1
  203.0.113.0/26     ospf       via eth2
> 203.0.113.0/26     connected  via eth2
> 203.0.113.64/26    ospf       via 198.51.100.1
> 203.0.113.251/32   ospf       via 198.51.100.1
> 203.0.113.252/32   connected  via lo
> 203.0.113.253/32   ospf       via 198.51.100.1
```

The routing table took several pages at `limit=3`, and the script did not have to know how many.
The lines marked `>` are the routes FRR selected. The duplicate prefixes are real: `edge1` knows
`198.51.100.0/30` both as connected and from OSPF, and the connected route wins.

**The page size is the client's choice within the server's limits.** This API allows 1 to 100
and defaults to 50. A smaller page costs more requests; a larger one costs memory on both sides.
And a list that changes while it is being read can move an item across a page boundary, so a
careful program treats a paginated read as a view of one moment and not as a transaction.
