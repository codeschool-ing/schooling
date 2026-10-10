---
title: Where the job came from
version: 1
---

**The title is young and the work is old.** Companies have moved data from where it is made to where
it is read for as long as they have had more than one system. What changed, three times, is how much
data there was and who did the moving — and each change left a word behind that you will meet in job
adverts and in the courses after this one.

## Three eras, and the word each one left

**The warehouse and ETL, from the 1990s.** A company's operational systems — sales, stock, payroll —
were copied every night into one **data warehouse**, a database designed for reading and summing
rather than for taking orders. The copying was called **ETL**: *extract* from the source, *transform*
into the warehouse's shape, *load*. The people who did it were ETL developers and database
administrators, working in tools that drew the flow as boxes and arrows. The warehouse is still the
centre of most data platforms; `warehouse-modeling` is how one is designed.

**Big data, from the late 2000s.** Web companies had more data than one machine could hold — every
click, every search — and most of it was not tables. Google published how it spread storage and
computation across thousands of cheap machines, and Hadoop copied the idea in the open. Data now
lived in files across a cluster, and processing it meant writing programs, not drawing boxes. That is
when **"data engineer"** became a common title: the work had become software engineering. Lesson 9 is
what spreading data over many machines involves, and why it is hard.

**The cloud, from the mid-2010s.** Warehouses that scale on demand, storage that costs cents per
gigabyte per month, and queues and stream processors as services. Two things followed. Loading raw
data first and transforming it inside the warehouse became cheaper than transforming it on the way —
**ELT** instead of ETL, which lesson 3 compares. And the hard part moved from *can we store it* to *can
we trust it, afford it and find it*, which is lessons 2 and 7.

## What stayed

Each era added tools and kept the problem. A nightly job in 1998 and a stream processor in 2025 both
have to answer the same questions: did all of it arrive, did any of it arrive twice, is it what the
source meant, and is it here in time. **The tools in a job advert change every few years; those four
questions have not changed in thirty**, which is why this course spends its hours on them.

It is also why a data engineer is expected to have a software engineer's habits — version control,
tests, code review, automation — and not only a database person's. `git`, which the `data` track
puts before this course, is the first of those habits; `pipelines-etl` puts tests around a pipeline.
