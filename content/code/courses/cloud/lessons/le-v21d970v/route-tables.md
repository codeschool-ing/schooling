---
title: "Public or private: the route table decides"
version: 1
---

The wrong picture is that a public subnet is a subnet with a "public" switch turned on. There is a
setting that looks like one: AWS lets a subnet hand every new instance a public address
automatically. It does not make the subnet public. **What makes a subnet public is one line in its
route table**, and a subnet without that line is private whatever its instances are given.

## Every subnet has a route table

A route table is the list you read in `networks` with `ip route`, kept by the VPC instead of by
each machine: a destination, written in CIDR, and a target to hand matching packets to. Each subnet
is associated with exactly one route table, and one table can serve several subnets. Every table
starts with a route for the VPC's own range whose target is `local`, which is how any subnet
reaches any other inside the VPC without anybody writing a rule for it.

A public subnet's table in the VPC `10.0.0.0/16`:

| destination | target |
|---|---|
| `10.0.0.0/16` | `local` |
| `0.0.0.0/0` | the internet gateway |

And a private subnet's:

| destination | target |
|---|---|
| `10.0.0.0/16` | `local` |

`0.0.0.0/0` is the CIDR block with no fixed bits at all, every IPv4 address there is: it is the
**default route**, the `default via` line of `ip route`. The **internet gateway** is the VPC's door
to the internet, one per VPC, attached to it rather than placed in a subnet.

When two routes match, the more specific wins, exactly as on a Linux machine. A packet for
`10.0.40.7` matches `0.0.0.0/0` and also `10.0.0.0/16`; sixteen fixed bits are more specific than
none, so it stays inside the VPC. **Only what matches nothing more specific goes to the internet
gateway.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A VPC, 10.0.0.0/16, holding two subnets in zone a, each with its own route table. The public subnet, 10.0.0.0/20, has a route table with 10.0.0.0/16 to local and 0.0.0.0/0 to the internet gateway, which leads to the internet. The private subnet, 10.0.32.0/20, has a route table with only the local route, so it has no way out.\"><defs><marker id=\"rt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"540\" height=\"250\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"32\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">VPC</text><text x=\"64\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.0.0.0/16</text><rect x=\"36\" y=\"62\" width=\"230\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"48\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">public subnet</text><text x=\"48\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.0.0.0/20</text><text x=\"48\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">zone a</text><path d=\"M266 108 L300 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"300\" y=\"62\" width=\"244\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"312\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">route table</text><text x=\"312\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.0.0.0/16</text><text x=\"430\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">local</text><text x=\"312\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">0.0.0.0/0</text><text x=\"430\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">internet gateway</text><rect x=\"36\" y=\"178\" width=\"230\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"48\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">private subnet</text><text x=\"48\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.0.32.0/20</text><text x=\"48\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">zone a</text><path d=\"M266 224 L300 224\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"300\" y=\"178\" width=\"244\" height=\"92\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"312\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">route table</text><text x=\"312\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.0.0.0/16</text><text x=\"430\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">local</text><text x=\"312\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">no default route: no way out</text><rect x=\"590\" y=\"106\" width=\"114\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"647\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">internet gateway</text><path d=\"M544 128 L590 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><path d=\"M647 106 L647 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rt-ah)\"></path><text x=\"647\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the internet</text></svg>", "caption": "Two subnets, one difference. Both route tables carry the local route for the whole VPC; only the public one sends 0.0.0.0/0 to the internet gateway, and that line is what makes it public."}
```

## What else "public" needs

The route is necessary and it is not enough. The internet gateway translates between an instance's
private address and a **public IPv4 address** associated with it, so an instance with no public
address has nothing to be reached at, even in a public subnet. And the filters of the next sections
still have to let the packet through.

A public IPv4 address is billed by the hour, whether or not anything uses it:

```
ana@laptop:~/cloud$ python3 prices.py ec2 | grep -E 'sa-east-1|IPv4'
                                        sa-east-1    us-east-1
  public IPv4 address, per hour            0.0050       0.0050
ana@laptop:~/cloud$ python3 -c "print(round(730 * 0.0050, 2))"
3.65
```

That is 730 hours, a month in AWS's arithmetic, at the rate on the sheet: 3.65 dollars a month for
each address, in either region. A machine that does not need to be reached directly should not
have one, which is the argument of the next two sections as well as a line on lesson 10's bill.

The reverse mistake is just as common. An instance with a public address in a subnet whose table has
no route to the internet gateway looks public on its details page and is unreachable. Its replies
have no way out, and neither do its own requests. When a machine "has a public IP and nothing
works", the route table of its subnet is one of the five places the last section of this lesson
tells you to look.

The prices here are AWS's public list for `sa-east-1` (São Paulo) and `us-east-1` (N. Virginia),
in dollars and before tax, at the offer versions `prices.py` prints; this course has no account,
and nothing here is a bill.
