---
title: Organisation, folders, projects and resources
version: 1
---

**Everything in Google Cloud sits somewhere in one tree, and where it sits decides who may touch it
and what it may do.** A virtual machine, a Pub/Sub topic, a bucket: each belongs to exactly one
**project**. A project belongs to a **folder** or directly to the **organisation**, and folders nest
inside each other up to ten levels deep. The organisation is the root, and there is one per company.

The wrong picture people bring from elsewhere is that the project is a folder in the filing-cabinet
sense, a place to group things for tidiness. **A project is a boundary.** It has its own APIs switched
on or off, its own quotas, its own link to a billing account, its own IAM policy, and a name in every
resource's address. Two projects share nothing unless somebody connects them on purpose, which is
what lesson 18 is about. The folders above it are where the tidiness lives, and where rules
are written once for many projects.

| level | what it is | how many |
|---|---|---|
| organisation | the company, tied to one domain such as `example.com` | one per Cloud Identity or Workspace account |
| folder | a group of projects, or of other folders | as many as the company needs, up to ten deep |
| project | the boundary every resource lives in | hundreds in a company of any size |
| resource | the thing itself: a topic, a network, a machine | as many as the quotas allow |

## What travels down the tree

Two things are written high in the tree and **inherited by everything below**:

- **IAM allow policies.** A role granted on a folder is held on every project inside it, and on every
  resource inside those. Lesson 7 says how the grants from different levels combine, and why the
  answer is a union: a grant higher up cannot be taken away lower down.
- **Organisation policies**, the guardrails of lesson 4: which regions resources may be created in,
  whether service account keys may exist at all.

Billing does **not** travel down the tree. Every project has its own link to a billing account,
lesson 11's subject, and two projects in the same folder may be paid for by different accounts.

## The estate this course builds

The company in this course is a small team that runs a planning application, **planner**, for its
customers. Its estate has the shape most companies of its size end up with:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l02-estate\" aria-label=\"The estate of the company in this course, as a tree. At the top, the organisation example.com. Below it, three folders: production, non-production and shared. Under production, the project planner-prod. Under non-production, planner-staging and planner-dev, the project the lab uses, which is highlighted. Under shared, planner-network and planner-logs. Under planner-dev, two resources: the topic orders and a network. An arrow down the left side says that IAM allow policies and organisation policies are inherited downwards; a note says that billing is linked per project and is not inherited.\"><defs><marker id=\"l02-estate-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"290.0\" y=\"18.0\" width=\"220.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"400.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">organisation</text><text x=\"400.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">example.com</text><path d=\"M400.0 58.0 L150.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"80.0\" y=\"92.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"150.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">production</text><path d=\"M400.0 58.0 L400.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"330.0\" y=\"92.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"400.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">non-production</text><path d=\"M400.0 58.0 L630.0 92.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"560.0\" y=\"92.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"630.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shared</text><path d=\"M150.0 128.0 L150.0 168.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"100.0\" y=\"168.0\" width=\"100.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planner-prod</text><path d=\"M400.0 128.0 L335.0 168.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"276.0\" y=\"168.0\" width=\"118.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"335.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">planner-staging</text><path d=\"M400.0 128.0 L475.0 168.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"425.0\" y=\"168.0\" width=\"100.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\"></rect><text x=\"475.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planner-dev</text><path d=\"M630.0 128.0 L585.0 168.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"526.0\" y=\"168.0\" width=\"118.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">planner-network</text><path d=\"M630.0 128.0 L680.0 168.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"639.0\" y=\"168.0\" width=\"82.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"680.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">planner-logs</text><text x=\"475.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">the lab</text><path d=\"M475.0 204.0 L430.0 248.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"378.0\" y=\"248.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">topics/orders</text><path d=\"M475.0 204.0 L540.0 248.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"488.0\" y=\"248.0\" width=\"104.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"263.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">networks/planner</text><text x=\"485.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resources</text><path d=\"M30.0 40.0 L30.0 290.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#l02-estate-af-ah-amber)\"></path><text x=\"42.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">inherited downwards:</text><text x=\"42.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">IAM allow policies</text><text x=\"42.0\" y=\"252.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">organisation policies</text><text x=\"42.0\" y=\"290.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">billing: per project, not inherited</text></svg>", "caption": "One tree per company. Rules go in at the folders and flow down to every project."}
```

Production lives in a folder of its own, because a folder is where the stricter rules go: fewer
people with roles, tighter policies. Staging and development share a folder with looser rules. The
projects that serve everybody, the shared network of lesson 18 and the logs, live in a third. The
project you have used since lesson 1, `planner-dev`, is the highlighted leaf.

## No organisation at all

A Google Cloud account opened with a personal Gmail address has **no organisation node**. Its projects
sit at the top with nothing above them, and the person who created each one is its owner. It works,
and it costs three things that a company notices late:

- there is nowhere to write a rule once for every project, so each project is configured by hand;
- the projects belong to a person, and when that person leaves, so does the only owner;
- there are no folders, so the stricter rules of production have nowhere to live.

An organisation appears when a company verifies its domain with **Cloud Identity** or **Google
Workspace**, the subject of lesson 10. Projects created without one can be moved under it later. Nothing
in this section was run: no emulator answers the resource hierarchy, and the next two sections show
what the lab can say about it instead.
