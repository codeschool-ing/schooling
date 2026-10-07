---
title: Choosing a tool
version: 1
---

Every chart in this course was drawn with matplotlib, because a library that is free, runs anywhere
and writes every step down was the best way to teach. The people who will read your charts do not
care what drew them. Your employer might: most workplaces already have a tool, and the choice is
often made before you arrive.

The tools fall into four families, and they trade the same two things against each other:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 300\" role=\"img\" data-fig=\"l20-landscape\" aria-label=\"Four families of tool placed on two axes: across, how much of the chart you can control; up, how quickly a first chart appears. Spreadsheets sit top left: a first chart in seconds, limited control. BI tools such as Power BI and Tableau sit a little lower and further right. Plotting libraries such as matplotlib sit lower and further right again. D3.js sits bottom right: complete control and the slowest start.\"><path d=\"M60.0 250.0 L580.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 36.0 L60.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"580.0\" y=\"266.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">how much of the chart you can control →</text><text x=\"68.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">↑ how fast a first chart appears</text><circle cx=\"130.0\" cy=\"66.0\" r=\"7.0\" fill=\"var(--phosphor)\"></circle><text x=\"142.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">spreadsheets</text><text x=\"142.0\" y=\"77.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Excel, LibreOffice Calc</text><circle cx=\"260.0\" cy=\"112.0\" r=\"7.0\" fill=\"var(--phosphor)\"></circle><text x=\"272.0\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">BI tools</text><text x=\"272.0\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Power BI, Tableau</text><circle cx=\"390.0\" cy=\"166.0\" r=\"7.0\" fill=\"var(--phosphor)\"></circle><text x=\"402.0\" y=\"162.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plotting libraries</text><text x=\"402.0\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">matplotlib, ggplot2</text><circle cx=\"510.0\" cy=\"218.0\" r=\"7.0\" fill=\"var(--phosphor)\"></circle><text x=\"522.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">D3.js</text><text x=\"522.0\" y=\"229.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">web graphics</text><text x=\"580.0\" y=\"286.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">positions are this lesson's judgement, not a measurement</text></svg>", "caption": "No tool is best at both. The ones that give a chart in seconds decide most of it for you; the ones that let you decide everything make you decide everything."}
```

- **Spreadsheets** give a chart in seconds from data already in a grid, and decide most of its look
  for you.
- **BI tools**, short for business intelligence, are built for dashboards: they connect to databases,
  keep a model of the data and let a reader filter and click. Power BI and Tableau are the two most
  widely used.
- **Plotting libraries** are code: every part of the chart is a line you wrote, and the same file
  draws the chart again next month.
- **D3.js** and similar web libraries draw directly in the browser and can make anything, at the cost
  of building everything.

## Questions that decide it

| question | points towards |
| --- | --- |
| Is it one chart, today, from data already in a sheet? | a spreadsheet |
| Will many people open it every week and want to filter it? | a BI tool |
| Will it be redrawn every month from new data? | a library, or a BI tool with a refresh |
| Does it need a shape no tool offers? | a library, or D3 |
| Who will maintain it when you leave? | whatever they already know |

The last question is the one people forget. A dashboard in a tool nobody else on the team can open
stops being updated the week its author goes on holiday.

## What does not change

Every rule in this course applies in every tool: the baseline at zero, the claim in the title, one
colour used with intent, contrast and direct labels. What changes is **where you set them**, in a
menu or a line of code, and **what the tool does if you do not**. The rest of this lesson goes
through the families with that question in mind.
