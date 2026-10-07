---
title: One job, three tools
version: 1
---

Airflow is the orchestrator this course has used since lesson 8, and it is the most common one.
It is not the only one. Three others turn up often enough that a data engineer will meet them:
**Luigi**, which came out of Spotify in 2012 and is the oldest of the four; **Prefect**, which
began as a reaction to Airflow's way of writing pipelines; and **Dagster**, which puts the data a
pipeline produces, rather than the steps it takes, at the centre.

A fair comparison is the same job in each. Ana's is the nightly she already has, cut down to three
steps:

1. Load raw: `python load_raw.py`, as since lesson 6;
2. Build the models: `dbt build`, which builds and tests the project of lessons 11 and 12;
3. Write the report: one day of `daily_sales` as a CSV file in `reports/`, for the managers.

Each step is the same command in every tool, run with `subprocess`. Only what surrounds the
commands changes — how a step is declared, how the order is said, what counts as done, and what is
remembered afterwards. Those four differences are the lesson.

Each tool is installed in its own virtual environment, because each pins its own versions of the
same libraries; the lab's header explains the arrangement. And these tools change fast. The versions
here are the lab's, the names of things may differ in the next major release, and one or another
of the three may not be maintained by the time this is read. **The questions in the last sections
outlive the tools**, which is why the lesson ends with them.
