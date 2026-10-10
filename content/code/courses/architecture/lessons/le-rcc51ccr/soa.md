---
title: Service-oriented architecture
version: 1
---

Large companies in the late 1990s had dozens of applications that could not talk to each other: a
billing system bought in one decade, a warehouse system written in another, a customer database
nobody dared touch. Connecting them pair by pair was a mess, and **service-oriented architecture**,
SOA, was the answer that took shape in the early 2000s: expose what each application does as a
*service* with a published contract, and let any other application use it through that contract.

Those contracts were usually written in **WSDL**, an XML description of a service's operations, and
the messages travelled as **SOAP**, an XML envelope over HTTP or a message queue. `apis` lesson 5
looks at SOAP from the side of a programmer who has to integrate with one.

## The bus

The piece that defined SOA in practice was the **enterprise service bus**, the ESB: a central
product through which every message between applications passed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two drawings. On the left, five applications joined to each other directly, with ten lines between them. On the right, the same five applications each joined by one line to an enterprise service bus in the middle, which routes, transforms and orchestrates the messages.\"><rect x=\"10\" y=\"10\" width=\"340\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"370\" y=\"10\" width=\"340\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">point to point: 10 links</text><text x=\"540\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">a bus in the middle: 5 links</text><path d=\"M180 64 L261 119\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M180 64 L230 209\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M180 64 L130 209\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M180 64 L99 119\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M261 119 L230 209\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M261 119 L130 209\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M261 119 L99 119\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M230 209 L130 209\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M230 209 L99 119\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><path d=\"M130 209 L99 119\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\"></path><circle cx=\"180\" cy=\"64\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"180\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 1</text><circle cx=\"261\" cy=\"119\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"261\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 2</text><circle cx=\"230\" cy=\"209\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"230\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 3</text><circle cx=\"130\" cy=\"209\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"130\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 4</text><circle cx=\"99\" cy=\"119\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></circle><text x=\"99\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 5</text><rect x=\"505\" y=\"131\" width=\"70\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"540\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">ESB</text><circle cx=\"540\" cy=\"64\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></circle><text x=\"540\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 1</text><path d=\"M540 82 L540 131\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\" fill=\"none\"></path><circle cx=\"627\" cy=\"119\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></circle><text x=\"627\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 2</text><path d=\"M610 124 L575 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\" fill=\"none\"></path><circle cx=\"594\" cy=\"209\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></circle><text x=\"594\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 3</text><path d=\"M583 195 L551 157\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\" fill=\"none\"></path><circle cx=\"486\" cy=\"209\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></circle><text x=\"486\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 4</text><path d=\"M497 195 L529 157\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\" fill=\"none\"></path><circle cx=\"453\" cy=\"119\" r=\"17\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></circle><text x=\"453\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">app 5</text><path d=\"M470 124 L505 134\" stroke=\"var(--phosphor)\" stroke-width=\"1.1\" fill=\"none\"></path></svg>", "caption": "Point to point, five systems need up to ten connections; with a bus, five. The bus also became the place where the rules lived, which is the part microservices rejected."}
```

The bus did real work. It cut the number of connections from one per pair to one per application.
It translated between formats, so the billing system's XML and the warehouse's fixed-width records
could meet. It routed messages by content. And it orchestrated: a business process such as "take an
order" was often written *in the bus*, as a flow of steps calling one service after another.

**That last part is where it went wrong.** The rules of the business moved out of the applications
and into a shared piece of middleware, owned by a central integration team. Every change to a
process was a change to the bus, queued behind every other team's change. The bus became the
bottleneck it was meant to remove, and often a single point of failure as well.

## What survived

SOA is sometimes remembered as a failure, which is unfair. Its central idea, that a capability is
offered through a published contract rather than through its database, is the same idea lesson 2
called owning the data. What did not survive was the heavy machinery around it: XML everywhere,
large vendor products, and **intelligence in the pipe**. Enterprise integration is still a large
subject in its own right, and the `enterprise-software` course takes it up in the
`software-architecture` track.
