---
title: Catalogue tools
version: 1
---

Ana's dictionary is a SQL file, a CSV and two short programs, and for one warehouse that is enough. A company with
hundreds of databases, lakes and dashboards needs the same thing as a service, and that service is a **data
catalogue**. What the products do is recognisably this lesson, at scale:

- **Harvest metadata** automatically from every source they can connect to: tables, columns, types, comments, sizes,
  the last time each was written. Nobody types the inventory.
- **Search** across all of it, so "where is revenue?" has an answer that is not a person's name.
- **Ownership**: who answers for each dataset, the data product's owner of lesson 11.
- **A business glossary**, linked to the columns that implement each term.
- **Lineage**, harvested from queries and pipelines, drawn as a graph.
- **Classification and access**: which columns are personal, and who may read them, sometimes enforced rather than
  only recorded.

Open-source catalogues include DataHub, which began at LinkedIn, OpenMetadata, and Amundsen, which began at Lyft. Each
cloud has its own as well: AWS Glue Data Catalog, Google's Dataplex, Microsoft Purview, and Databricks' Unity Catalog,
which Databricks made open source in 2024.

One word, two jobs, worth keeping apart. **A catalogue in this lesson's sense is for people**: search, meaning,
ownership. **A catalogue in lesson 10's sense is for engines**: the service that holds the pointer to each Iceberg or
Delta table's current metadata, so that a commit is atomic. Some products, Unity Catalog and Glue among them, do both,
which is convenient and is also why the word confuses.

A tool does not write descriptions. **A catalogue full of harvested tables with no meaning attached is an inventory, not
a dictionary**, and searching it returns the column names you could have listed yourself. The work of this lesson,
deciding and writing what each column means, is the part every tool assumes somebody has done.
