---
title: What a box claims, and what a line claims
version: 1
---

**Every mark on an architecture diagram is a claim about the system.** A box claims that something
exists and has a boundary. A line claims that two of those things are related in some way. A word
on either one says what kind of thing, or what kind of relation. Reading a diagram well means
reading each mark as the claim it makes, and noticing when a mark makes no claim the reader can use.

## The box

A box with only a name says that something called that exists. That is rarely enough, because the
same word names very different things. At Carcará, "Booking" is the name of a team, a service, a
database schema, a table and a screen in the app. A box labelled `Booking` could be any of them.

Three additions turn a name into a claim somebody can check:

- **a type**: is it a service, a database, a queue, a person, a whole external system?
- **a technology**, when the reader is technical: *Kotlin service on the JVM*, *PostgreSQL 16*.
- **a responsibility**, in a few words: *holds bookings and seat reservations*.

C4, in lesson 3, makes those three a rule for every element. You do not need C4 to follow it.

## The line

The line is where most diagrams go wrong, and the arrow is the worst of it, because **an arrow with
no label can mean at least five different things**, and all five appear on real diagrams, often on
the same one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l01-arrow-meanings\" aria-label=\"One unlabelled arrow from the passenger app to the ticketing API, and five things it is commonly taken to mean: the app calls the API; data flows from the app to the API; the app depends on the API, so a change to the API can break it; the app is part of, or owned by, the API; the app comes before the API in a sequence of steps. The first two describe the same conversation and can point in opposite directions.\"><defs><marker id=\"l01-arrow-meanings-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"35.0\" y=\"26.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Passenger app</text><rect x=\"335.0\" y=\"26.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Ticketing API</text><path d=\"M186.0 46.0 L334.0 46.0\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l01-arrow-meanings-am-fill-paper)\"></path><text x=\"260.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--amber)\">?</text><circle cx=\"48.0\" cy=\"112.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"48.0\" y=\"112.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">1</text><text x=\"72.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">calls</text><text x=\"210.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the app sends requests and waits for answers</text><circle cx=\"48.0\" cy=\"148.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"48.0\" y=\"148.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">2</text><text x=\"72.0\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sends data to</text><text x=\"210.0\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the order travels this way; the answer comes back the other way</text><circle cx=\"48.0\" cy=\"184.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"48.0\" y=\"184.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">3</text><text x=\"72.0\" y=\"184.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">depends on</text><text x=\"210.0\" y=\"184.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">change the API and the app may break</text><circle cx=\"48.0\" cy=\"220.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"48.0\" y=\"220.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">4</text><text x=\"72.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">is part of</text><text x=\"210.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">owned by, deployed with, or contained in</text><circle cx=\"48.0\" cy=\"256.0\" r=\"9\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"48.0\" y=\"256.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">5</text><text x=\"72.0\" y=\"256.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">comes before</text><text x=\"210.0\" y=\"256.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a step in a process, not a call at all</text><text x=\"612.0\" y=\"124.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">opposite</text><text x=\"612.0\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">directions</text><path d=\"M590 104 L600 104 L600 152 L590 152\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path></svg>", "caption": "An arrow with no label leaves the reader to choose one of five meanings, and different readers choose differently without knowing it."}
```

The two readings people mix up most are the first and the second. "The app calls the API" and "the
data flows from the API to the app" point in **opposite directions** for the same conversation: the
request goes one way, the answer comes back the other. A diagram that uses arrows for calls in one
corner and for data in another is a diagram where half the arrows are backwards for every reader.

So **every line carries a label, and the label is a verb phrase in the direction of the arrow**:
*sends booking requests to*, *reads schedules from*, *publishes ticket-sold events to*. When it
matters, add the protocol: *HTTPS/JSON*, *SQL*, *AMQP*. A label like *uses* is better than nothing
and not much better, because it is the one verb that fits every arrow.

## Position, size and colour

Three more things on a diagram look like claims and usually are not:

- **Position.** Readers assume that something on the left comes first and that something at the top
  is more important. If neither is true, the reader still reads it, so either arrange it to be true
  or keep the layout plainly neutral.
- **Size.** A bigger box looks more important or more complex. If the ticketing API is drawn three
  times the size of the payment integration, a reader will believe it does three times the work.
- **Colour and line style.** Colour is a strong signal, and readers try to decode it. **If colour
  means something, a legend says what**; if it means nothing, use one colour. A dashed line is
  read as "different" — optional, asynchronous, planned — so it needs a key as well.

## Boundaries

A box drawn around other boxes makes one more kind of claim: these belong together, and something
about the inside differs from the outside. A boundary may mean *deployed together*, *owned by one
team*, *inside our network* or *one bounded context*, and those four boundaries rarely coincide.
**Name the boundary, and draw one kind per diagram** unless the legend separates them.
