---
title: Six skills, and the one that is not technical
version: 1
---

**The skills that last are few, and they are older than any tool on a job advert.** A beginner looking
at the field sees forty product names and concludes that the first job needs all of them. It needs
the six below, at a working level, and the rest is learnt on the job, one tool at a time, because each
of them is built on these.

| skill | what it is for in this work | where this catalogue teaches it |
|---|---|---|
| **SQL** | asking a database a question, and reshaping tables inside it | `sql-databases` |
| **Python** | everything SQL cannot reach: calling an API, reading a file, checking a delivery | `python`, which this course assumes |
| **Linux and the shell** | where pipelines run, where their logs are, how files move | `linux-terminal` |
| **git** | a pipeline is code, and code needs history and review | `git` |
| **the cloud** | where the storage and the managed services are, and what they bill | `cloud` |
| **modelling** | shaping tables so that questions are easy to ask and numbers agree | `warehouse-modeling` |

Notice what is absent. There is no particular warehouse, no particular scheduler, no particular
stream processor. Each of those is a product that does one of the six jobs above in its own way, and
learning one after the six is a matter of weeks. Learning one *instead* of them leaves somebody who
can drive a tool and cannot tell when it is giving a wrong answer.

## The seventh skill: finding out what the question is

**Most expensive mistakes in data engineering are correct answers to the wrong question.** Here is
the shape of one. Marta asks Ana for "a live map of bicycles per station". Taken literally, that is a
stream of dock readings processed as they arrive, which is the most expensive thing in lesson 8.

Ana asks what Marta will do with it. The answer: a van moves bicycles between stations twice a day,
leaving at 09:30 and at 16:00, and the driver needs to know where to take them. So what Marta needs is
a picture of each station **shortly before each van run**, and a forecast of which ones will run dry
before the next. That is a batch job twice a day, reading data no more than an hour or two old.
Nobody has to be paged at night when a stream stops.

Three questions do most of the work, and none of them is technical:

- **What will you do differently when you have the answer?** If nothing, the request is curiosity,
  and it can wait.
- **When do you need it, and how old may it be?** "Live" means different things to different people,
  and the honest answer is usually a time of day.
- **What would make you distrust it?** The answer names the checks the pipeline needs, before the day
  somebody distrusts it.

The questions change the architecture before any tool is chosen, which is why they come first in the
criteria two sections on.
