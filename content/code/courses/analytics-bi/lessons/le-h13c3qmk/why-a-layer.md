---
title: Why a layer between the tables and the people
version: 1
---

Lesson 2 ended with a definition of net revenue written in two places: a view, and a comment on
it. That works while one analyst writes every query. It stops working the day the business wants
**self-service**: a marketing manager building her own chart, a finance analyst exploring a
question nobody anticipated, without asking the data team each time.

Self-service on raw tables fails in a predictable way. Each person who builds a chart writes the
definition again — through a tool's menus rather than in SQL, but a definition all the same — and
each writes it slightly differently. One forgets the test account, one sums gross values, one
groups by the UTC date because that is what the tool did by default. Six months later the company
has forty charts of revenue and nine numbers, which is the meeting from lesson 2 multiplied by
everybody who has a login.

A **semantic layer** is the fix: a set of tables or views, maintained by people who know the data,
that present the business in its own terms, with the definitions already applied. The people
building charts read only the layer. **They choose what to look at; they do not choose what a
word means.** In the layer, `net_revenue` is a column that is already net, already excludes the
test account and already sits on the São Paulo day, so summing it is the definition, and nobody
building a chart can get it wrong by accident.

The term covers a range of things. At one end it is what this lesson builds: a schema of SQL views
with business names and comments, which any tool that speaks SQL can read. At the other end are
products whose whole job is to be the layer — LookML in Looker, the dbt Semantic Layer, Cube, a
Power BI semantic model — and the last section of this lesson places them. What they all share is
the idea, and the idea is the part that matters: **definitions are written once, by somebody
accountable for them, in a place every tool reads.**

What a layer does not do is decide the definitions. Lesson 2 is still where that happens. The
layer is where a decision, once made, stops depending on everybody remembering it.
