---
title: Business intelligence tools
version: 1
---

Power BI, from Microsoft, and Tableau, owned by Salesforce, are the two business intelligence
tools you are most likely to meet. They are built for the subject of lessons 18 and 19: dashboards
that many people open, filter and come back to.

They work in a similar way. A **data source** is connected once: a file, a database, a company's
data warehouse. The tool keeps a **model** of it, with the fields listed in a pane. A chart is made by
dragging fields onto the canvas or onto slots for the axes, colour and size, and the tool picks a
chart type it thinks fits. Charts are arranged into a dashboard or report page and **published** to a
server, where other people open them in a browser or an app.

## What they do well

- **Interaction.** Clicking a bar in one chart can filter every other chart on the page. That is hard
  to build in a library and free in a BI tool.
- **Refreshing.** A published dashboard can reload its data on a schedule, so Monday's numbers are
  there on Monday without anybody redrawing anything.
- **Sharing with permissions.** The server decides who sees which dashboard, which a folder of image
  files cannot.

## What to watch

- **The automatic chart type.** It is a guess. Check it against lesson 2's ranking before accepting it.
- **Defaults again**: legends for one series, rainbow palettes, every chart the same size. Lessons 13,
  17 and 18 apply unchanged.
- **Licences.** Power BI Desktop, the program charts are built in, is a free download for Windows;
  sharing through Microsoft's service generally needs a paid licence. Tableau's free edition publishes
  to **Tableau Public**, where anything saved can be seen and downloaded by anyone.
- **Data that is not yours to publish.** That last point is a privacy question, not a pricing one.
  Customer data, sales figures and anything with a person's details in it do not belong on a public
  gallery, whatever the tool's free tier encourages. Check what your organisation allows before
  uploading anything.

These tools change their menus every few months, so this lesson does not teach where the buttons
are. What it teaches is what to look for once you have found them.
