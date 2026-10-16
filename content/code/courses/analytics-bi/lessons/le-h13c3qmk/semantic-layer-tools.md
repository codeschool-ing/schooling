---
title: Where the layer lives in other tools
version: 1
---

Lantern's layer is SQL views with comments, and that is a real semantic layer: every tool that can
read PostgreSQL reads it the same way. Larger organisations often use a product built for the job.
They differ in where the definitions live and how much they enforce; the idea is the one this lesson
built. The descriptions below are of each product's own documentation, and none of them was run for
the course.

| tool | where the definitions live | what it adds over views |
|---|---|---|
| LookML, in Looker | text files of views, measures and the joins between them, kept in git | joins are declared once, so a user cannot join two tables a way the model does not allow |
| dbt Semantic Layer, with MetricFlow | YAML files beside a dbt project, naming entities, measures and metrics | a metric is defined once and compiled to SQL for whichever tool asks, at whichever grain |
| Cube | a server with its own model files, between the database and the tools | an API in front of the database, with caching and access rules |
| a Power BI semantic model | the model inside a Power BI file: relationships, measures in DAX | one model shared by many reports, published to the Power BI service |

Three questions place any of them, and they are the same three to ask of this lesson's layer:

- **Who writes a definition, and where is it reviewed?** Files in git can be reviewed like code; a
  definition typed into a tool's screen usually cannot.
- **Can a user get around it?** Views can be bypassed by anybody with access to the tables, which
  is why the role in this lesson can read only the layer. Some products refuse unsafe joins
  outright.
- **Which tools read it?** Views are read by anything that speaks SQL. A product's own layer is read
  by the tools that support it, and a definition that lives in one dashboard tool is not a shared
  definition at all once a second tool arrives.

Lesson 4 builds the same star as a Power BI semantic model, and lesson 5 meets LookML again in the
context of Looker.
