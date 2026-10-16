---
title: The power-interest map
version: 1
---

A list of ten stakeholders does not say what to do with each. Treating all of them the same way
fails in both directions: inviting everybody to every meeting wastes the time of people who do not
care, and sending everybody the same monthly e-mail leaves the people who can stop the project
finding out too late. **The power-interest map sorts the list by two questions: how much can this
person affect the project, and how much do they care about it?**

## Two axes, four quadrants

Power is the ability to change the project's course: approve it, fund it, block it, or refuse to
supply what it needs. Interest is how much the result touches the person's own work. Draw power up
the side and interest along the bottom, and each quadrant gets a way of working:

- **Manage closely** (high power, high interest). These people shape the project, so they see the
  definitions, the mock and every decision that changes either. Meet them regularly.
- **Keep satisfied** (high power, low interest). They can stop the project but will not follow it.
  Give them short, rare updates that answer their question, and never surprise them.
- **Keep informed** (low power, high interest). They cannot stop it, but they will live with it.
  Tell them what is coming, ask what they need, and show them the mock before the build.
- **Monitor** (low power, low interest). Check now and then that this has not changed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 470\" role=\"img\" aria-label=\"A two by two grid. The vertical axis is power over the project, the horizontal axis is interest in it. Top right, manage closely: Caio Barreto and Tiago Ramos. Top left, keep satisfied: Helena Prado and Otávio Lins. Bottom right, keep informed: Marcos and the store managers, with Bruno Teixeira. Bottom left, monitor: Renata Sá and the carriers. An arrow moves the store managers up and to the right, labelled: once their bonus depends on it.\" data-fig=\"l13-map\"><rect x=\"110.0\" y=\"20.0\" width=\"280.0\" height=\"190.0\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"126.0\" y=\"48.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">keep satisfied</text><text x=\"126.0\" y=\"82.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Helena Prado, CEO</text><text x=\"126.0\" y=\"108.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Otávio Lins, CFO</text><rect x=\"400.0\" y=\"20.0\" width=\"280.0\" height=\"190.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"416.0\" y=\"48.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">manage closely</text><text x=\"416.0\" y=\"82.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Caio Barreto, operations</text><text x=\"416.0\" y=\"108.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Tiago Ramos, the data</text><rect x=\"110.0\" y=\"220.0\" width=\"280.0\" height=\"190.0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"126.0\" y=\"248.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">monitor</text><text x=\"126.0\" y=\"282.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Renata Sá, marketing</text><text x=\"126.0\" y=\"308.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the carriers</text><rect x=\"400.0\" y=\"220.0\" width=\"280.0\" height=\"190.0\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"416.0\" y=\"248.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">keep informed</text><text x=\"416.0\" y=\"282.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Marcos, deliveries</text><text x=\"416.0\" y=\"308.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">store managers, Bruno too</text><path d=\"M590.0 330.0 L630.0 170.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><path d=\"M630.0 170.0 L631.8 178.8 L624.2 176.9 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"416.0\" y=\"360.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">moves up once their</text><text x=\"416.0\" y=\"374.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">bonus depends on it</text><path d=\"M80.0 410.0 L80.0 20.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M80.0 20.0 L83.9 28.1 L76.1 28.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"72.0\" y=\"215.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">power</text><path d=\"M110.0 430.0 L680.0 430.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M680.0 430.0 L671.9 433.9 L671.9 426.1 Z\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"395.0\" y=\"450.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">interest</text></svg>", "caption": "Varanda's delivery dashboard project on the power-interest map. The quadrant says how much of your time each person gets; the arrow is the reason to redraw it whenever something about the number changes."}
```

## Varanda's delivery dashboard on the map

Caio and Tiago are in the top right: Caio owns the KPI and asked for the work, and Tiago can make or
break it by what the pipelines deliver. Helena and Otávio are top left. Helena can cancel the project
with one sentence and has no wish to read about it weekly; Otávio's carriers' contracts depend on it,
but he wants the result, not the process. Marcos and the store managers are bottom right: they will
use it every day or be judged by it, and none of them can approve it. Renata and the carriers are
bottom left for now.

**The placing is a judgement, and two analysts would place some names differently.** Tiago could be
argued into "keep informed": he has no formal authority. He is in the top right here because a
project whose data does not arrive has no other power that can save it.

## The map moves

The arrow on the map is the reason to draw it more than once. The store managers sat in "keep
informed" while the dashboard was just a report about the warehouse. **When their bonus was tied to
the delivery KPI, their interest jumped and so did their power**: nine store managers who all
dispute the same number reach Helena quickly. A project that kept sending them the monthly update
would have found them in the top right at launch, angry.

So redraw it whenever something about the number changes: a new definition, a target, a bonus, a
reorganisation. And keep it to yourself. A map that labels a director "monitor" is a working note
for the analyst and the project owner, not a document to circulate.
