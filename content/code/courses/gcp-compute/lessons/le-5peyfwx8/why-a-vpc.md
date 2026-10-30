---
title: Why a serverless service needs a network at all
version: 1
---

The common picture of Cloud Run is a container floating free of any network you own, and for a
service that only answers the internet that picture is right. **It stops being right the moment
the service has to reach something with a private address**: a database on a private IP, a cache,
an internal API on a virtual machine. Those live inside a VPC, and a Cloud Run instance, by
default, does not.

## Where an instance actually runs

A Cloud Run instance runs on Google's infrastructure, in the region you chose, on a network Google
manages. It can reach the internet, and through it every public Google API. What it cannot reach is
an address in `10.0.0.0/8`, `172.16.0.0/12` or `192.168.0.0/16` inside your project's VPC, because
there is no route from Google's network into yours. A connection to `10.20.0.3:5432` simply times
out, and that is the first symptom a team meets: the service deploys, answers its health check,
and hangs on its first query.

The orders service from lesson 8 is exactly that case in the shop. Its database is a PostgreSQL
instance that only has a private address, `10.20.0.3` in the subnet `shop-data`, because a database
with a public address is a database somebody will eventually find. The service needs a way into
the VPC `shop`, and only the egress side of it: requests still reach the service from outside,
while the service's own outbound connections go into the VPC.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"On the left, a Cloud Run instance on Google's managed network, with an arrow to the internet. On the right, the VPC shop with the subnet shop-run, a connector in the range 10.8.0.0/28, and the database at 10.20.0.3. Two dashed routes join the instance to the VPC: direct VPC egress into the subnet, and the connector, which forwards the traffic.\"><defs><marker id=\"l12p-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"16\" width=\"230\" height=\"268\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"28\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-weight=\"600\">Google-managed network</text><rect x=\"40\" y=\"108\" width=\"180\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">Cloud Run instance</text><text x=\"130\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">orders</text><rect x=\"40\" y=\"220\" width=\"180\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"130\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the internet, Google APIs</text><path d=\"M130 156 L130 216\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l12p-ah)\"></path><rect x=\"474\" y=\"16\" width=\"230\" height=\"268\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"486\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" font-weight=\"600\">VPC shop</text><rect x=\"490\" y=\"52\" width=\"198\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"589\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">subnet shop-run</text><text x=\"589\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.1.0/26</text><rect x=\"490\" y=\"138\" width=\"198\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"589\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">connector</text><text x=\"589\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.8.0.0/28</text><rect x=\"490\" y=\"212\" width=\"198\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"589\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">database</text><text x=\"589\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.0.3:5432</text><path d=\"M250 118 L486 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l12p-ah)\"></path><text x=\"354\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">direct VPC egress</text><path d=\"M250 140 L486 166\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l12p-ah)\"></path><text x=\"354\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">through a connector</text></svg>", "caption": "An instance has no route into the VPC until its revision is given one. Direct egress puts the instance itself in a subnet; a connector puts machines there that forward for it."}
```

## Two ways in

Google offers two, and the next two sections take one each:

- **Direct VPC egress** gives each Cloud Run instance an address in a subnet of your VPC. Traffic
  leaves the instance already inside the network. There is nothing extra to run and nothing extra
  on the bill beyond the traffic itself.
- **A Serverless VPC Access connector** is a small group of virtual machines that Google runs in
  your VPC, in a `/28` range of their own. The service sends its traffic to the connector and the
  connector forwards it. It is the older mechanism, it is billed as the machines it runs, and it
  still has uses that section 04 names.

Both are a property of the service's **revision template**, not of the service as a whole, which
matters for lesson 9: a new revision can move from a connector to direct egress, and traffic can
be split between the two while you watch.

## What the network does not change

Reaching the VPC changes where outbound traffic can go. It does not change who may call the
service, which is ingress and is section 05's subject, and it does not give the service an
identity on the database. A private address is a route, not a permission: the database still
needs a user and a password, or IAM database authentication, and the service still needs its own
service account. Lesson 15 makes the same point for pods.

None of this can be run in the lab, because there is no VPC to reach and no Cloud Run to reach
from. What can be run is the configuration, and the next sections write it and let Terraform
check it.
