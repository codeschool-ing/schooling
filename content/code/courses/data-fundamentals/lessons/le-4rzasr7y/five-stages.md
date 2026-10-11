---
title: Five stages, and what runs underneath them
version: 1
---

**Every number in a report has a history, and the history has five stages: the data was generated,
ingested, stored, transformed and delivered.** Take one ride. A customer unlocks bicycle B014 at
Batel at 06:01 on Monday 15 September and docks it at Passeio Público 44 minutes later. The app
writes a row to charge for it. That night a program copies the day's rides out of the app; the copy
is kept; another program cleans the rides, adds each station's name and counts them; and on Tuesday
morning Marta reads how many rides Batel had. Five stages, five places the ride could have been
lost, counted twice or changed into something it never was.

The common wrong picture is a conveyor belt: data enters on the left, moves once to the right, and
the work is done. Three things are wrong with it.

- **It runs every day, not once.** Monday's rides go through while Sunday's are being read and
  Tuesday's are being generated. A stage that fails on one day has to be repaired without stopping
  the others.
- **It runs more than once over the same day.** A copy is retried, a bug in a transformation is
  fixed and the month is rebuilt. Whether running a stage again changes the answer is the subject
  of section 09 in this lesson.
- **Storage is not a station on the belt.** Every other stage reads from it or writes to it, so it is
  better drawn as the floor under them.

## The five, in one table

| stage | the question it answers | at Roda Livre |
|---|---|---|
| **generation** | where is the data born, and what was that system built for? | the app writes a row per ride, to charge the customer |
| **ingestion** | how does a copy get out, and how often? | each night, one day of rides is copied out of the app's database |
| **storage** | where is each copy kept, and in what state? | the copy as it arrived, a cleaned copy, and the counts |
| **transformation** | what turns rows a system wrote into rows a person can use? | drop false starts, add station names, count per station |
| **delivery** | who reads the result, and in what form? | Marta's morning report; later a dashboard and Caio's model |

The figure draws the same five with storage where it belongs, under the others, and with what runs
underneath all of them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Generation: the app writes a row per ride. Ingestion copies one day out each night into the raw zone of storage. Transformation reads raw and writes the cleaned and curated zones. Delivery reads curated and produces the morning report. Under all of it, the undercurrents: security, data management, DataOps, architecture, orchestration and software engineering.\" data-fig=\"lifecycle\"><defs><marker id=\"lifecycle-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"30\" width=\"152\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"51.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">generation</text><text x=\"90.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the app writes</text><text x=\"90.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a row per ride</text><rect x=\"194\" y=\"30\" width=\"152\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"51.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">ingestion</text><text x=\"270.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one day copied</text><text x=\"270.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">out each night</text><rect x=\"374\" y=\"30\" width=\"152\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"51.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">transformation</text><text x=\"450.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">clean, join,</text><text x=\"450.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">count</text><rect x=\"554\" y=\"30\" width=\"152\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"51.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">delivery</text><text x=\"630.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the morning</text><text x=\"630.0\" y=\"82.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">report</text><line x1=\"166\" y1=\"67\" x2=\"192\" y2=\"67\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></line><rect x=\"180\" y=\"136\" width=\"528\" height=\"98\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"194\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">storage: every stage reads and writes here</text><rect x=\"214\" y=\"148\" width=\"120\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"274\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">raw</text><text x=\"274\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">raw/</text><rect x=\"394\" y=\"148\" width=\"120\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"454\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">cleaned</text><text x=\"454\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">clean/</text><rect x=\"574\" y=\"148\" width=\"120\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"634\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">curated</text><text x=\"634\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">curated/</text><line x1=\"270\" y1=\"104\" x2=\"270\" y2=\"146\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></line><line x1=\"334\" y1=\"160\" x2=\"410\" y2=\"106\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></line><line x1=\"454\" y1=\"104\" x2=\"454\" y2=\"146\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></line><line x1=\"514\" y1=\"175\" x2=\"572\" y2=\"175\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></line><line x1=\"634\" y1=\"148\" x2=\"634\" y2=\"106\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></line><rect x=\"14\" y=\"254\" width=\"694\" height=\"62\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"361\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">the undercurrents</text><text x=\"361\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">security · data management · DataOps · architecture · orchestration · software engineering</text></svg>", "caption": "The lifecycle at Roda Livre. Storage is drawn under the other stages because every one of them reads from it or writes to it, and the undercurrents apply to all five."}
```

## Where the picture comes from

The lifecycle drawn this way is Joe Reis and Matt Housley's, from their book *Fundamentals of Data
Engineering* (2022). They call the last stage **serving**, where this course says delivery, and they
list storage second, because data is stored the moment it is generated, before anybody copies it.
This course follows the order a ride is handled in at Roda Livre. Either way, the five words are the
vocabulary the rest of the `data` track assumes.

Under the stages they draw what they call the **undercurrents**: security, data management, DataOps,
data architecture, orchestration and software engineering. Those are not stages a ride passes
through. They are concerns that apply to every stage at once — who may read the raw copy, what the
columns mean, how a failure is noticed, what runs each program at 02:00. Lesson 2 takes them one at
a time; this lesson keeps them in the corner of the picture and walks the stages.

**The rest of the lesson has one section per stage, and then builds all five as four small
programs** you run on your own machine, in section 08.
