---
title: How this lesson runs
version: 1
---

Lesson 4 drew five shapes for the box office's data. This lesson runs **one real database of each
family**, puts a little of the box office's data in it, asks it the question it is good at, and
then asks it one it is bad at, so that the trade of each family is something you watched happen.

The five, with what each is in this lesson:

| database | family | the question it gets |
|---|---|---|
| MongoDB 8.0 | document | the page of a show, and every show at one venue |
| DynamoDB (Local) | key-value and document | one buyer's tickets for one show |
| Cassandra 5.0 | wide column | the latest scans at the door of one show |
| Neo4j 5.26 | graph | the shows that a show's buyers also went to |
| InfluxDB 2.9 | time series | tickets sold per hour, per channel |

## One at a time

Each database runs in a container of its own, started at the beginning of its section and **removed
at the end of it** with `docker rm -f`. None of them needs the box office, and none of them keeps
anything you will need later. Running them one at a time is what makes the lab of lesson 1 enough:
Cassandra and Neo4j are Java programs that size their memory from the machine they find, so each
command below gives them a limit with `--memory`, and Cassandra is also told how big its heap may
be. Together, all five would want more memory than an 8 GB lab should give; one at a time, the
largest takes about a gigabyte.

The images add up to about 4 GB of disk. They stay after their containers are removed, so a section
can be run again without downloading; `docker image rm` with the image's name frees the space when
you are done with the lesson.

## The files

Each database gets its data from a small file you create in `~/tickets`, shown in full in its
section, and copied into the container with `docker cp` before it runs. They are short on purpose:
a hundred shows, five tickets, six scans, ten shows and sixty buyers, three hours of sales. **The
point is the shape of each question, not the volume**, and every number printed comes from data
you can read in one screen.

## About DynamoDB

DynamoDB is a service that exists only in Amazon's cloud. What runs here is **DynamoDB Local**, a
program Amazon publishes for developing and testing against the same interface on your own
machine. It accepts the same requests and returns the same answers, and it is not the service:
it has no partitions spread across machines, no throttling, and no bill. Section 06 says which
parts of what you see would be different in the real thing.
