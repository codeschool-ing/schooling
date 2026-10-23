---
title: Component diagrams: what each part offers and needs
version: 1
---

**A component diagram shows the replaceable parts of a system and the interfaces through which
they connect: what each part provides to others, and what it requires from them.** It is the
diagram for questions about dependencies and substitution: *what breaks if Pricing changes?*, *can
we swap the payment provider without touching ticketing?*

## The notation

- A **component** is a rectangle with the keyword `«component»` or a small component icon in its
  corner. It is a modular part with a well-defined interface: a service, a library, a module of a
  larger program.
- A **provided interface** is drawn as a small circle on a stick, the **ball** or lollipop: *this
  component offers this*.
- A **required interface** is a half circle on a stick, the **socket**: *this component needs this
  from somebody*.
- An **assembly connector** is a ball fitted into a socket: one component's need is met by another's
  offer.
- A **port**, a small square on the component's edge, groups interfaces at one point of interaction.
  It is optional and often left out.
- A **dependency**, the dashed open arrow from the class diagram, can join components directly when
  the interface does not matter to the question.

## Carcará's sales components

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-component\" aria-label=\"A component diagram of Carcará's sales. Four components: passenger app, ticketing, pricing and payment adapter, and the payment gateway, outside, dashed. Ticketing provides the interface Bookings, a ball, which the passenger app requires, a socket fitted round it. Pricing provides FareQuote, which ticketing requires. The payment adapter provides PaymentPort, which ticketing requires. The gateway provides its own API, which the payment adapter requires.\"><rect x=\"20.0\" y=\"120.0\" width=\"160.0\" height=\"60.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"158.0\" y=\"128.0\" width=\"14.0\" height=\"16.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"154.0\" y=\"131.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"154.0\" y=\"137.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"30.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">«component»</text><text x=\"94.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Passenger app</text><rect x=\"280.0\" y=\"120.0\" width=\"160.0\" height=\"60.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"418.0\" y=\"128.0\" width=\"14.0\" height=\"16.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"414.0\" y=\"131.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"414.0\" y=\"137.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"290.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">«component»</text><text x=\"354.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Ticketing</text><rect x=\"280.0\" y=\"18.0\" width=\"160.0\" height=\"56.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"418.0\" y=\"26.0\" width=\"14.0\" height=\"16.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"414.0\" y=\"29.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"414.0\" y=\"35.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"290.0\" y=\"32.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">«component»</text><text x=\"354.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Pricing</text><rect x=\"540.0\" y=\"120.0\" width=\"160.0\" height=\"60.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"678.0\" y=\"128.0\" width=\"14.0\" height=\"16.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"674.0\" y=\"131.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"674.0\" y=\"137.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"550.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">«component»</text><text x=\"614.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Payment adapter</text><rect x=\"540.0\" y=\"222.0\" width=\"160.0\" height=\"56.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><rect x=\"678.0\" y=\"230.0\" width=\"14.0\" height=\"16.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"674.0\" y=\"233.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><rect x=\"674.0\" y=\"239.0\" width=\"8.0\" height=\"4.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></rect><text x=\"550.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">«component»</text><text x=\"614.0\" y=\"257.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Payment gateway</text><path d=\"M280.0 150.0 L243.0 150.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><circle cx=\"236.0\" cy=\"150.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><path d=\"M180.0 150.0 L225.0 150.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M233.6 139.3 A11 11 0 0 1 233.6 160.7\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"236.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Bookings</text><path d=\"M360.0 74.0 L360.0 89.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><circle cx=\"360.0\" cy=\"96.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><path d=\"M360.0 120.0 L360.0 107.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M349.3 98.4 A11 11 0 0 1 370.7 98.4\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"376.0\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">FareQuote</text><path d=\"M540.0 150.0 L499.0 150.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><circle cx=\"492.0\" cy=\"150.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><path d=\"M440.0 150.0 L481.0 150.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M489.6 139.3 A11 11 0 0 1 489.6 160.7\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"492.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">PaymentPort</text><path d=\"M620.0 222.0 L620.0 209.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><circle cx=\"620.0\" cy=\"202.0\" r=\"7\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></circle><path d=\"M620.0 180.0 L620.0 191.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M630.7 199.6 A11 11 0 0 1 609.3 199.6\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"636.0\" y=\"204.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Gateway API</text><text x=\"20.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ball: provided</text><text x=\"20.0\" y=\"254.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">socket: required</text></svg>", "caption": "Ticketing meets the rest only at three named interfaces. A partner company's fares would be a second provider of FareQuote, and nothing inside Ticketing would change."}
```

The figure answers Otávio's question from a planning meeting: *could we sell tickets for a partner
bus company through our site?* It shows that **Ticketing** requires two interfaces, `FareQuote`
and `PaymentPort`, and provides one, `Bookings`. Pricing provides the fares; the **payment adapter**
provides `PaymentPort` and itself requires the gateway's API.

So the answer is readable from the sockets: a partner's trips need a second provider of
`FareQuote`, and nothing else in Ticketing changes. If Ticketing had called Pricing's tables
directly, the diagram would show a dependency arrow straight into the database, and the honest
answer would be *we would have to change Ticketing too*.

## Why the interfaces are the point

**A component diagram without interfaces is a box diagram with a keyword on it.** The balls and
sockets are what make it say something a box diagram cannot: that two parts meet only at a named,
narrow contract, and that anything offering the same contract could take one side's place. That is
the dependency inversion principle from `design-patterns` lesson 4, drawn.

The commonest mistakes follow from forgetting that:

- **every component connected to every other**, with dependency arrows and no interfaces, which
  shows coupling but not where it could be cut;
- **sockets with no ball**, a requirement nobody provides, which is either a gap in the diagram or a
  gap in the system, and worth finding out which;
- **components that are classes**, which turns the diagram into a class diagram with fewer details.

## Components, containers and deployment

A component is a **logical** part. It says nothing about where it runs: Ticketing and Pricing could
be two services or two modules in one program. Where they run is the deployment diagram's question,
in the next section. Lesson 3 adds C4's word **container** for *a separately running thing*, which
sits between the two, and that word causes more confusion than any arrowhead.
