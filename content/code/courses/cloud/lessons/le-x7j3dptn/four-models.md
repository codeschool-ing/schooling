---
title: Four deployment models, one question each
version: 1
---

Lesson 1 defined a cloud by what it does: self-service, access over the network, pooled resources,
elasticity and metering. None of those five says **where the hardware stands or who else uses it**.
The same NIST document, SP 800-145, answers that separately, with four *deployment models*: public,
private, community and hybrid.

The common picture is that the words describe a location. Public is out on the internet, private is
in your own building. That is not how the definitions are written. Location is allowed to vary in
three of the four; what each model fixes first is **who the infrastructure is provisioned for**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"The four deployment models of NIST SP 800-145, arranged by who may run workloads on the same hardware, from one organisation to anyone. Private: for one organisation, on its premises or off them, run by it or by a contractor. Community: for a group of organisations with shared concerns, such as a mission or a law, on or off premises. Public: for anyone who signs up, on the provider's premises, run by the provider. Below all three, hybrid: two or more of them, still separate, bound together so that data and applications can move between them.\"><defs><marker id=\"dm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"360\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">who may run workloads on the same hardware</text><text x=\"20\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fewer</text><text x=\"700\" y=\"38\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">more</text><path d=\"M70 38 L650 38\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dm-ah)\"></path><rect x=\"20\" y=\"56\" width=\"200\" height=\"116\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\" font-weight=\"600\">Private</text><text x=\"34\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">for one organisation</text><text x=\"34\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">on its premises or off them</text><text x=\"34\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">run by it or by a contractor</text><rect x=\"260\" y=\"56\" width=\"200\" height=\"116\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"274\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\" font-weight=\"600\">Community</text><text x=\"274\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">for a group with shared</text><text x=\"274\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">concerns: a mission, a law</text><text x=\"274\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">on or off premises</text><rect x=\"500\" y=\"56\" width=\"200\" height=\"116\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"514\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\" font-weight=\"600\">Public</text><text x=\"514\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">for anyone who signs up</text><text x=\"514\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">on the provider's premises</text><text x=\"514\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">run by the provider</text><path d=\"M120 174 L120 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#dm-ah)\"></path><path d=\"M360 174 L360 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#dm-ah)\"></path><path d=\"M600 174 L600 198\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#dm-ah)\"></path><rect x=\"20\" y=\"200\" width=\"680\" height=\"66\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"34\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">Hybrid</text><text x=\"34\" y=\"237\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">two or more of the three, each still its own cloud, joined so that</text><text x=\"34\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">data and applications can move between them or span them</text></svg>", "caption": "NIST's four models answer one question first: who else may run on the hardware. Where it stands and who operates it follow from that, loosely for the first two and fixed for public. Hybrid is not a fourth kind of hardware; it is a join between the others."}
```

Put side by side, in NIST's terms and in plain words:

| model | provisioned for | where it may stand | who may operate it |
|---|---|---|---|
| private | one organisation, which may hold many consumers, such as its business units | on its premises or off them | the organisation, a third party, or both |
| community | a group of organisations with shared concerns: a mission, security requirements, a policy, compliance | on or off premises | one or more of the members, a third party, or a mix |
| public | open use by the general public | on the provider's premises | a company, a university, a government body, or a mix |
| hybrid | two or more of the above, still distinct, bound by technology that lets data and applications move between them | wherever its parts stand | whoever operates each part |

Read the table by column and two things fall out of it.

First, **a private cloud can sit in somebody else's building**. A company that rents a room of
dedicated servers in a colocation facility and runs a cloud stack on them has a private cloud off
its premises: the building is shared, and the hardware is not. "Private" is about tenancy, not
about the address on the gate.

Second, **hybrid is not a fourth kind of hardware**. There is no hybrid server to buy. The word
names a composition: two clouds that stay separate and are joined so that a workload can move from
one to the other, or run across both. NIST's own example is *cloud bursting*: the private side
carries the load until it is full, and the overflow goes to the public side.

Strictly, NIST's hybrid joins two clouds. In practice the word is used more loosely, and an
ordinary datacentre joined to a public region is called hybrid by nearly everybody, the providers
included. This lesson follows common usage. The difference matters in one place, which is why the
section on private cloud asks what a datacentre needs before it counts as a cloud at all.

## Two axes, not one list

The deployment model and lesson 1's service model are **independent questions**. IaaS, PaaS and
SaaS say how much of the stack the provider runs for you; public, private and community say who
shares the hardware underneath. OpenStack run inside a bank gives the bank's teams IaaS on a
private cloud. A webmail service sold to anybody with a card is SaaS on a public one. Any pairing
is possible, and a sentence that uses only one of the two words has left half the description out.

## The question behind each name

Compressed to one question, each model answers **who else runs on the same hardware**:

- nobody outside the organisation: private;
- organisations that share your rules and concerns: community;
- anybody who signs up and pays: public.

Hybrid moves the question from the hardware to the join. What has to cross between the two sides,
what it costs to cross, and what breaks when the link does. Most of the rest of this lesson is
about that join, because it is where the surprises are.
