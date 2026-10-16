---
title: One question, followed from the person who asked it
version: 1
---

**The quickest way to see what a data engineer does is to follow one question until it is answered,
and notice who touches it.** Here is Marta's, on a Monday morning:

> Which stations ran out of bicycles last week, and for how long?

It sounds like a query. It is not one yet, because nothing at Roda Livre holds the answer. The
answer is spread over three systems built for other purposes, none of which was designed to be
asked this.

## Where the answer is hiding

- **The app's database** knows every ride: which bicycle left which station, and when it was docked
  again. It was built to charge customers correctly, and it keeps the current state of things, not
  their history.
- **The dock sensors** report, every minute, whether each dock holds a bicycle. They were built so the
  app can show a map, and they send their readings to a server that keeps them for two days.
- **The maintenance spreadsheet** says which docks were broken, from when to when. It was built by a
  mechanic, for the mechanics.

"Ran out" means a station with zero bicycles available. Those three sources disagree about that in
small ways: a bicycle in a broken dock is in the station and cannot be taken; a sensor can stop
reporting; the database's clock and the sensors' clocks are not the same clock.

## Who does what

**Davi, the data engineer, makes the question answerable.** He copies the sensor readings somewhere
they are kept for longer than two days, every day, without missing one. He copies the rides out of the
app's database without slowing the app down. He loads the spreadsheet, whose columns the mechanics
rename when they feel like it. He puts all three on one clock, in one place, in tables with names
that mean something, and he checks every morning that yesterday arrived.

**An analyst answers it.** Given those tables, "ran out" becomes a definition — zero available
bicycles for at least five minutes, say — and the answer becomes a query and a chart. That half of
the work is `analytics-bi`, and it is a different job.

**Caio, the data scientist, asks the next question.** Given the same tables, and two years of them,
he can predict which stations *will* run out next Friday at six. That question is impossible until
the first one has been made answerable, and stays answerable every day.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"The app database, the dock sensors and the maintenance spreadsheet feed the data engineer, who copies, keeps, puts on one clock and checks them every day, producing tables. An analyst reads the tables to answer which stations ran out; a data scientist reads them to predict which will run out next.\" data-fig=\"one-question\"><defs><marker id=\"one-question-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"178\" y=\"14\" width=\"362\" height=\"232\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"359\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">the data engineer’s half</text><rect x=\"14\" y=\"46\" width=\"146\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"87.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the app database</text><line x1=\"160\" y1=\"69\" x2=\"196\" y2=\"130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#one-question-ah)\"></line><rect x=\"14\" y=\"112\" width=\"146\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"87.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the dock sensors</text><line x1=\"160\" y1=\"135\" x2=\"196\" y2=\"130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#one-question-ah)\"></line><rect x=\"14\" y=\"178\" width=\"146\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"87.0\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the maintenance sheet</text><line x1=\"160\" y1=\"201\" x2=\"196\" y2=\"130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#one-question-ah)\"></line><rect x=\"198\" y=\"56\" width=\"160\" height=\"148\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"278.0\" y=\"91.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">the pipeline</text><text x=\"278.0\" y=\"106.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">copy it out</text><text x=\"278.0\" y=\"122.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">keep it longer</text><text x=\"278.0\" y=\"137.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one clock</text><text x=\"278.0\" y=\"153.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one place</text><text x=\"278.0\" y=\"168.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">check it daily</text><line x1=\"358\" y1=\"130\" x2=\"386\" y2=\"130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#one-question-ah)\"></line><rect x=\"388\" y=\"92\" width=\"136\" height=\"76\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"456.0\" y=\"114.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">tables</text><text x=\"456.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">rides, docks,</text><text x=\"456.0\" y=\"145.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">repairs</text><line x1=\"524\" y1=\"116\" x2=\"562\" y2=\"82\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#one-question-ah)\"></line><line x1=\"524\" y1=\"144\" x2=\"562\" y2=\"178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#one-question-ah)\"></line><rect x=\"564\" y=\"50\" width=\"144\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"636.0\" y=\"65.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">an analyst</text><text x=\"636.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">which stations</text><text x=\"636.0\" y=\"96.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ran out?</text><rect x=\"564\" y=\"148\" width=\"144\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"636.0\" y=\"163.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.0\" fill=\"var(--paper)\" font-weight=\"600\">the data scientist</text><text x=\"636.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">which will run</text><text x=\"636.0\" y=\"194.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">out on Friday?</text></svg>", "caption": "Three systems built for other purposes, one engineer who makes them answerable, and two people who ask the questions."}
```

## The part nobody sees

**Most of the data engineer's work is invisible when it works.** Marta sees a chart. She does not see
that the sensors' server was replaced in August and started sending timestamps in UTC, and that
somebody noticed because one Wednesday had 27 hours of readings. She does not see the morning the spreadsheet arrived
with a column called `doca` instead of `dock`, and the load stopped rather than reporting every dock
as unbroken.

That is the shape of the job, and the rest of this lesson gives it names. **A data engineer builds and
runs the systems that turn data made for one purpose into data that can answer questions nobody has
asked yet.** The data scientist and the analyst ask them.
