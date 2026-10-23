---
title: Views and viewpoints: no picture shows everything
version: 1
---

**An architecture cannot be drawn in one diagram, because different people ask different questions
of it and each question needs its own picture.** The vocabulary for this comes from the standard
that describes architecture descriptions, ISO/IEC/IEEE 42010, and it is worth knowing because the
frameworks in lessons 8 to 10 all use it.

## Four words

- A **stakeholder** is anybody with an interest in the system: Celeste, Otávio, a passenger, the
  engineer on call at three in the morning, the auditor checking how CPFs are stored.
- A **concern** is something a stakeholder cares about: *can a bus board when the network is down?*,
  *how long does checkout take at peak?*, *who can read a passenger's document number?*
- A **viewpoint** is a recipe for a kind of picture: which concerns it addresses, for which
  stakeholders, and with which notation. *A deployment viewpoint, for operations, in UML deployment
  diagrams* is one.
- A **view** is one application of a viewpoint to one system: *Carcará's deployment view*, drawn
  this month.

**The viewpoint is reusable and the view is not.** A company that writes down its viewpoints once
gets consistent pictures from every team, which is the same idea as the *How we draw* page in the
previous section, one level up.

## Kruchten's 4+1

The best-known set of viewpoints for software is Philippe Kruchten's **4+1 view model**, from 1995.
It names four views and a fifth that ties them together:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l01-four-plus-one\" aria-label=\"Kruchten's 4+1 view model. Four views in the corners: logical, for designers; development, for developers; process, for performance and reliability; physical, for operations. In the middle, the scenarios, the use cases that connect all four and are used to check that they agree.\"><rect x=\"45.0\" y=\"27.0\" width=\"210.0\" height=\"66.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"45.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Logical view</text><text x=\"150.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">abstractions and relations</text><text x=\"150.0\" y=\"74.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">for designers</text><rect x=\"465.0\" y=\"27.0\" width=\"210.0\" height=\"66.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"45.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Development view</text><text x=\"570.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">modules and owners</text><text x=\"570.0\" y=\"74.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">for developers</text><rect x=\"45.0\" y=\"187.0\" width=\"210.0\" height=\"66.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"205.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Process view</text><text x=\"150.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what runs concurrently</text><text x=\"150.0\" y=\"234.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">for performance</text><rect x=\"465.0\" y=\"187.0\" width=\"210.0\" height=\"66.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"570.0\" y=\"205.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Physical view</text><text x=\"570.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">machines and networks</text><text x=\"570.0\" y=\"234.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">for operations</text><ellipse cx=\"360.0\" cy=\"140.0\" rx=\"110\" ry=\"44\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></ellipse><text x=\"360.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Scenarios (+1)</text><text x=\"360.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">use cases walked</text><text x=\"360.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">through all four</text><path d=\"M255.0 80.0 L300.0 112.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M465.0 80.0 L420.0 112.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M255.0 200.0 L300.0 168.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M465.0 200.0 L420.0 168.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path></svg>", "caption": "The four views answer four different questions. The scenarios are the check: one use case walked through every view finds the places where they disagree."}
```

| view | the question it answers | who asks it | typical diagram |
| --- | --- | --- | --- |
| **logical** | what are the main abstractions, and how do they relate? | analysts, designers | class diagram, lesson 2 |
| **development** | how is the code organised into modules, and who owns which? | developers, team leads | component or package diagram, lesson 2 |
| **process** | what runs at the same time, and how do the running parts communicate? | performance and reliability engineers | sequence and activity diagrams, lessons 2 and 4 |
| **physical** | what runs on which machine, and how are the machines connected? | operations, platform | deployment diagram, lesson 2 |
| **scenarios** (the +1) | do the four views together support the things users actually do? | everybody | use cases, lesson 2 |

The +1 is the important part. **The scenarios are how you check that the four views agree with each
other**: walk one use case, such as *a passenger buys a ticket*, through the logical view, then the
process view, then the physical one, and every place where the walk gets stuck is a gap in a view.

## What this means on Monday

You will not draw all five views for every system, and Kruchten did not suggest it. What the model
gives you is **a way to notice that a diagram is trying to be two views at once**: a box diagram with
servers, classes and a timeline on it is the logical, physical and process views fighting for one
page. Split it, and each picture gets clearer.

**Draw it yourself.** For a system you know, write the one stakeholder who would most need each of
the four views, and the question they would ask. If you cannot name a stakeholder for a view, that
view probably does not need drawing yet.
