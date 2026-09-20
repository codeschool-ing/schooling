---
title: Charts, where the picture must not say more than the numbers
version: 1
---

A chart is an argument. It takes a table nobody would read and turns it into something a person
takes in at a glance — which is exactly why a chart can be wrong in a way a table cannot.

## Start from the question

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 288\" role=\"img\" aria-label=\"Five rows pairing a question with the chart that answers it. How it changed over time goes with a line. How categories compare goes with a bar, sorted. How two numbers relate goes with a scatter. How the values are spread goes with a histogram. How much of a total each part is goes with a bar again, and a pie only for two or three parts.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Start from the question, never from the chart menu</text><text x=\"44\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the question you are asking</text><text x=\"676\" y=\"46\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the chart that answers it</text><rect x=\"24\" y=\"62\" width=\"672\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"77\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">how did it change over time</text><text x=\"676\" y=\"77\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a line</text><rect x=\"24\" y=\"100\" width=\"672\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"115\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">how do these categories compare</text><text x=\"676\" y=\"115\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a bar, sorted</text><rect x=\"24\" y=\"138\" width=\"672\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"153\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">how do these two numbers relate</text><text x=\"676\" y=\"153\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a scatter</text><rect x=\"24\" y=\"176\" width=\"672\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"191\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">how are the values spread out</text><text x=\"676\" y=\"191\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a histogram</text><rect x=\"24\" y=\"214\" width=\"672\" height=\"30\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"44\" y=\"229\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">how much of the total is each part</text><text x=\"676\" y=\"229\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a bar, and a pie only for two or three</text><text x=\"24\" y=\"270\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">A chart chosen from the menu answers whichever question that chart happens to answer.</text></svg>", "caption": "The last row is the one worth arguing about: a pie is read by comparing angles, which people do badly above about three slices."}
```

Choosing from the chart menu and seeing which looks best is choosing an argument and then finding
out what it says. Deciding the question first takes ten seconds and removes most of the bad
charts anybody has ever made.

## The axis rule, which is not a matter of taste

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 298\" role=\"img\" aria-label=\"Two bar charts of the same three values, ninety-eight, one hundred and one hundred and two. In the left chart the axis starts at zero and the three bars are almost the same height. In the right chart the axis starts at ninety-six and the last bar is three times the height of the first.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">The same three numbers, drawn twice</text><text x=\"24\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">with the axis at zero</text><path d=\"M50 68 L50 218 L320 218\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></path><text x=\"44\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><rect x=\"74\" y=\"74\" width=\"56\" height=\"144\" fill=\"var(--phosphor)\" fill-opacity=\"0.35\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"102\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">98</text><rect x=\"154\" y=\"71\" width=\"56\" height=\"147\" fill=\"var(--phosphor)\" fill-opacity=\"0.35\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"182\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">100</text><rect x=\"234\" y=\"68\" width=\"56\" height=\"150\" fill=\"var(--phosphor)\" fill-opacity=\"0.35\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"262\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">102</text><text x=\"374\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">with the axis at ninety-six</text><path d=\"M400 68 L400 218 L670 218\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></path><text x=\"394\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">96</text><rect x=\"424\" y=\"168\" width=\"56\" height=\"50\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"452\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">98</text><rect x=\"504\" y=\"118\" width=\"56\" height=\"100\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"532\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">100</text><rect x=\"584\" y=\"68\" width=\"56\" height=\"150\" fill=\"var(--amber)\" fill-opacity=\"0.35\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"612\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">102</text><text x=\"24\" y=\"248\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">a four per cent spread, which is what it is</text><text x=\"374\" y=\"248\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the same four per cent, looking like a tripling</text><text x=\"24\" y=\"280\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Neither chart is a lie about the numbers. Only one of them is a lie about the size of the difference.</text></svg>", "caption": "The rule is not that a truncated axis is forbidden. It is that a bar's length is read as its value, so a bar chart has to start at zero."}
```

**A bar is read by its length**, so the length has to be the value, so the axis has to start at
zero. A truncated axis on a bar chart is not emphasis; it is a bar three times as long as another
bar describing a four per cent difference.

**A line is read by its slope**, so a line chart may start wherever the data is interesting. That
is the exception and it is the whole of the exception.

## Four more that do the most work

- **Sort the bars.** A bar chart of categories should be in order of value, not alphabetical,
  unless the categories have their own order — months, sizes, grades. Sorting is what makes the
  comparison readable.
- **Label the thing rather than the legend.** A legend makes the eye travel; a label on the line
  or at the end of the bar does not. Two series rarely need a legend at all.
- **Say the units.** `Sales` is not an axis title. `Sales, R$ thousands` is, and it is the
  difference between a chart somebody can act on and one they have to ask about.
- **Title it with the finding.** *Sales fell in the second quarter* is a title. *Sales by
  quarter* is a filing label, and the reader has to work out what they are meant to see.

## Pie charts, honestly

A pie is read by comparing angles, which people do badly. Above about three slices nobody can
order them by eye, and the moment two slices are close the chart has stopped answering the
question it was drawn for.

**Two or three parts of a whole: a pie is fine and it is immediately legible.** More than that: a
sorted bar chart says the same thing and can be read.

And never a 3D pie. The perspective makes the near slices larger, which means the picture is
wrong by an amount that depends on where a slice happens to sit.

## The one that is not about drawing

**A chart built on a range does not grow.** Add a hundred rows under a chart's data and the chart
shows the first nine hundred, quietly, for as long as nobody checks.

Build charts on **tables** — the `Ctrl+T` feature from lesson nine — and the range grows with the
data. It is the same fix as everything else in this lesson: define the thing once, and let
everything point at the definition.
