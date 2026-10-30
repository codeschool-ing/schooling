---
title: A landing zone is a subscription that starts out right
version: 1
---

**A landing zone is not a product you buy or a button in the portal. It is a subscription that
arrives already governed**: placed in the right management group, under the right policies, with a
budget, logging, a network connected to the company's, and the roles its team needs, before the team
deploys its first resource. The wrong picture is a template for a virtual machine. The right one is
the plot of land with the water, the power and the planning rules already in place.

The name comes from Microsoft's **Cloud Adoption Framework**, CAF, a large body of guidance on how an
organisation moves to Azure. Its *Ready* part is about landing zones, and it divides one into two
halves:

- **the platform landing zone**: what is built once, by a central platform team, for everybody. The
  management group tree, the policies on it, the identity setup, the hub network that connects to
  the office, the central log workspace. The shop's `shop-shared` subscription from lesson 2 is the
  seed of one;
- **workload landing zones**: one or more subscriptions per application, handed to the team that
  runs it, inside the guardrails the platform set. `shop-prod` and `shop-staging` are the shop's.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l05-platform-workload\" aria-label=\"A landing zone in two halves. At the top, the platform landing zone, built once by the platform team: the management group tree and its policies, identity, the hub network connected to the office, and central logs. Below it, two workload landing zones, the subscriptions shop-prod and shop-staging, each handed to the shop's team inside the platform's guardrails.\"><defs><marker id=\"l05-platform-workload-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"680.0\" height=\"110.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">platform landing zone: built once, for everybody</text><rect x=\"40.0\" y=\"60.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tree and policies</text><rect x=\"205.0\" y=\"60.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">identity</text><rect x=\"370.0\" y=\"60.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">hub network</text><rect x=\"535.0\" y=\"60.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">central logs</text><path d=\"M220.0 132.0 L220.0 158.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-platform-workload-af-ah-paper-dim)\"></path><rect x=\"110.0\" y=\"160.0\" width=\"220.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">workload landing zone</text><text x=\"220.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop-prod</text><path d=\"M500.0 132.0 L500.0 158.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-platform-workload-af-ah-paper-dim)\"></path><rect x=\"390.0\" y=\"160.0\" width=\"220.0\" height=\"80.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">workload landing zone</text><text x=\"500.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop-staging</text></svg>", "caption": "The platform is decided once; each workload gets a subscription that arrives inside it."}
```

## Eight things to decide, in advance

CAF lists **eight design areas**, the decisions a platform landing zone has to have answered:

| design area | the question | in this course |
|---|---|---|
| billing and Entra tenant | which tenant, and who pays | lessons 2 and 13 |
| identity and access management | who may do what, and how they prove it | lessons 6 to 12 |
| resource organisation | management groups, subscriptions, names, tags | lessons 2, 3 and 15 |
| network topology and connectivity | hub and spokes, the road to the office, DNS | lessons 16 to 23 |
| security | protections, detection, the central security tooling | lessons 10 and 11 |
| management | logs, monitoring, backups | beyond this course |
| governance | the policies that keep it all inside the lines | lesson 4 |
| platform automation and DevOps | the platform itself described in code | lessons 25 and 26 |

**That table is most of this course.** A landing zone is not a separate topic; it is the place where
all the others are decided once, together, rather than per project and differently each time.

## Subscription vending

The second idea CAF adds is how a workload gets its subscription: **subscription vending**, a
platform mechanism that issues a new subscription on request, already placed in the right
management group, with its budget, its network and its roles. A request, an approval, and a
pipeline that does the rest. **The point is that nobody creates a subscription by hand**, because a
subscription created by hand starts under the tenant root group, governed by almost nothing, until
somebody remembers to move it.

That last detail is documented and worth knowing on its own: **a new subscription is placed under
the root management group unless a default is set.** The tenant's hierarchy settings let you name a
default management group for new subscriptions, and CAF recommends one, its sandbox group, so that a
subscription created outside the process lands somewhere harmless rather than somewhere ungoverned.
None of it was run here: each step is a request to Resource Manager or to the billing service.

## Accelerators, or by hand

Microsoft publishes **accelerators** for the platform landing zone, in Bicep and in Terraform, that
deploy the CAF reference design with its policies. CAF's own advice is that most organisations start
from one rather than writing their own. This course does the opposite on purpose, for the same reason
a mechanic learns on an engine with the cover off. The next section builds the tree by hand, small
enough to read. An accelerator is then something you can recognise rather than something you
trust.
