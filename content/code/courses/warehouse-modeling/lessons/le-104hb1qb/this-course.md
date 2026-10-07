---
title: What this course builds, and for whom
version: 2
---

Most databases you have met so far were designed to **record** things: an order, a payment, a
change of address. This course is about a second kind of database, designed to **answer** things:
how much each department sold this year against last, which customers stopped buying after they
moved, whether a promotion brought new readers or only discounted the old ones. The data is the
same. The design is almost the opposite, and the twelve lessons are the reasons why.

## One company, all the way through

Every query in the course runs against the same business. **Ponto Final** is a chain of bookshops
that does not exist: six shops in São Paulo, Campinas, Belo Horizonte, Curitiba and Porto Alegre,
and a website that ships anywhere in Brazil. Its tills and its website write to one PostgreSQL
database, and that database holds two years of trade, from January 2024 to December 2025. Ana is
the shop's data analyst, and every lesson is a step in Ana's project: a warehouse built out of that
database.

The numbers are invented, by a program that draws them from fixed seeds, so they come out the same
on every machine. Everything done with them is real: every query was run, and every line of output
in a lesson is what the database printed.

## What each lesson adds

| lesson | what Ana builds or measures |
|---|---|
| 1 | the two workloads, measured on the shop's own database |
| 2 | the first fact table and its dimensions |
| 3 | the same model as a star and as a snowflake |
| 4 | the grain, the keys, and a table for books with several authors |
| 5 | customers who move and change tier, kept with their history |
| 6 | what normalising and denormalising each cost, in bytes and in joins |
| 7 | what happens when one machine is not enough |
| 8 | why the warehouse stores columns rather than rows |
| 9 | the same model on BigQuery, Snowflake and Redshift |
| 10 | files on a lake, and the table format that makes them a table |
| 11 | marts, data mesh and pipelines generated from metadata |
| 12 | the dictionary that says what every column means |

## Who is reading

::: track bi
You arrive from `analytics-bi`, where you built reports on top of tables somebody else had shaped.
This course is how those tables are shaped. By the end you can read a model and say whether a
number on a dashboard can be trusted, and `pipelines-etl` comes next to keep it loaded.
:::

::: track data
You arrive as an engineer who can write SQL and Python. This course is the design you will be
loading: `pipelines-etl` comes next and is defined by what it loads into, which is why the model
comes first.
:::

::: track software-architecture
You may never build a warehouse yourself. You will sit in the meeting where somebody proposes
one, or proposes running reports on the production database instead, and this course gives you
the vocabulary and the measurements to argue either side. Lessons 1, 6, 7 and 11 are the ones that
decision rests on.
:::

::: track *
You need SQL: tables, keys, joins and normalisation, which is what `sql-databases` teaches. Half
of this course argues with that last one, so it helps to have it fresh.
:::

**Nothing here needs a programming language beyond SQL.** A few lessons use a short shell script
or a few lines of Python to move files around; they are shown whole, and you can read them as
recipes. The longest is the program in section 05 that writes the shop's data, and that one you
only have to run.
