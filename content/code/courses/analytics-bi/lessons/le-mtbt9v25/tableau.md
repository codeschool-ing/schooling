---
title: Tableau
version: 1
---

**Tableau** is the tool that made the visual canvas the standard way to explore data. It has been
part of Salesforce since 2019. Its desktop program runs on Windows and macOS, and its server
products publish workbooks to a browser.

## How it thinks

Tableau's central idea is that a chart is a **query drawn**. You drag a field onto *Columns*, another
onto *Rows*, a third onto *Colour*, and Tableau writes the query, runs it and draws the result in one
step. Its engine for that translation is called VizQL. Every field is one of two kinds:

- a **dimension**, which Tableau groups by — region, segment, month;
- a **measure**, which it aggregates — net revenue, quantity — with `SUM` unless told otherwise.

That is lesson 2's split again, applied by the tool to every column the moment it reads a table. It
guesses from the column's type, and a guess is a definition nobody chose: an `order_id` stored as a
number arrives as a measure, and a chart that sums order ids is the first mistake most people make.

## Live or extract

A Tableau data source either queries the database each time — a **live** connection — or copies the
data into an **extract**, a file in Tableau's own format, refreshed on a schedule. It is the choice
lesson 4 called DirectQuery and Import, under other names, with the same trade between freshness and
speed.

## Where its definitions live

A calculated field in Tableau — the equivalent of a measure — lives in the **workbook** where it was
written, unless it was defined in a **published data source** that many workbooks share. A company
that lets each analyst build from raw tables gets lesson 3's nine revenues; one that publishes a
data source over the layer gets one. The tool permits both.

## Trying it

Tableau sells licences per person, at different prices for people who build and people who only
read. **Tableau Public** is a free edition with an important condition: what you build is published
to a public profile on the internet. That is fine for a portfolio built on open data, and wrong for
anything a company would not put on a billboard — including Lantern's customers, even invented.
