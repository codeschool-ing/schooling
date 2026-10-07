---
title: What this course does, and to which data
version: 1
---

**Cleaning is the part of an analysis that decides whether the rest of it is true.** A chart, a
model or a dashboard is a calculation over rows, and none of them can tell a real row from a
repeated one, a price from a typing slip, or an empty cell that means zero from one that means
nobody asked. You can. This course is about doing it on purpose, in an order, and with a record
of every decision.

It is not a course of tricks. Each lesson takes one kind of defect, shows where it comes from,
how to find it, what the honest choices are, and what each choice costs. The code is short. The
judgement is the subject.

## The company, and the question

Every lesson works on the same data: the systems of **Quitanda Verde**, an organic grocer that does
not exist. It has five shops — Pinheiros in São Paulo, Cambuí in Campinas, Botafogo in Rio de
Janeiro, Savassi in Belo Horizonte and Batel in Curitiba — and a website and an app that deliver.

In the first week of January 2026 its analyst, Ana, is handed what those systems export and asked
one question: **can the 2025 numbers be trusted?** The files are what such systems really
produce. The website writes dates one way, the app another and the shops' old till a third. The
customer file was exported on a different day from the orders. Some people signed up twice. A
blank in one column means zero and a blank in the next means the timer gave up.

None of that was found by accident. The generator you run in this lesson plants each defect on
purpose and writes down where it put it. So a lesson can say **how many of the real duplicates a
technique found**, a question real work almost never lets you answer.

## How a lesson runs

Each lesson does its work twice, in **SQL on PostgreSQL and in pandas**, because those are the two
places this work happens in practice and because each one makes a different mistake easy. Lesson 16
adds Excel and R's dplyr to the comparison and says which one to reach for when.

::: track bi
You arrive here from `excel-analytics`, where lessons 13 and 14 did much of this in Power Query,
and from `sql-databases`. The SQL half of every lesson is written for you, and every exercise can
be answered from it. The pandas half is shown beside it so you can read it; Python itself arrives
later in your track, with `python`, and this course is a good reason to take it seriously.
:::

::: track data-science
You arrive here from `python-data`, where lessons 9 to 15 taught the pandas this course uses, and
from `sql-databases`. Here pandas is the tool and the subject is the judgement behind each call.
The SQL beside it is there because a good share of real cleaning happens before the data ever
leaves the database, and because a colleague will ask you to do it there.
:::

::: track *
The SQL half of every lesson stands on its own, and so does the pandas half: read the one you
know, and use the other as a translation.
:::

Every command shown was run, in the lab described in the next section, and its output is pasted
as it came out. Where something could not be run here, the lesson says so.

## The order of the lessons

| lessons | what they do |
|---|---|
| 1–2 | measure the data and profile it before touching anything |
| 3–4 | missing values: why they are missing, then what to do about it |
| 5 | duplicates, exact and approximate |
| 6–8 | text, formats and categories brought to one spelling |
| 9 | outliers: a typo, a real event or a fraud |
| 10–11 | types converted safely, and tables joined without losing or multiplying rows |
| 12–14 | transformations, reshaping and enrichment from outside sources |
| 15 | exploratory analysis as the last check before the data is handed on |
| 16–17 | the tools compared, and how to make the whole thing repeatable |

**What it leaves to other courses.** Running cleaning on a schedule inside a pipeline is
`pipelines-etl`, whose lesson 16 turns the checks of this course into tests that stop a load.
Deciding who owns a column and who may change it is `data-governance`, lesson 9. Drawing the
cleaned data is `visualization`, which comes straight after this course in both tracks.
