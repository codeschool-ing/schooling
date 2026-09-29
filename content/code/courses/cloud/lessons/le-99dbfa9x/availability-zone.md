---
title: Availability zones
version: 1
---

The common picture is one big building per region, or one building per zone and nothing more to it.
AWS's own definition is more careful: **an availability zone is one or more discrete datacentres
with redundant power, networking and connectivity**, inside a region. `sa-east-1` has three of them,
named `sa-east-1a`, `sa-east-1b` and `sa-east-1c`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A region, sa-east-1, drawn as a dashed boundary holding three availability zones, sa-east-1a, sa-east-1b and sa-east-1c. Each zone is one or more datacentres with its own power, its own cooling and its own network. The three zones are joined to each other by low-latency links, and AWS documents them as many kilometres apart and within 100 km of each other.\"><defs><marker id=\"rgz-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"262\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"36\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">sa-east-1</text><text x=\"118\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a region: a geographic area, São Paulo</text><rect x=\"44\" y=\"70\" width=\"176\" height=\"132\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">sa-east-1a</text><text x=\"56\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one or more datacentres</text><text x=\"56\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">its own power</text><text x=\"56\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">its own cooling</text><text x=\"56\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">its own network</text><rect x=\"272\" y=\"70\" width=\"176\" height=\"132\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"284\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">sa-east-1b</text><text x=\"284\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one or more datacentres</text><text x=\"284\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">its own power</text><text x=\"284\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">its own cooling</text><text x=\"284\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">its own network</text><rect x=\"500\" y=\"70\" width=\"176\" height=\"132\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">sa-east-1c</text><text x=\"512\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one or more datacentres</text><text x=\"512\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">its own power</text><text x=\"512\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">its own cooling</text><text x=\"512\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">its own network</text><path d=\"M132 202 L132 232 L588 232 L588 202\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M360 202 L360 232\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"360\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">low-latency links between zones: many km apart, within 100 km</text></svg>", "caption": "One region, three zones. A fault inside one box, a flood or a failed power feed, stays inside that box; the region carries on in the other two."}
```

The point of a zone is **isolation**. Each one has its own power feeds, its own cooling and its own
network equipment, so that the ordinary disasters of a building stay inside it. A failed power feed,
a cooling plant that stops, a flood in a basement, a bad change to one set of switches: each of those
is meant to stop at the zone's boundary.
AWS documents its zones as separated by a meaningful distance, many kilometres, and all within 100 km of each other.
That distance is the compromise the whole design rests on: far enough apart that one local event does
not reach two of them, close enough that the round trip between them stays short.

**Close enough matters, because the zones are meant to be used together.** They are joined by
dedicated links with high bandwidth and low latency, so that an application can run in two zones at
once and a database can keep a copy in a second zone while it commits. A hundred kilometres of fibre,
there and back, is 200 km, and at the 200 km per millisecond this lesson works out two sections on,
that is a floor of 1 ms. A zone pair is cheap to talk across in time. It is not free in money, and the
section on surviving a zone failure puts a price on it.

## Your "a" is not my "a"

**A zone name is a label in your account, not an address of a building.** AWS maps the names to
physical zones independently for each account. The documented reason is load: if every account's
`sa-east-1a` were the same building, most people would pick "a" out of habit, and that one zone would
fill up while the others stood half empty. So `sa-east-1a` in your account and `sa-east-1a` in a
colleague's account may be different buildings.

The stable name is the **zone ID**, which looks like `sae1-az1` and means the same physical zone in
every account. Listing the names with their IDs is one call to the EC2 API, and it is not run here:
there is no account in this course.

Most of the time the mapping is invisible, because everything you build is in one account and your
own names are consistent with each other. It matters the day two accounts have to agree on a zone.
Suppose your team runs the application in one account and the database team runs the database in
another, and both teams put their part "in `sa-east-1a`" to keep the traffic inside one zone. The
names match. The buildings may not, and if they do not, every query crosses zones and is billed at the
between-zones rate, while both teams are sure it does not. **Compare zone IDs, never zone names**,
whenever more than one account is involved.

## What a zone does not protect you from

A zone protects against a failure that is local to a building. It does nothing for a mistake that is
not local. A bad deployment that you push to both zones breaks both zones. A region-wide problem in
the provider's own software, the kind the last section of this lesson is about, reaches every zone in
that region, because the zones share the region's control systems. Two zones are a defence against
the ground under one building, and only that.

Azure and Google Cloud have zones too, under their own names: Azure numbers them 1, 2 and 3 within a
region, and Google names them after the region with a letter, such as `southamerica-east1-a`. The
shape is the same everywhere: a region is the unit you choose for law, latency and price, and a zone
is the unit you spread across for failure.
