---
title: What this course is, and the shop it studies
version: 1
---

Every company that keeps data ends up with somebody who is asked a question in a corridor — how
many customers did we lose last month? — and has to answer it with a number that two other
people will check against their own. This course is about that end of the data: **the part the
business actually reads**. The pipelines have run, the tables exist, and now a person needs to
decide something.

It covers four jobs, in this order:

| lessons | the job |
|---|---|
| 1 to 3 | knowing the data, agreeing what each number means, and writing those meanings down once, in SQL, where every tool reads them |
| 4 to 6 | putting the numbers in front of people: Power BI, four other tools, and what makes a dashboard readable |
| 7 and 8 | **reverse ETL**: sending computed numbers back into the tools where people work, so a salesperson sees a score without opening a dashboard |
| 9 and 10 | the analyses a business asks for most — segments, cohorts and funnels — and the ways a true number can still mislead |

## Lantern Coffee

Every lesson works on one company. **Lantern Coffee** is a small roastery in São Paulo that sells
beans, ground coffee and brewing equipment through its own website, to people at home and to a
few offices. It opened its online shop on 1 January 2025, and its data runs to 17 June 2026,
the evening of the last extract.

The shop is invented and its data is generated, by a script you will paste into your own
database in this lesson. That script is written so that it produces **the same rows on every
run**: when a lesson says the median order is R$ 95.80, your database says R$ 95.80 too. It also
has the faults real data has, put there on purpose — and finding them is most of this lesson.

## What runs on your machine, and what does not

Three tools in this course are free, open source and run on your own computer, and every
transcript in it was recorded with them:

- **PostgreSQL 16**, the database, from this lesson on;
- **Metabase**, a business intelligence tool you open in a browser, from lesson 3;
- **Streamlit**, a way to turn a short Python file into a web page, in lesson 5.

The others the course names are products somebody sells, and **nothing in this course depends on
a licence or a free trial**. Power BI Desktop runs only on Windows, so lesson 4 shows its
formulas beside the SQL that computes the same numbers, and says plainly which of the two was
run. Tableau and Looker in lesson 5, and Hightouch, Census and Segment in lesson 8, are described
from their own documentation and mapped onto things you build yourself. When a lesson shows
something it could not run, it says so in the sentence above it.

::: track bi
You arrive from `visualization` and `statistics`, and this course leans on both: a median, a
quartile and a correlation are tools you already have, and this lesson uses them on a database
instead of a spreadsheet.
:::

::: track data-platform
You arrive from the platform side, where tables are built, loaded and watched. This course is
where they are read — and it is the best place to see why a column nobody documented, or a load
that silently skipped a day, costs somebody a wrong decision.
:::

::: track *
The course assumes SQL: joins, `GROUP BY` and window functions. Where it uses a statistical idea —
a median, a quartile, a correlation — it explains it in the section that needs it.
:::
