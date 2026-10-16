---
title: Four shapes of BI tool
version: 1
---

There are dozens of BI tools, and comparing them feature by feature is a way to spend a week and
remember nothing. They are easier to tell apart by two questions:

- **Who builds?** An analyst dragging fields onto a canvas, a modeller writing definitions in
  files, anybody clicking through menus, or a programmer writing code.
- **Where do the definitions live?** In each workbook, in a central model, in the tool's own
  saved questions, or in the code of the app.

The four tools of this lesson sit at four different answers, which is why they were chosen:

| tool | who builds | where definitions live | what it costs |
|---|---|---|---|
| **Tableau** | analysts, on a visual canvas | in each workbook, or in shared data sources | licences per person; a free edition publishes in public |
| **Looker** | modellers write LookML; everybody else explores | in a central model, in files kept in git | an enterprise contract |
| **Metabase** | anybody, through menus; analysts in SQL | in the database (lesson 3) and in its own models and metrics | open source and free to run yourself; hosted plans are paid |
| **Streamlit** | a programmer, in Python | in the code of the app | open source and free |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"four-shapes\" aria-label=\"The BI tools placed on two axes. Across: who builds, from anybody clicking through menus on the left to a programmer writing code on the right. Up: where definitions live, from in each piece of work at the bottom to in one central model at the top. Metabase sits to the left and in the middle. Tableau sits to the left and low. Power BI sits left of centre and a little higher than Tableau. Looker sits in the middle and at the top. Streamlit sits to the right and low. The two this course runs, Metabase and Streamlit, are highlighted.\"><defs><marker id=\"four-shapes-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"110\" y1=\"270\" x2=\"690\" y2=\"270\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#four-shapes-ah)\"></line><line x1=\"110\" y1=\"270\" x2=\"110\" y2=\"40\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#four-shapes-ah)\"></line><text x=\"110\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">anybody, clicking</text><text x=\"690\" y=\"288\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a programmer, in code</text><text x=\"400.0\" y=\"310\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">who builds</text><text x=\"100\" y=\"264\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">in each piece</text><text x=\"100\" y=\"278\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">of work</text><text x=\"100\" y=\"46\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">in one central</text><text x=\"100\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">model</text><text x=\"120\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">where definitions live</text><rect x=\"148\" y=\"135\" width=\"104\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"200\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Metabase</text><rect x=\"178\" y=\"220\" width=\"104\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"230\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Tableau</text><rect x=\"278\" y=\"180\" width=\"104\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"330\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Power BI</text><rect x=\"378\" y=\"55\" width=\"104\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"430\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Looker</text><rect x=\"548\" y=\"220\" width=\"104\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Streamlit</text></svg>", "caption": "A placement to argue with, not a measurement: each tool can be pushed along both axes by how a team uses it."}
```

Lesson 4's Power BI sits between Tableau and Looker: an analyst builds on a canvas, and a semantic
model can be published once and shared. The two this course can run, Metabase and Streamlit, sit at
opposite corners, and that is deliberate: between them they show what a menu-driven tool and a
code-driven one each make easy, and what each leaves to you.

Two of the four — Tableau and Looker — are commercial products this course does not run. Their
sections describe what they are and how they think, from their own documentation, and show what
their definitions look like; anything shown from them says it was not run.
