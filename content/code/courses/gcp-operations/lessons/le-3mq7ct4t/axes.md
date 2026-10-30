---
title: Three ways to cut a bill, and what each one can answer
version: 1
---

**A Google Cloud bill can be cut three ways, and each answers a different question.** By **project**: which
environment or product spent it. By **folder**: which part of the organisation, since a folder groups projects
and the bill rolls up through it. By **label**: which team, service or cost centre, across projects. The three are
complementary rather than alternatives: the project is the hardest boundary (permissions, quotas and billing all stop
at it), the folder is the organisation chart, and the label is the only one that can cut across both. This section is
from Google's documentation; the next one asks the questions of a month of data on your computer.

| cut | set by | answers | does not answer |
|---|---|---|---|
| project | the project a resource is created in | what did production cost against development? | which team in production |
| folder | where the project sits in the hierarchy | what did the shop's division cost? | anything inside one project |
| label | a key and value on each resource | what did team `data` spend, wherever it ran? | anything about a resource with no label |

## Labels, and what they are not

A **label** is a key and value on a resource (`team=shop`), written by whoever creates it, and copied into every line
of the bill that resource produces. Lesson 5's `default_labels` put them on everything Terraform creates. Three facts
decide how useful they are:

- **Not every resource takes labels.** Most do; some billing lines (support, some network charges, taxes) carry none,
  so even a perfectly labelled project has a remainder.
- **Labels are not retroactive.** A label added today appears on today's bill lines and not on last month's. A cost
  report by label is only as old as the labelling.
- **A label is free text.** `team=shop`, `team=Shop` and `Team=shop` are three teams to a query. The shop's labels come
  from Terraform's `default_labels`, which is the main reason they are consistent.

**Tags** are a different thing with a similar name: they are attached to the resource hierarchy, are controlled by IAM,
and can be used in organisation policies and firewall rules. For cost reports, labels are what the billing export
carries.

## Projects are the cheapest boundary to get right

Most cost questions are answered before any label: production and development in separate projects means "what does
production cost?" is the project's line. The shop's two projects, `planner-prod` and `planner-dev`, are that split. A
team that runs both environments in one project has to label every resource perfectly to recover what a project
boundary would have given it for nothing.
