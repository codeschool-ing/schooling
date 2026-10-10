---
title: A program nobody wrote the rule for
version: 1
---

Most people arrive at this course thinking of a model as a clever program. **It is closer to a
table of numbers that a program filled in by reading examples.** The program that reads them is
ordinary and somebody else's, usually a library; what makes the result useful is which examples it
read, and that is the part a data engineer owns.

Take the question this course carries from start to finish. Ponto Final, the chain of bookshops
from `warehouse-modeling` and `pipelines-etl`, runs a loyalty card. The marketing team wants to
send a voucher to card members who are about to stop coming, before they stop. Somebody has to
say, for each member, how likely that is.

There are two ways to answer, and the difference between them is the whole subject.

**A rule written by a person.** *A member who has not been in for 120 days has lapsed.* It is one
line of SQL, everybody can read it, and it is wrong in both directions: it flags the member who
buys twice a year and is fine, and it misses the member who came every week until a month ago.

**A rule learned from examples.** Take the members as they stood on one day last year, describe
each one in numbers (how many days since the last visit, how many visits, how much spent), and
write beside each one what actually happened afterwards: came back, or did not. A learning
algorithm reads those rows and finds the weights that best separate the two outcomes. What it
produces is a **model**: given the numbers for a member today, it returns a probability.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l01-rule-or-model\" aria-label=\"Two ways to decide whether a member has lapsed. Above, a rule a person wrote: a member today goes through the rule recency_days &gt; 120 and comes out yes or no. Below, a rule learned: last year's members, each with features and a known label, are read by training, which produces a model; a member today goes through the model and comes out with a probability, 0.86.\"><defs><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">written by a person</text><rect x=\"40.0\" y=\"44.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">a member today</text><rect x=\"280.0\" y=\"44.0\" width=\"180.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"370.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">a rule</text><text x=\"370.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">recency_days &gt; 120</text><path d=\"M190.0 69.0 L278.0 69.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M460.0 69.0 L548.0 69.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"550.0\" y=\"50.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">yes or no</text><path d=\"M20.0 128.0 L700.0 128.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"20.0\" y=\"154.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">learned from examples</text><rect x=\"40.0\" y=\"174.0\" width=\"200.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">last year's members</text><path d=\"M40.0 202.0 L240.0 202.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"105.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">features</text><text x=\"205.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">label</text><path d=\"M170.0 202.0 L170.0 294.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"105.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4  4  33940</text><text x=\"205.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0</text><text x=\"105.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">105  1  4990</text><text x=\"205.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1</text><text x=\"105.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">30  6  76870</text><text x=\"205.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0</text><path d=\"M240.0 234.0 L318.0 234.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><text x=\"279.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">training</text><rect x=\"320.0\" y=\"204.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">a model</text><text x=\"400.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one weight per feature</text><rect x=\"330.0\" y=\"300.0\" width=\"140.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"313.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a member today</text><path d=\"M400.0 300.0 L400.0 266.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><path d=\"M480.0 234.0 L548.0 234.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><rect x=\"550.0\" y=\"215.0\" width=\"140.0\" height=\"38.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">p = 0.86</text></svg>", "caption": "The same question answered two ways. The rule is one line anybody can read; the model is a table of weights nobody wrote, and what it learned depends on which rows it was shown."}
```

Three words appear in every lesson from here on, so they are worth fixing now:

- a **feature** is one of the numbers that describe an example: `recency_days`, `visits_180d`;
- a **label** is the answer written beside an example, here `lapsed`, 1 or 0;
- **training** is the algorithm reading the examples and fitting the model; **prediction**, or
  **inference**, is the model answering for an example it has not seen.

## Where the data engineer stands

The modeller chooses the algorithm and judges the result. Everything before and after that belongs
to the platform: **which rows become examples, how each feature is computed, how the label is
attached without leaking the future into the past, where the trained model is kept, how it reaches
the place that asks it questions, and how anybody finds out when it stops being right.** That is
most of the work, and it is the part that breaks in production.

So this course takes the data engineer's side of the model. Lessons 1 to 4 give you the vocabulary
a modeller will use with you: the kinds of learning, the common tasks, how data is split so that a
score means something, and which scores lie. Lessons 5 to 10 are the lifecycle itself: your role in
it, features that can be reproduced, versions of data and models, deployment, monitoring, and what
to do when the world the model learned from moves.

**This is not a statistics course.** The algorithms come from scikit-learn, the same way a
database engine comes from PostgreSQL: you need to know what they promise and where they break,
not how to write one.
