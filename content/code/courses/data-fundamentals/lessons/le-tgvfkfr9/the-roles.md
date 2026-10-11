---
title: Five jobs with "data" in the name
version: 1
---

**The common picture is a ladder: an analyst becomes a data scientist, and a data engineer is a data
scientist who writes more code.** It is wrong in both halves. The jobs are not rungs, they are
different answers to *what do you deliver*, and a person moves between them sideways.

## What each one delivers

| role | what they deliver | who reads it | what goes wrong when it is missing |
|---|---|---|---|
| **data engineer** | data that arrives, on time, correct, in a shape that can be queried | the other four, and the systems they build | every analysis starts with a week of copying files by hand |
| **analytics engineer** | the tables and definitions the business agrees on: what a "ride" or an "active customer" is | analysts and dashboards | two dashboards give two numbers for the same thing |
| **data analyst** | answers to questions that have been asked: a number, a chart, a recommendation | managers, operations, finance | decisions are made on the loudest opinion |
| **data scientist** | models and experiments: a prediction, an estimate of what caused what | product and operations | nobody can say whether the new pricing worked |
| **machine learning engineer** | a model running in production, fed and monitored | the application | the model works in a notebook and nowhere else |

Two of the five deserve a second look, because their names mislead.

**The analytics engineer** sits between the first and the third: someone who writes SQL with the
habits of a software engineer, versioned and tested, so the business's definitions live in one
place. The title is about ten years old and many companies give the work to whichever of the other
two has time. `warehouse-modeling` is most of that job.

**The machine learning engineer** is a software engineer whose product happens to contain a model.
The data scientist decides *what* the model should predict and proves it does; the ML engineer makes
it answer in fifty milliseconds, every time, and notices when its predictions drift.

## Where the data engineer is different

The others answer questions. **The data engineer builds the thing the questions are asked of**, and
that changes the shape of the work in three ways:

- **It is software, and it runs every day.** An analysis is finished when it is delivered. A pipeline
  is never finished: it runs tonight, and tomorrow night, against a source that changed its format
  without telling anyone.
- **Its users are mostly other systems and other data people.** Marta never sees Davi's work, only its
  absence.
- **Its failures are quiet.** A wrong chart is wrong where somebody can see it. A pipeline that loads
  yesterday's file twice produces a chart that looks perfectly fine, and doubles every number on it.

## The overlaps are real

In a company the size of Roda Livre, two people do all five jobs. Davi writes the pipelines and also
the SQL that defines a ride; Caio trains a model and also deploys it. **The roles are a way of naming
the work, not a way of dividing people**, and a job advert that asks for all five at once is asking
for a small team, by mistake or on purpose.

What does not overlap is the question each role starts from. The analyst asks *what happened*. The
data scientist asks *what will happen, and why*. The data engineer asks **will the data be there, be
right, and be on time, tomorrow and every day after** — and that is the question the rest of this
course is about.
