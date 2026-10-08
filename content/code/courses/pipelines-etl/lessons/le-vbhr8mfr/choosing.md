---
title: Choosing, and what outlasts the choice
version: 1
---

A team rarely chooses an orchestrator from a table. It inherits one, or the platform it runs on
offers one, or somebody already knows one. Still, the lab suggests where each fits:

- **Airflow** when there are many pipelines on schedules, owned by several people, and the value is
  in one place that runs them all, retries them and says what failed — and when the managed versions
  every cloud sells are an option. Its cost is the machinery: four processes in the lab, a metadata
  database, and DAG files that must stay cheap to parse.
- **Luigi** for batch jobs that produce files, where *the file exists* really does mean *the job is
  done*. It is small and has few moving parts. It is also the least actively developed of the four,
  and its notion of done fits a database poorly, as the markers showed.
- **Prefect** when the pipeline is mostly Python and its shape is decided while it runs — a loop
  over whatever the API returned, a branch on a result. Nothing else here makes that as plain.
- **Dagster** when the important thing is the data, and the questions are *what is out of date and
  what does it feed* — which is close to what dbt asks inside the warehouse, and why the two are
  often used together.

What outlasts the choice is the four questions of the last section, and three habits the course has
built regardless of tool. **Every step safe to run twice**, because every one of these tools will,
sooner or later, run a step twice. **Every rule about the data checked by a machine**, because none
of them knows whether the numbers are right. **And the day to load taken from the run, never from the
clock**, because every one of them can rerun yesterday. A pipeline written that way moves from one
orchestrator to another as a change of wrapping, which is exactly what this lesson did three times.
