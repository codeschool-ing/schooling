---
title: Job titles, and the work behind them
version: 1
---

If the four roles were as tidy in job adverts as they are in the last two sections, choosing a job
would be easy. **They are not: the same title means different work in different companies, and the
same work is advertised under different titles.** The title is a hint. The verbs in the advert are
the evidence.

## Why titles drift

A company names a job after what it needs and what it can pay, and the market's words change faster
than either. A small company that wants one person to do everything with data calls the job "data
analyst" because that is the title candidates search for. A large bank may split the same work into
three teams with three titles. "BI analyst" and "data analyst" are used interchangeably in many
adverts, and in some companies "data scientist" means somebody who writes reports with more
statistics in them.

## Lívia's job, honestly described

Lívia's contract says "BI analyst". In her first two months she wrote definitions and built the
Monday sales email, which is BI. She explored the October drop and the returning customers, which is
a data analyst's work. And twice she fixed a broken pipeline herself on a Friday afternoon because
Tiago works three days a week, which is engineering. **At a company of Varanda's size, one analyst
does three of the four jobs**, and that is normal rather than a failure of planning. What matters is
that she knows which hat she is wearing, because each one is done to a different standard: an
exploration can be rough, a monthly number cannot.

## Reading an advert by its verbs

Ignore the title for a moment and underline what the job asks you to do. The verbs sort it.

| verbs in the advert | the role it describes |
|---|---|
| build, maintain and monitor pipelines; ingest; model the warehouse | data engineer |
| define KPIs; build and maintain dashboards and recurring reports; work with stakeholders on requirements | BI analyst |
| investigate; explore; answer ad hoc questions; present findings | data analyst |
| train, validate and deploy models; predict; experiment | data scientist |

An advert titled "data analyst" whose list is mostly *build dashboards, define KPIs, gather
requirements* is a BI job. One titled "BI analyst" that asks for *pipelines, orchestration, data
modelling* is mostly engineering with a BI title. **Neither is a trick; it is the company describing
its problem in the market's words**, and the verbs tell you which problem you would be hired to solve.
The `first-job` course goes through job searching as a whole.

## A newer title: the analytics engineer

One title has spread in the last decade and sits between two of the four. **The analytics engineer
takes the data the engineer has delivered and turns it into clean, tested, documented tables that
analysts and dashboards read from** — the place where "a sale" or "a returning customer" is defined
once, in code, for every report at the same time. It grew with tools that let analysts write those
transformations as versioned code with tests, of which dbt is the best known.

At Varanda there is nobody with the title, and the work is shared: Tiago builds the tables, Lívia
writes the definitions they implement. When a company finds that every dashboard computes revenue a
little differently, the analytics engineer is usually the role it is missing. `warehouse-modeling`
lesson 2 covers the kind of table that work produces.

## What this means for the rest of the course

This course follows a BI analyst because the questions in it — which number, defined how, shown to
whom — belong to that role. **Most of it is useful to the other three as well**, for a plain reason:
every one of them hands work to somebody, and the next section is about what goes wrong at those
handoffs.
