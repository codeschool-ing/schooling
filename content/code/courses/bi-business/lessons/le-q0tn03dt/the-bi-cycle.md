---
title: The BI cycle, and where it breaks
version: 1
---

A piece of BI work goes round a loop. It starts with a question somebody has to decide on, gathers
the data that bears on it, analyses it, shows the answer, and then — the part that is left out most
often — watches what the decision did. **The measurement at the end is the question at the start of
the next lap.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Six boxes in a loop. Top row, left to right: a question, the data, the analysis. Then down to the bottom row, right to left: the answer, shown; a decision; an action. An arrow from the action back up to the question is labelled: measure, did it work?\" data-fig=\"l01-cycle\"><rect x=\"20.0\" y=\"30.0\" width=\"190.0\" height=\"74.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"60.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">a question</text><text x=\"115.0\" y=\"82.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">which store do we enlarge?</text><rect x=\"265.0\" y=\"30.0\" width=\"190.0\" height=\"74.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">the data</text><text x=\"360.0\" y=\"82.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sales and floor area, 9 stores</text><rect x=\"510.0\" y=\"30.0\" width=\"190.0\" height=\"74.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"60.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">the analysis</text><text x=\"605.0\" y=\"82.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sales per square metre</text><rect x=\"510.0\" y=\"200.0\" width=\"190.0\" height=\"74.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"605.0\" y=\"230.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">the answer, shown</text><text x=\"605.0\" y=\"252.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one ranking on one page</text><rect x=\"265.0\" y=\"200.0\" width=\"190.0\" height=\"74.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">a decision</text><text x=\"360.0\" y=\"252.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Helena picks a store</text><rect x=\"20.0\" y=\"200.0\" width=\"190.0\" height=\"74.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"230.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">an action</text><text x=\"115.0\" y=\"252.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the works, then sales after</text><path d=\"M212.0 67.0 L263.0 67.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M263.0 67.0 L254.9 70.9 L254.9 63.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M457.0 67.0 L508.0 67.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M508.0 67.0 L499.9 70.9 L499.9 63.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M605.0 106.0 L605.0 198.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M605.0 198.0 L601.1 189.9 L608.9 189.9 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M508.0 237.0 L457.0 237.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M457.0 237.0 L465.1 233.1 L465.1 240.9 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M263.0 237.0 L212.0 237.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M212.0 237.0 L220.1 233.1 L220.1 240.9 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M115.0 198.0 L115.0 106.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M115.0 106.0 L118.9 114.1 L111.1 114.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"127.0\" y=\"150.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">measure: did it work?</text><text x=\"360.0\" y=\"312.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">and the measurement is the next question</text></svg>", "caption": "The BI cycle with the example of lesson 2. Starting at the data instead of the question, and stopping at the answer instead of the action, are the two ways it is usually broken."}
```

Take the example in the figure, which lesson 2 works through with real numbers. Helena wants to
enlarge one store. The question is which one. The data is each store's sales and floor area, which
Varanda already records. The analysis divides one by the other. The answer is a ranking on a page. The
decision is Helena's, and the action is the building work. The lap closes when, a year after the
works, somebody compares that store's sales with what they were and with the stores that were not
touched.

## Six steps, six places to go wrong

| step | the question it answers | how it usually goes wrong |
|---|---|---|
| a question | what has to be decided, by whom, by when? | it is skipped: "we have lots of data, what can we do with it?" |
| the data | which records bear on it, and can they be trusted? | the data that is easy to get stands in for the data that matters |
| the analysis | what do the records say about the question? | the method is chosen before the question is understood |
| the answer, shown | what does the person deciding need to see? | everything is shown, so nothing is |
| a decision | which option, and who owns it? | nobody is named, so nothing is decided |
| an action | what changes, and when do we look again? | nobody looks again |

The two failures that matter most are at the ends. **Starting from the data** produces analysis
nobody asked for, and its findings are usually true and useless: Varanda sells more umbrellas when it
rains. **Stopping at the answer** produces a dashboard that is built, launched and then visited by its
author alone. Both feel like work and both are invisible in any count of reports delivered.

## The cycle is also the course

The lessons follow the loop. Lesson 2 is about why decisions need it at all. Lessons 3 and 4 are the
people who run it and what they need to know; lesson 5 is the company whose questions they answer.
Lessons 6 to 9 are the four kinds of analysis, from what happened to what to do about it. Lessons 10
to 12 are the indicators — choosing them, defining them and catching the ones that mislead. Lesson 13
is the people who receive the answer, and lessons 14 to 16 are the three levels at which a company
decides: today, this month, this year. Lessons 17 to 21 take the same loop into finance, retail,
healthcare, industry and regulated reporting.
