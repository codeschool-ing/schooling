---
title: Slides that carry one claim each
version: 1
---

**A slide should make one claim, state it in its title as a full sentence, and show the evidence
for it below.** That is most of what is known about technical slides, and most slides break all
three parts.

## The title is a sentence

The default slide title is a topic: "Options", "Costs", "Architecture". It tells the audience what
the slide is about and leaves them to work out what it says. A sentence title says it: "Every option
except doing nothing costs less than one year of Friday losses."

Michael Alley, who studied engineering presentations at Penn State, called this the
**assertion-evidence** structure: a sentence headline of up to two lines, and below it a picture,
chart or diagram that supports the sentence, with as little text as possible. In his group's
studies, students taught from assertion-evidence slides understood and remembered the material
better than students taught from the same content as topic titles and bullet points.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two slides side by side. On the left, a topic title, Options, above five bullets listing the options and the recommendation in text. On the right, a sentence title, every option except doing nothing costs less than one year of Friday losses, above a bar chart comparing the yearly loss with the cost of a server, a replica and pooling, with the source in small type.\"><defs><marker id=\"slidepair-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"330\" height=\"220\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"370\" y=\"30\" width=\"330\" height=\"220\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">topic title and bullets</text><text x=\"370\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">assertion and evidence</text><text x=\"40\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"16\" font-weight=\"600\" fill=\"var(--paper)\">Options</text><text x=\"40\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">• Do nothing: no cost, losses continue</text><text x=\"40\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">• Larger server: R$ 9k/month, temporary</text><text x=\"40\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">• Pooling: 2 weeks, partial</text><text x=\"40\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">• Replica: 6 weeks + R$ 4k/month</text><text x=\"40\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">• Recommendation: replica</text><text x=\"390\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Every option except doing nothing costs</text><text x=\"390\" y=\"71\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">less than one year of Friday losses</text><text x=\"390\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">loss a year</text><rect x=\"470\" y=\"112\" width=\"208.0\" height=\"16\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"390\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">server</text><rect x=\"470\" y=\"142\" width=\"40.0\" height=\"16\" rx=\"1\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"390\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">replica</text><rect x=\"470\" y=\"172\" width=\"36.0\" height=\"16\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"390\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pooling</text><rect x=\"470\" y=\"202\" width=\"6.4\" height=\"16\" rx=\"1\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"390\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">source: lesson 4, first-year costs</text></svg>", "caption": "The same content twice. Read only the titles: the left slide says what it is about, the right slide says what it claims, and its chart makes the claim visible."}
```

The test for a slide is the same as for a paragraph in lesson 1: **if the audience reads only the
title, do they get the point?** A deck whose titles, read in a row, tell the whole story can be sent
to somebody who missed the meeting, and it works.

## The evidence is a picture, not a paragraph

Text on a slide competes with the presenter. The audience reads faster than anybody speaks, so they
finish the slide's sentences before the presenter does, and then stop listening while they wait. If
the words matter, say them; if they need to be kept, put them in the document.

What goes below the title is whatever makes the claim believable at a glance:

- **one chart with one point.** The options slide shows the four costs as bars on the same scale as
  the annual loss, the figure from lesson 4. Not a table of ten columns.
- **a diagram with as few boxes as the claim needs.** Three boxes for "two systems compete for one
  database", not the full architecture.
- **one big number**, when the claim is a number. "1,350 checkouts failed in 32 minutes" set large
  on an empty slide is remembered; the same figure in a bullet is not.

## Smaller rules that matter

- **Number the slides**, so that a question can say "on slide 4".
- **Use the audience's units on the axes.** Reais and customers for leadership, as lesson 3 said.
- **Show the date and the source** under any chart, in small type. Caio will ask, and the answer
  should already be on the screen.
- **Delete the agenda slide** in a ten-minute presentation. The first thirty seconds, said aloud,
  do that job.
- **Do not read the slide.** If the presenter's words and the slide are the same, one of them is
  redundant.
