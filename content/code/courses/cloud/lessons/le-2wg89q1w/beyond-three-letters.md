---
title: "FaaS, CaaS, DBaaS: more points on the same line"
version: 1
---

Read about cloud services for an hour and you will meet a dozen more names ending in *as a service*.
The wrong conclusion is that each one is a new category to learn. **Each is a point on the line you
already have**, and the name says where the point is: it names what you hand over.

**Containers as a service**, CaaS, takes a container image: your application packaged together with
its runtime and the libraries it needs, a format the `docker` course builds. The platform runs the
image on machines it manages. That puts the line *below* where PaaS put it. The host's operating
system is the provider's, but the runtime is inside your image, so when the language gets a security
fix, rebuilding the image with it is your job again. Managed Kubernetes services and services that run
a single container on request are both here.

**Functions as a service**, FaaS, takes a single function: a piece of code that receives one event, a
request or a file arriving, and returns. The platform starts it when an event comes, runs as many
copies as there are events, and runs none at all when nothing is happening. You pay per invocation and
per GB-second, the two Lambda lines in the capture at the start of this lesson. The line sits a little
above PaaS, because there is not even a running process of yours to manage. Lesson 8 is about it,
under the name it is usually sold by, *serverless*.

**Database as a service**, DBaaS, is a database engine the provider installs, patches, replicates and
backs up on a schedule you set. Amazon RDS, Google Cloud SQL and Azure SQL Database are examples. The
line sits in the middle of the database: the engine is theirs, and **the schema, the queries, the
indexes, the users and the data are yours**. A slow query is still slow on a managed database, and it
is still you who has to find out why.

## Two questions for any name

New names keep arriving: storage as a service, identity as a service, backend as a service, desktop as
a service. You do not need a list of them. Ask two questions of any service, and the answers place it:

1. What do I hand over? A machine image, a container, code, a function, a schema, or nothing but
   your data.
2. What is still mine afterwards? Everything above the thing you handed over, and always the top
   two rows.

A managed database answered that way: I hand over a schema and my data; the engine, its patches and its
disks are theirs; my queries, my users and my data stay mine. That is a complete description of the
service, in the one vocabulary this course uses, and it would be the same on any of the three large
providers.
