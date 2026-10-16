---
title: Choosing between them
version: 1
---

A team rarely chooses a BI tool on features, because every one of them draws a bar chart. The
questions that decide it are about people, money and where definitions will live.

| question | points towards |
|---|---|
| Will most readers build their own questions, without SQL? | Metabase, Tableau, Power BI |
| Must every definition be reviewed like code before anybody sees it? | Looker, or views in the database whatever the tool |
| Is there no budget for licences? | Metabase run yourself, Streamlit |
| Does the page need something no BI tool draws — a simulation, a form, a custom chart? | Streamlit |
| Does the company already pay for Microsoft 365 or Google Cloud? | Power BI or Looker, which are sold alongside them |
| Will the people who build it leave in a year? | the tool whose definitions live somewhere a successor can read |

The last row is the one teams forget. A Streamlit app is as maintainable as its code; a Metabase full
of personal collections is as maintainable as its owners' memories; a Tableau server with a hundred
workbooks, each with its own calculated fields, is a hundred places to look.

**Whatever the tool, the definitions that matter belong below it**, in the database, where lesson 3 put
them. Lantern's net revenue reached the same R$ 1,046,756.40 through `psql`, Metabase and Streamlit in
this lesson, and would through Power BI's files from lesson 4, because none of the four tools was
allowed to decide what net revenue means. A company can then change its BI tool — and most change it
more than once — without changing a single number.
