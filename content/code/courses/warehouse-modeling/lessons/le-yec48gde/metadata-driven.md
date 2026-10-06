---
title: Pipelines described as data
version: 1
---

Ana's staging layer has fifteen tables, and lesson 2 wrote fifteen nearly identical statements to load them. A
warehouse with four hundred source tables would have four hundred, and the four hundred and first would be copied
from one of the others, with whatever mistake that one carried.

A **metadata-driven** pipeline turns that round. The tables are described as data, a list with one entry per
source saying what it is called, where it comes from and anything unusual about it, and **one generic program** turns
the list into loads, either by generating the code or by running the loads itself. Adding a source is a line in the
list, not a new program.

The idea is old and appears under several names:

- **Code generation** writes the SQL from the metadata, so the result can be read, reviewed and kept in version control.
  dbt does this with SQL templates configured in YAML, and `pipelines-etl` lessons 11 and 12 use it.
- **A generic loader** reads the metadata at run time and executes the loads directly, with nothing generated in
  between. The copy activities that cloud integration tools build from a control table work this way.
- **Data Vault automation**, from lesson 6: hubs, links and satellites are so regular that whole vaults are generated
  from a description of the business keys.

What it buys is consistency, and that is worth more than the typing it saves. Every staging table is loaded the same
way, with the same options, so a fix to the template is a fix to all of them. What it costs is that **the generator is
now a program the team maintains**, and every exception makes it more complicated: the one source with a different
delimiter, the one table that needs a type forced. The next section generates Ana's staging layer and meets exactly
one such exception.
