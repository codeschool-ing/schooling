---
title: The others
version: 1
---

Three products are not the whole market, and several others are worth recognising by name, each because it
answers one of this course's questions differently.

- **Databricks SQL** runs SQL warehouses over tables stored in an open format, Delta Lake, in your own object
  storage. It is the bridge between this lesson and lesson 10, which takes the open format apart.
- **Azure Synapse Analytics** and **Microsoft Fabric** are Microsoft's: Synapse's dedicated pools are a
  shared-nothing MPP warehouse with distribution choices much like Redshift's, and Fabric puts warehouse and
  lake behind one product with open-format storage.
- **ClickHouse** is an open-source columnar database built for very fast aggregation over very large tables,
  often of events and logs. It can be run on your own machines or rented.
- **DuckDB**, the engine of this course, runs inside a single process on one machine and reads Parquet from
  anywhere. **MotherDuck** is a managed service built around it. For the many warehouses that fit in one
  machine's memory, lesson 7's rule of thumb, it is an honest alternative to renting a cluster.
- **PostgreSQL** itself, with extensions that add columnar storage or distribute tables across nodes, is
  used as a warehouse by teams that want one database technology rather than two.

None of these was evaluated in this course beyond DuckDB, which ran every query in it. They are named so that
a reader meeting one in a job description can place it: **a columnar engine, a place where the data lives,
and a way of paying for the compute**, which is what all of them are.
