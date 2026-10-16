---
title: What is worth writing down, and for whom
version: 1
---

**Document what the code cannot tell a reader, for a reader you can name.** Everything else either
belongs in the code, or is a page that nobody will keep up to date. Most architecture documentation
fails one of those two tests, and the failure comes from two opposite beliefs.

The first is that **the code is the documentation**. It is true for what the code does, line by
line, to somebody who already knows where to look. The second is that **everything should be
documented**, which produced, at Carreto in 2021, a drive that left the wiki with 640 pages. Five
years later Renata counted 410 of them that nobody had edited in two years. The first belief leaves
a new engineer with no map; the second leaves them with a map of a city that has since been rebuilt.

## What the code cannot say

The code of Carreto's monolith answers every question about how a quote is calculated. It answers
none of these:

- **Why it is built this way.** Why Tracking has its own database and Pricing does not, and what was
  considered and rejected. That is what an architecture decision record is for, and lesson 5 showed
  one.
- **What is outside it.** Shippers, drivers, SEFAZ, the bank partner that sends the Pix payments,
  and which team owns which of the 14 services.
- **How the parts behave together while running.** The path of a delivery proof from a driver's
  phone to a payment, across three services and a broker, is in no single file.
- **Which qualities it was built to meet.** Lesson 7's one page of requirements, with the numbers
  each part of the design is held to.
- **What to do at three in the morning.** A runbook for the payout that is stuck, written by
  whoever unstuck it last time.

Each item on that list is something a reader needs and cannot recover by reading code, however
long they read. **That is the test for whether a page should exist.** A page that restates what the
code says clearly is a second copy of it, and the copy will be the one that is wrong.

## Views, because no single picture serves everybody

ISO/IEC/IEEE 42010, whose definition of architecture opened lesson 1, adds a vocabulary for this.
A system has **stakeholders**, each with **concerns**: the questions they bring to it. A **view** is a
description of the system that answers some concerns for some stakeholders. It follows that
**no single diagram can be the architecture diagram**, because the questions differ.

At Carreto the readers are easy to name, and so are their questions:

- Sílvio, the finance director: what are the big pieces, which outside parties do we depend on, and
  where does the money go?
- Helena: what can change quickly, and what would take a quarter?
- Ícaro Nunes, a junior developer on Payments: which service owns deliveries, and where does the data
  live?
- Paula Reis on Platform, on call: what runs where, and what stops if this falls over?

One drawing that tried to answer all four would carry every box and every arrow, and none of the four
would find their answer in it. Four smaller drawings, each for one question, serve them all, and two
families of views help choose those drawings.

## The C4 model: four levels of zoom

Simon Brown's **C4 model** describes a software system at four levels, each one a zoom into a single
box of the level above, like the levels of an online map.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Four panels left to right, each a zoom into one box of the panel before. Context: the shipper, the driver, SEFAZ and the bank partner around Carreto, which is highlighted; read by everybody. Container: inside Carreto, the Shipper web app, the Driver app, Matching (highlighted), Pricing and Tracking, 14 services in all; read by engineers. Component: inside Matching, the offer dispatcher (highlighted), driver ranking, load claims and the offer timer; drawn where it helps. Code: the class OfferDispatcher and its methods offer, claim and expire; generated on demand.\"><defs><marker id=\"l8c4-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"40\" width=\"160\" height=\"250\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">1 · Context</text><text x=\"90.0\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">read by everybody</text><path d=\"M172 165.0 L188 165.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l8c4-ah)\"></path><rect x=\"190\" y=\"40\" width=\"160\" height=\"250\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">2 · Container</text><text x=\"270.0\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">read by engineers</text><path d=\"M352 165.0 L368 165.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l8c4-ah)\"></path><rect x=\"370\" y=\"40\" width=\"160\" height=\"250\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">3 · Component</text><text x=\"450.0\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">drawn where it helps</text><path d=\"M532 165.0 L548 165.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l8c4-ah)\"></path><rect x=\"550\" y=\"40\" width=\"160\" height=\"250\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">4 · Code</text><text x=\"630.0\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">generated on demand</text><rect x=\"22\" y=\"54\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Shipper</text><rect x=\"22\" y=\"90\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"90.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Carreto</text><rect x=\"22\" y=\"126\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Driver</text><rect x=\"22\" y=\"162\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SEFAZ</text><rect x=\"22\" y=\"198\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Bank partner</text><rect x=\"202\" y=\"54\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Shipper web app</text><rect x=\"202\" y=\"90\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Driver app</text><rect x=\"202\" y=\"126\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"270.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Matching</text><rect x=\"202\" y=\"162\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Pricing</text><rect x=\"202\" y=\"198\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Tracking</text><text x=\"270.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">14 services in all</text><rect x=\"382\" y=\"54\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"450.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Offer dispatcher</text><rect x=\"382\" y=\"90\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Driver ranking</text><rect x=\"382\" y=\"126\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Load claims</text><rect x=\"382\" y=\"162\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Offer timer</text><text x=\"564\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">class OfferDispatcher</text><text x=\"564\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">  def offer(load)</text><text x=\"564\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">  def claim(driver)</text><text x=\"564\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">  def expire(offer)</text></svg>", "caption": "The C4 model's four levels at Carreto. Each panel opens the highlighted box of the one before it, and each level has its own readers. Most teams need the first two."}
```

- **Context.** The system as one box, with the people who use it and the other systems it talks to.
  It is the picture for Sílvio and Helena, and for any engineer's first day.
- **Container.** Inside the system box: the separately running things — web apps, mobile apps,
  services, databases, the broker — and how they talk to each other. A container here means a
  runnable unit, not a Docker container, although it may run in one. It is the picture for Ícaro and
  Paula.
- **Component.** Inside one container: its main parts and their responsibilities.
- **Code.** Inside one component: classes and functions.

**Brown's own advice is that most teams need only the first two.** Component diagrams are worth
drawing for a container whose inside is hard to understand, and the code level is better generated by
a tool on the day somebody needs it, because it changes with every commit. For Carreto that means one
context diagram, one container diagram showing the 14 services, and component diagrams for two
containers: Matching and Payments, whose insides are where new engineers get lost. That is four
drawings for a company of fifty engineers. C4 also has a few supplementary diagrams, a deployment
diagram and a dynamic one for a flow among them, used when a question needs them.

`architecture-modeling` lesson 3 teaches the notation properly. Here, the point is the choice: **pick
the level by the reader's question**, and stop at the level where the question is answered.

## The 4+1 views

Philippe Kruchten published the **4+1 view model** in 1995, from a different starting point: four
views, each answering one kind of concern, and a fifth that ties them together.

- The **logical view**: what the system does for its users, decomposed into its main abstractions.
- The **process view**: what runs at the same time, how the parts communicate at runtime, and how it
  behaves under load.
- The **development view**: how the code is organised into modules and repositories, and which team
  works on which.
- The **physical view**: what runs on which machines and networks.
- The **scenarios**, the "+1": a handful of important use cases walked through all four, which both
  explain the views and check that they agree.

The two families overlap more than they differ. C4's container diagram covers much of the
development and physical views; its dynamic diagram is a small process view. **4+1 earns its place
where concurrency or deployment is the hard part.** Tracking takes GPS positions from thousands of
phones at once. The question that matters there is what happens when a burst of positions arrives
faster than they can be written, and that is a process-view question a container diagram does not
answer. The UML diagrams usually drawn inside 4+1 views belong to `architecture-modeling` lesson 2.

## How much is enough

Renata's starting list for Carreto was short on purpose. A context diagram and a container diagram.
The ADRs, and the one page of requirements from lesson 7. A README for each service saying what it
is for, who owns it and how to run it. And runbooks for the incidents that have already happened once. **A
smaller set kept true beats a larger set that is half right**, and the next two sections are about
the keeping.

For a checklist of what might be missing, **arc42**, a template by Gernot Starke and Peter Hruschka,
lays out twelve sections, from goals and constraints through the building blocks and runtime
behaviour to risks, technical debt and a glossary. It works well as a list of questions to ask about
your own documentation. Filled in completely, section by section, it becomes the 2021 wiki again.
