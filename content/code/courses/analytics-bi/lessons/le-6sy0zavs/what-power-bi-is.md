---
title: What Power BI is, and what this lesson can show of it
version: 1
---

**Power BI** is Microsoft's business intelligence product, and in many companies it is simply what
BI means: job advertisements for analysts name it more than any other tool. It has two halves that
are easy to confuse:

| | what it is | where it runs |
|---|---|---|
| **Power BI Desktop** | the program where a model is built: data imported, relationships drawn, measures written, reports laid out | Windows only, free to download |
| **the Power BI service** | the website where finished reports are published, shared, refreshed on a schedule and read | a browser, and a licence per person who publishes or shares |

A file built in Desktop has the extension `.pbix`. Inside it is a **semantic model** — the tables,
the relationships between them, and the measures — and one or more **reports** drawn from it.
Microsoft called the model a *dataset* until 2023, and much of what you will read online still does.

## What this lesson can and cannot show

Power BI Desktop runs only on Windows, and this course was recorded on Ubuntu. **No formula in this
lesson was run in Power BI.** Each one is written from Microsoft's documentation, and each is shown
beside the SQL that computes the number it is defined to compute — and that SQL was run, on the
layer from lesson 3, so every number quoted here is real. Where a formula and its SQL might disagree,
the lesson says why.

That arrangement is less of a compromise than it sounds. Power BI's formula language, **DAX**, is
easy to type and hard to reason about, and the thing that makes it hard — the *filter context* of
the seventh section — is exactly a `WHERE` and a `GROUP BY` that you have been writing since lesson
1. Seeing both side by side is how most people who learn DAX after SQL eventually understand it.

If you have a Windows computer, the next section installs Power BI Desktop and every step of the
lesson can be followed in it. If you do not, read the formulas as specifications and run the SQL.
