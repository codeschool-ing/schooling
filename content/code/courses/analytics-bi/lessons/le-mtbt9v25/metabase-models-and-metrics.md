---
title: Models and metrics, the layer inside Metabase
version: 1
---

Metabase has two features of its own that do what lesson 3's views do, and it is worth knowing both
exist, and what they cost.

A **model** is a saved question that Metabase treats as a table. Its own description says it: *do
all your joins and custom columns once, save it as a model, then query it like a table*. A model can
carry descriptions for its columns, and other questions start from it as if it were a view. They
are listed under **Browse models**, and **Create a new model** starts one.

A **metric** is a saved aggregation with a name: *Net revenue* defined once as the sum of
`net_revenue` over `Orders`, and then offered by name in the editor wherever it applies, so a person
building a question picks the metric rather than rebuilding the sum. They are listed under **Browse
metrics**, and **Create a new metric** starts one. A fresh Metabase shows two of its own there, from
its sample data, as examples.

## Which layer, then

Lantern now has two places a definition can live: the views of `semantic.sql`, and Metabase's models
and metrics. The rule this course follows is the one lesson 3 argued:

| definition | where | why |
|---|---|---|
| what net revenue means, which rows exist, which day an order falls on | the database views | every tool reads them, including the Streamlit app of the next sections and the reverse ETL of lesson 7 |
| how Metabase's users find things: a metric named for the menu, a model shaped for one team's questions | Metabase | they are about the tool's interface, and no other tool needs them |

**A metric in Metabase should sum a column whose meaning was already decided in the database.** The
day a Metabase metric starts filtering out refunded orders by itself, the definition of net revenue
lives in two places, and lesson 2's meeting is back.
