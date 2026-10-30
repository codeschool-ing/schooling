---
title: Four services on two axes
version: 1
---

**Azure has four services that stand in front of your machines and share traffic out among them,
and the usual mistake is to see four brands of one thing and pick the cheapest.** They are four
answers to two separate questions, and each question has two answers:

- **How much of the traffic does it read?** A layer 4 service reads addresses and ports and passes
  everything else through untouched. A layer 7 service reads every HTTP request, its host name,
  its path and its headers, and decides per request.
- **Where does it stand?** A regional service lives in one region, in front of machines in that
  region. A global one stands in front of several regions at once and decides which region a user
  reaches.

Two questions with two answers each give four boxes, and each box has exactly one service in it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l22-quadrant\" aria-label=\"A two by two grid. Columns: layer 4, which reads addresses and ports, and layer 7, which reads HTTP requests. Rows: regional and global. Regional and layer 4 is Azure Load Balancer. Regional and layer 7 is Application Gateway. Global and layer 4 is Traffic Manager, which answers in DNS and carries no traffic. Global and layer 7 is Front Door, a proxy at Microsoft's edge locations.\"><text x=\"320.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">layer 4: addresses and ports</text><text x=\"565.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">layer 7: HTTP requests</text><text x=\"105.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">regional</text><text x=\"105.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">global</text><rect x=\"200.0\" y=\"50.0\" width=\"240.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Load Balancer</text><text x=\"320.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">spreads TCP and UDP flows</text><text x=\"320.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the caller's address arrives</text><rect x=\"445.0\" y=\"50.0\" width=\"240.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Application Gateway</text><text x=\"565.0\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a reverse proxy in your network</text><text x=\"565.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">routes by host and path</text><rect x=\"200.0\" y=\"180.0\" width=\"240.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Traffic Manager</text><text x=\"320.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">answers in DNS</text><text x=\"320.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no packet passes through it</text><rect x=\"445.0\" y=\"180.0\" width=\"240.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Front Door</text><text x=\"565.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a proxy at the edge</text><text x=\"565.0\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cache and WAF before any region</text></svg>", "caption": "Two questions with two answers each, and one service in every box."}
```

## Load Balancer, regional and layer 4

Azure Load Balancer spreads TCP and UDP connections across the machines in a **backend pool**. It
reads the five things that identify a flow, the two addresses, the two ports and the protocol, and
hashes them to pick a machine, so every packet of one connection reaches the same machine. It never
opens the connection and never sees a URL; to the machines behind it, the caller's own address
arrives as the source. A **health probe** asks each machine at intervals whether it is fit, and a
machine that stops answering stops receiving new flows.

It comes in two forms that share a name: a **public** load balancer has a public address as its
front end, and an **internal** one has a private address from a subnet, in front of machines other
machines call. The shop uses both: a public one for customers, and an internal one in front of the
application tier, which only the web tier calls. **The Basic SKU was retired on 30 September 2025**,
so every load balancer you create today is Standard, and the next section builds one.

## Application Gateway, regional and layer 7

Application Gateway is a **reverse proxy**: it ends the client's HTTPS connection, reads the
request, and opens a connection of its own to a backend it chooses. Because it reads the request it
can do what Load Balancer cannot: send `/api/` to one pool and everything else to another, host
several sites on one address, rewrite headers, and keep a user on one machine with a cookie. With
the WAF SKU it also inspects the request for common attacks, which is a web application firewall
and lives in the `azure-operations` course.

Three facts decide how it fits into a network:

- **It needs a subnet of its own**, which may hold nothing else. The shop gives it
  `snet-agw`, `10.20.5.0/24`, in `vnet-shop-prod`;
- **the backends see the gateway's address, not the customer's**, since the gateway opened the
  connection. The customer's address travels in the `X-Forwarded-For` header instead;
- **only the v2 SKUs exist now**, Standard_v2 and WAF_v2, which scale on their own and can span
  zones. The v1 SKUs were retired on 28 April 2026.

## Traffic Manager, global and answering in DNS

Traffic Manager is the odd one out: **no packet of yours ever passes through it.** It is a DNS
service. A name such as `shop.example` is a CNAME to a Traffic Manager name in `trafficmanager.net`.
When a user's resolver asks for it, Traffic Manager answers with the address of one of your
endpoints, chosen by the **routing method** of the profile: by priority, by weight, by the lowest
latency from the user, by the user's country, or by the user's address range. After that the user
talks straight to the endpoint.

That design has a price: a decision made in DNS lasts as long as the answer is cached. When an
endpoint fails, Traffic Manager stops naming it, and users holding the old answer keep trying the
failed address until their copy expires. A short TTL shortens that wait and multiplies the queries,
which Traffic Manager bills by the million.

## Front Door, global and layer 7

Front Door is the global version of the reverse proxy. A user's connection ends at the nearest of
Microsoft's **edge locations**, of which there are more than a hundred, and Front Door carries the
request across Microsoft's own network to the region that should answer it. On the way it can
cache what is cacheable, the way a content delivery network does, and apply WAF rules at the edge,
before an attack reaches any region at all.

It is sold in two tiers, Standard and Premium, with Premium adding the managed rule sets of the
WAF and private connections to the origins through Private Link, which is lesson 19's subject. A
third, **classic**, is the earlier product, and Microsoft is retiring it: build nothing new on it.

The last section of this lesson asks the public DNS about two of Microsoft's own names, and finds
both Traffic Manager and Front Door in the answers.
