---
title: What the job is answerable for
version: 1
---

**A data engineer is answerable for outcomes, and the tools are how they get there.** Job adverts
read like inventories of software, so the common picture of the job is a list of products to learn.
The products change every few years. What somebody is called at three in the morning to fix has not
changed, and it is the better description of the work.

Lesson 1 left Davi checking every morning that yesterday arrived. Here is the whole of what he and
Ana answer for at Roda Livre:

| what the job owns | at Roda Livre | what it looks like when nobody owns it |
|---|---|---|
| **pipelines** | the nightly copies of rides, dock readings and payments | a script on somebody's laptop that stops when they go on holiday |
| **data contracts** | an agreement with the app team about the rides export | a column renamed on a Tuesday, found by a report on Wednesday |
| **freshness** | rides less than two hours old when Marta looks at 09:00 | Friday's numbers read on Monday, by somebody who thinks they are Sunday's |
| **privacy** | customers' names, phone numbers and the station near their home | a phone number in a table every analyst can read |
| **cost** | the monthly bill for storage, queries and servers | a dashboard re-reading a year of data every five minutes |
| **on-call** | somebody who hears when the hourly rides export fails | the failure found at eleven by the person who needed the number |
| **documentation** | what each table means, where it comes from, whom to ask | one person who knows, and everybody else asking them |

Four of the rows deserve more than a line.

## A contract is an agreement about change

**A data contract is a written agreement between the team that produces data and the team that
reads it**: which fields exist, what each one means, what type it has, and how a change will be
announced. Lesson 1's renamed column broke because the app team had no reason to know that a
pipeline read `start_station`. With a contract, renaming it is a change somebody announces two weeks
ahead, and the pipeline is ready on the day.

The contract does not stop change; the app has to evolve. It turns a surprise into a date. Lesson 4
comes back to it, with the questions to put to the owner of a source.

## Privacy is a legal duty

Roda Livre holds personal data: a name, a phone number, and a trail of rides that says where somebody
lives and works. In Brazil that is governed by the **LGPD**, the Lei Geral de Proteção de Dados
(Law 13.709 of 2018), and enforced by a national authority, the ANPD. Three of its ideas are enough
to recognise here. Personal data may only be processed for a stated purpose with a legal basis. The
person it describes has rights over it, including to know what is held about them. And whoever
processes it must keep it secure.

For the engineer that becomes concrete work: who can read the customers table, how long ride
histories are kept, how a request to delete somebody reaches every copy. Lesson 7 shows collecting
only what a question needs; `data-governance` is the law and its machinery in depth.

## On-call is part of the job

A pipeline that runs every hour can fail at any hour, five in the morning included. **Somebody has to hear about it before the people who
needed the data do**, which means an alert that reaches a phone and a person whose turn it is to
answer. In a team of two that is a rota of two, and it is one of the arguments for choosing tools
that fail rarely and explain themselves when they do. `observability` is the craft of alerts and
incidents.

## Documentation is how the job outlives the person

Davi knows that `rides.minutes` is rounded up and that station `ST05` was closed for two weeks in
August. If that lives only in his head, every question about it waits for him. **A table that
nobody has described gets described again by everybody who reads it**, each slightly differently.
A paragraph per table, a line per column and a name to ask is enough to start, and the decision
record later in this lesson is the same idea applied to choices rather than tables.
