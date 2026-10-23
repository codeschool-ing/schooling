---
title: Level 1, system context
version: 1
---

**The system context diagram shows the software system as one box, the people who use it and the
other software systems it depends on or that depend on it.** Nothing inside the box is shown. It is
the picture anybody can read, technical or not, and the one that should exist for every system.

It answers three questions: *what is this system for?*, *who uses it?* and *what does it need from
the world around it?*

## Carcará ticketing in context

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l03-context\" aria-label=\"The system context diagram of Carcará ticketing. In the middle, one box: Carcará ticketing, a software system that sells and checks bus tickets. On the left, three people: the passenger buys tickets using it, the station agent sells at counters, the driver checks tickets with it. On the right, three external software systems, drawn grey and dashed: the payment gateway, which charges cards and Pix; Frota, which sends the next day's trips; and the notification provider, through which tickets are sent.\"><defs><marker id=\"l03-context-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"260.0\" y=\"135.0\" width=\"200.0\" height=\"70.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"157.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Carcará ticketing</text><text x=\"360.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Software system]</text><text x=\"360.0\" y=\"182.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">sells and checks bus tickets</text><circle cx=\"90.0\" cy=\"30.0\" r=\"11\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><rect x=\"34.0\" y=\"43.0\" width=\"112.0\" height=\"40.0\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"59.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Passenger</text><text x=\"90.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">[Person]</text><circle cx=\"90.0\" cy=\"140.0\" r=\"11\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><rect x=\"34.0\" y=\"153.0\" width=\"112.0\" height=\"40.0\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Station agent</text><text x=\"90.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">[Person]</text><circle cx=\"90.0\" cy=\"250.0\" r=\"11\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><rect x=\"34.0\" y=\"263.0\" width=\"112.0\" height=\"40.0\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"279.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Driver</text><text x=\"90.0\" y=\"292.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">[Person]</text><rect x=\"550.0\" y=\"37.0\" width=\"160.0\" height=\"46.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"630.0\" y=\"53.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Payment gateway</text><text x=\"630.0\" y=\"66.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Software system]</text><rect x=\"550.0\" y=\"147.0\" width=\"160.0\" height=\"46.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"630.0\" y=\"163.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Frota</text><text x=\"630.0\" y=\"176.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Software system]</text><rect x=\"550.0\" y=\"257.0\" width=\"160.0\" height=\"46.0\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"630.0\" y=\"273.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Notification provider</text><text x=\"630.0\" y=\"286.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.0\" fill=\"var(--paper-dim)\">[Software system]</text><path d=\"M146.0 66.0 L262.0 146.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-context-am-fill-paper)\"></path><path d=\"M146.0 172.0 L258.0 172.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-context-am-fill-paper)\"></path><path d=\"M146.0 276.0 L262.0 196.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-context-am-fill-paper)\"></path><path d=\"M460.0 150.0 L550.0 76.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-context-am-fill-paper)\"></path><path d=\"M550.0 172.0 L460.0 172.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-context-am-fill-paper)\"></path><path d=\"M460.0 194.0 L550.0 268.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l03-context-am-fill-paper)\"></path><text x=\"198.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">buys tickets using</text><text x=\"202.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">sells at counters</text><text x=\"186.0\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">checks tickets with</text><text x=\"530.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">charges cards and Pix</text><text x=\"505.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">sends next day's trips</text><text x=\"520.0\" y=\"224.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">sends tickets via</text></svg>", "caption": "One box for the whole system, and only people and other systems around it. Frota is grey although Carcará owns it: grey means outside the scope, not outside the company."}
```

Everything on it is either a person or a software system:

- **Passengers** search for trips, buy tickets and receive them on their phones.
- **Station agents** sell tickets at the counter in 26 bus stations, for people who pay in cash or
  do not use the app.
- **Drivers** check tickets at the door of the bus.
- **The payment gateway**, run by another company, charges cards and Pix payments and confirms them.
- **Frota**, Carcará's own fleet system, bought in 2009, holds the buses, the drivers and the
  timetable, and sends the next day's trips every night.
- **The notification provider** sends the e-mails and SMS messages with tickets and changes.

Frota is drawn grey although Carcará owns it, because **it is outside the system being described**.
The colour says *in scope* and *out of scope*, not *ours* and *theirs*. A legend should say so,
because that is exactly the convention readers guess wrong.

## What to leave out

The context diagram is often drawn too detailed, because the author knows what is inside and
cannot resist showing it. Three things do not belong on it:

- **containers**, such as the database or the API: they are the next level;
- **protocols and technologies**: a context diagram is for everybody, and *HTTPS/JSON* means nothing
  to most of them;
- **infrastructure**, such as the cloud provider, load balancers or firewalls: unless the cloud
  provider is genuinely a system the users or the system interact with, it is deployment, which is a
  different diagram.

What it should have is **a label on every line saying what flows or what is done**, from the
perspective of the arrow's source: *buys tickets using*, *sends the next day's trips to*, *charges
cards and Pix through*.

## Drawing one for a system you do not know

The context diagram is also the first thing to draw when you arrive in a team, before reading any
code. It needs only conversations: ask *who uses it?* and *what does it talk to?*, and draw what you
are told. The disagreements between two people's answers are usually the most useful thing you will
learn that week.

**Draw it yourself.** Draw the system context of Frota, the fleet system, treating it as the
system in scope. Carcará ticketing is now one of the grey boxes around it. Which people use Frota
that ticketing never sees?
