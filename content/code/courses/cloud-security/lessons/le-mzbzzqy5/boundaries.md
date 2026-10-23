---
title: Boundaries, and what flows down them
version: 1
---

**The three providers sell the same kinds of building block, and the `cloud` course's lessons 3 and 7
already translated their names. What a defender needs on top is where each one draws its
boundaries, and what flows down from one level to the next: that decides how far one grant or one
guardrail reaches.** Nothing in this lesson was run except the last
section's AWS half: there is no Azure and no Google Cloud in this lab, and every claim about them
comes from their documentation.

The wrong picture is that the translation table is the whole story: an account is a subscription is
a project, a policy is a role assignment is a binding, and a control written once translates word
for word. The words translate. **The reach does not.**

## The unit of isolation

Each provider has a container that holds resources, carries a bill, and is the usual line between
one team or one environment and the next:

| | AWS | Azure | Google Cloud |
|---|---|---|---|
| the container | an **account** | a **subscription**, holding **resource groups** | a **project** |
| containers grouped by | organisational units (OUs) in an organisation | management groups in a tenant | folders in an organisation |
| where identities live | in each account (IAM), or centrally in IAM Identity Center | in the tenant's **Microsoft Entra ID**, shared by every subscription | in Cloud Identity or Google Workspace, shared by every project |
| a guardrail on a whole branch | service control policies (SCPs) and resource control policies | **Azure Policy** assignments with a `Deny` effect | **Organization Policy** constraints |

Read the third row twice. An AWS account keeps its own IAM users and roles, and reaching into another
account takes a grant on both sides. **An Azure subscription and a Google Cloud project hold no
identities of their own**: the people and programs belong to the tenant or the organisation, and a
subscription or project is a place where they are given roles. That is not a weakness; it is a
different shape, and it means the question "who can touch this project" starts with a directory that
serves every other project too.

## What flows down

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 375\" role=\"img\" data-fig=\"l05-hierarchy\" aria-label=\"The three hierarchies side by side, top to bottom. AWS: an organisation, organisational units, accounts, resources; the management account sits apart at the top. Azure: a tenant with its root management group, management groups, subscriptions, resource groups, resources. Google Cloud: an organisation, folders, projects, resources. Guardrails flow down at all three: SCPs, Azure Policy and Organization Policy. Grants flow down at Azure and Google Cloud, where a role given high up reaches everything below it. At AWS an identity policy stays inside its own account, and an SCP never applies to the management account.\"><defs><marker id=\"l05-hierarchy-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l05-hierarchy-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"120.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">AWS</text><rect x=\"50.0\" y=\"48.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"135.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">organisation</text><rect x=\"60.0\" y=\"94.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">OU</text><rect x=\"70.0\" y=\"140.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">account</text><rect x=\"80.0\" y=\"186.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">resource</text><path d=\"M32.0 52.0 L32.0 220.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l05-hierarchy-af-ah-amber)\"></path><text x=\"24.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">SCPs</text><text x=\"24.0\" y=\"254.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">flow down</text><path d=\"M42.0 144.0 L42.0 220.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l05-hierarchy-af-ah-phosphor)\"></path><text x=\"24.0\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">grants stay in the account</text><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Azure</text><rect x=\"290.0\" y=\"48.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tenant, root group</text><rect x=\"300.0\" y=\"94.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">management group</text><rect x=\"310.0\" y=\"140.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">subscription</text><rect x=\"320.0\" y=\"186.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">resource group</text><rect x=\"330.0\" y=\"232.0\" width=\"130.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"395.0\" y=\"249.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">resource</text><path d=\"M272.0 52.0 L272.0 266.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l05-hierarchy-af-ah-amber)\"></path><text x=\"264.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">Azure Policy</text><text x=\"264.0\" y=\"300.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">flow down</text><path d=\"M282.0 52.0 L282.0 266.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l05-hierarchy-af-ah-phosphor)\"></path><text x=\"264.0\" y=\"318.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">role assignments flow down</text><text x=\"600.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Google Cloud</text><rect x=\"530.0\" y=\"48.0\" width=\"170.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">organisation</text><rect x=\"540.0\" y=\"94.0\" width=\"160.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">folder</text><rect x=\"550.0\" y=\"140.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">project</text><rect x=\"560.0\" y=\"186.0\" width=\"140.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">resource</text><path d=\"M512.0 52.0 L512.0 220.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l05-hierarchy-af-ah-amber)\"></path><text x=\"504.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">Organization Policy</text><text x=\"504.0\" y=\"254.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">flow down</text><path d=\"M522.0 52.0 L522.0 220.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l05-hierarchy-af-ah-phosphor)\"></path><text x=\"504.0\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">allow policies flow down</text><rect x=\"36.0\" y=\"330.0\" width=\"180.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"126.0\" y=\"345.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">management account: no SCP</text></svg>", "caption": "Guardrails flow down at all three. Grants flow down at two of them, which is why a role given high up for convenience reaches everything below it."}
```

**At Google Cloud and Azure, a grant flows down.** A role granted on a folder applies to every project
in it and every resource in those; a role assignment on a management group applies to every
subscription below it. A grant made high up "for convenience" is a grant on everything, including the
projects created next year. So **the answer to "who can read this bucket" is collected by walking up
the hierarchy**: the bucket, its project, every folder above, the organisation.

**At AWS, grants do not flow down the organisation.** An identity policy lives in one account and
speaks for that account. What does flow down an AWS organisation is the guardrail: an SCP attached to
an OU limits every account below it, and grants nothing. One exception matters in practice:
**an SCP never applies to the organisation's management account**, so
the account that runs the organisation should hold no workloads at all.

Guardrails flow down at all three, which is what makes them guardrails: Azure Policy assigned to a
management group and an Organization Policy constraint set on a folder reach everything below, the
same way an SCP does.

## What the clinic would check

The clinic's account is a single AWS account today, and bia's reports live in one Google Cloud
project (lesson 4). The questions a defender asks are the same on both sides and are answered in
different places:

- **who can act here?** On AWS, the account's IAM, plus any role another account may assume into it.
  On Google Cloud, the project's allow policy and every folder and organisation policy above it;
- **what can never happen here, whatever anybody is granted?** On AWS, the SCPs on the account and
  its OUs. On Google Cloud, the Organization Policy constraints in force on the project;
- **who could change those answers?** Whoever holds the organisation's top: the AWS management account,
  the Google Cloud organisation administrators, Azure's root management group.
