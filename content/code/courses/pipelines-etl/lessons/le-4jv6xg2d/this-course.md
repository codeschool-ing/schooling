---
title: What this course is for
version: 1
---

In `warehouse-modeling` Ana designed a warehouse for Ponto Final: a star schema of sales, a
customer dimension that remembers where people used to live, and a calendar. **Every row in it
got there because she ran a command.** She exported the shop's tables, ran the SQL files in order
and checked the totals by eye. That works once. It does not work every night for three years,
while the tills keep selling and somebody upstream renames a column.

This course is the other half of the job: **moving data from where it is written to where it is
read, on a schedule, without a person, and knowing when it went wrong.** The programs that do it
are called pipelines, and the profession that writes them is mostly about what happens when they
fail.

## The shape of the course

The nineteen lessons fall into five groups:

| lessons | what they cover |
|---|---|
| 1–3 | the kinds of ingestion, ETL against ELT, and the four kinds of source |
| 4–7 | extracting, transforming and loading, one step each, by hand in Python and SQL |
| 8–14 | the tools that run those steps: Airflow, dbt, and a look at Luigi, Prefect and Dagster |
| 15–17 | idempotency, data quality and testing — the reasons a pipeline can be trusted |
| 18–19 | versions and environments, and what a large load costs |

The order is deliberate. **You will write every step by hand before a tool does it for you**,
because a scheduler only runs what you give it, and a badly written step scheduled every night
is still badly written. When Airflow arrives in lesson 8 it will be running code you already
understand.

## What it assumes

`warehouse-modeling`, because a pipeline is defined by what it loads into: facts, dimensions, a
grain, a slowly changing dimension. When lesson 7 loads a type 2 dimension it will not stop to
explain what one is. You also need enough SQL to read a join and a `GROUP BY`, and enough Python
to read a loop and a function — the orchestrators are configured in Python.

## What it leaves ready

Orchestration and data quality, for `ml-mlops`: a model trained on data nobody checked, by a job
nobody schedules, is the same problem with a higher price.
