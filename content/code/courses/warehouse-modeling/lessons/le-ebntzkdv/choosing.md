---
title: Choosing one
version: 1
---

The choice between warehouses is rarely decided by benchmarks. Published benchmarks are run by vendors on
workloads that suit them, and at the size of most companies all of these products answer in seconds. What
decides it is usually a short list of questions, roughly in this order:

1. **Where is the data already?** Moving terabytes between clouds costs money for every gigabyte that leaves,
   and time. A company on AWS tends towards Redshift or Snowflake on AWS; one on Google Cloud towards BigQuery.
2. **What shape is the workload?** Many small, unpredictable queries from many people suit paying per query
   or per second with fast scaling; a steady, heavy load that runs all day suits reserved capacity, paid by the
   hour, which costs less per unit when it is used.
3. **How much operation does the team want?** BigQuery asks for almost none; Snowflake asks for warehouses to
   be sized and suspended; provisioned Redshift asks for nodes, keys and maintenance.
4. **What will the bill look like when somebody makes a mistake?** On demand, a careless `SELECT *` over a large
   table is a large bill on its own; by the second, a warehouse left running is. Every product has limits and
   alerts, and lesson 10 of `cloud`, on budgets, applies here directly.
5. **What does the rest of the stack speak?** The report tools, the pipelines and the people's skills.

**And the honest first question, from lesson 7: does it need to be rented at all?** Ana's warehouse is a 46 MB
file that answers every question in this course in milliseconds on a four-core machine. A shop of this size can
run DuckDB or PostgreSQL for years before any of these products is worth its bill, and a design built on the
dimensional model of lessons 2 to 6 will move to whichever one it eventually needs.
