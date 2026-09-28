---
title: "Network ACLs: a stateless filter at the subnet"
version: 1
---

The second filter sits at the edge of the subnet rather than on the machine. A **network ACL**,
access control list, is attached to a subnet and applies to every packet that crosses into or out
of it. It looks like a security group with the numbers filled in differently, and the differences
are exactly the ones that catch people.

**It is stateless.** A network ACL remembers nothing. A reply is just another packet, judged by the
rules on its own, so if requests are allowed in and replies are not allowed out, the connection
fails.

**Its rules are numbered and evaluated in order.** The lowest number is checked first, and the first
rule that matches decides; the rest are not read. The list ends with a rule written `*` that denies
whatever reached it.

**It can deny.** Each rule says allow or deny, so a network ACL can do the one thing a security group
cannot: refuse a specific range, subnet-wide, whatever the groups inside say.

## The return traffic has to be written in

A client opening a connection to your web server on 443 sends from an **ephemeral port**, a
temporary port its own system picked, somewhere high. The reply goes back to that port. A security
group lets the reply out because it remembers the request; a network ACL has to be told, with an
outbound rule that allows the whole range a client could have picked. The usual rule covers TCP
ports 1024 to 65535.

The rules for a public subnet serving HTTPS, with one range refused:

| inbound rule | protocol | ports | source | action |
|---|---|---|---|---|
| 90 | all | all | `198.51.100.0/24` | deny |
| 100 | TCP | 443 | `0.0.0.0/0` | allow |
| `*` | all | all | `0.0.0.0/0` | deny |

| outbound rule | protocol | ports | destination | action |
|---|---|---|---|---|
| 100 | TCP | 1024–65535 | `0.0.0.0/0` | allow |
| `*` | all | all | `0.0.0.0/0` | deny |

Rule 90 comes before rule 100, so a request from `198.51.100.7` to port 443 is denied before the
allow is ever read. Swap the numbers and the deny would never be reached. The outbound rule is the
return path: without it every request gets in and no reply gets out, and from outside that looks
exactly like a dead server. The same applies the other way round: if the instances in this subnet
make requests of their own, the replies come in to *their* ephemeral ports and need an inbound rule
for 1024 to 65535.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"A client, from port 51724, sends a request to a web server on port 443 inside a subnet. On the way in, the network ACL at the subnet edge checks it against inbound rule 100, which allows 443, and the security group allows 443. The reply goes back to port 51724: the security group lets it out because it remembers the request, but the network ACL judges it again and needs an outbound rule allowing ports 1024 to 65535.\"><defs><marker id=\"fw-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"200\" y=\"20\" width=\"500\" height=\"244\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"216\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">subnet: its network ACL judges every packet that crosses this edge</text><rect x=\"20\" y=\"102\" width=\"120\" height=\"84\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">client</text><text x=\"80\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">from port</text><text x=\"80\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">51724</text><rect x=\"470\" y=\"70\" width=\"210\" height=\"170\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"484\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">security group</text><text x=\"484\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">allows 443 in</text><rect x=\"515\" y=\"116\" width=\"120\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"575\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">web server</text><text x=\"484\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">lets the reply out:</text><text x=\"484\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">it remembers the request</text><text x=\"216\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">the request</text><text x=\"216\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">51724 -&gt; 443</text><text x=\"216\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">network ACL, inbound: rule 100 allows 443</text><path d=\"M140 130 L470 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fw-ah)\"></path><path d=\"M470 130 L515 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fw-ah)\"></path><path d=\"M515 158 L470 158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M470 158 L140 158\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fw-ah)\"></path><text x=\"216\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">network ACL, outbound: remembers nothing,</text><text x=\"216\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">needs a rule for 1024-65535</text><text x=\"216\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">the reply</text><text x=\"216\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">443 -&gt; 51724</text></svg>", "caption": "The same connection through both filters. The security group checks the request once and lets its reply out; the network ACL checks both packets on their own, so the reply needs its own rule."}
```

## Side by side

| | security group | network ACL |
|---|---|---|
| attached to | an instance's network interface | a subnet |
| memory | stateful: replies are allowed automatically | stateless: replies need their own rule |
| rules | allow only | allow and deny |
| order | every rule is considered; any allow lets it in | numbered, lowest first; the first match decides |
| source | an address range or another security group | an address range only |
| new one on AWS | nothing in, everything out | the VPC's default ACL: everything in and out |

## When you reach for one

The default network ACL that AWS gives every VPC allows everything in both directions, and **most
designs leave it that way** and do their filtering with security groups. The reasons are all in
the table: groups follow the instance, remember connections, and can name each other, while an ACL
needs the ephemeral range spelled out in both directions and knows only addresses.

A network ACL earns its place in two situations. The first is a subnet-wide deny: an address range
that is attacking you, refused for every machine in the subnet with one rule, which no set of allow
rules can express. The second is a guard rail: the database subnets' ACL admits only the
application subnets' ranges, so a security group opened too wide by mistake still does not expose
the database to the rest of the VPC. Both are a second line, behind the groups, and neither replaces
them.
