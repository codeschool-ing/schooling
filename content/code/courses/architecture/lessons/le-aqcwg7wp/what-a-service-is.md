---
title: What makes something a service
version: 1
---

The size is the common misreading: a microservice is taken to be a small program, and splitting a
system into many small programs is taken to be the architecture. **What defines a service is
independence**, and a large program can have it while a small one does not.

James Lewis and Martin Fowler wrote the description most people cite, in 2014. Read for what a
service must be able to do, it comes to four properties:

| property | what it means in practice |
| --- | --- |
| **independently deployable** | a new version goes out without any other service being rebuilt, redeployed or even told |
| **organised around a business capability** | it does one thing the business would recognise, such as stock, payments or delivery, rather than one technical layer such as "the database layer" |
| **owns its data** | its tables are its own, and no other service reads them; other services ask it |
| **smart endpoints, dumb pipes** | the logic is in the services; what joins them, HTTP or a queue, carries messages and makes no decisions |

The first is the one the rest serve. **If two services always have to be deployed together, they
are one service with a network in the middle**, and this lesson's last section has a name for that.

## Where the word came from, briefly

Splitting systems into networked components is far older than the word. Lesson 3 covers
service-oriented architecture, which did much of it in the 2000s with heavier machinery. What the
2010s added was cheap automation: containers, deployment pipelines and cloud machines made it
affordable to run dozens of small deployable units, and the companies that did it publicly, Netflix
and Amazon among them, described the result. The cost of running each unit fell; the cost of the
network between them did not.

## What it buys

Each property buys something specific, and each has a price that the rest of the lesson measures:

| it buys | and pays with |
| --- | --- |
| teams that release without waiting for each other | a network call wherever a function call used to be |
| scaling one part with its own number of copies | a second database, and no transaction across the two |
| a fault in one service that does not kill the others | new kinds of fault: the other service slow, gone, or half done |
| each service in the language and version it needs | one more pipeline, image, dashboard and alert per service |

Quitanda has one force from lesson 1 that is strong enough: suppose the stock team, two people who
also run the warehouse, wants to release on its own schedule, several times a day, without waiting
for the shop's release. That is the force. The next two sections draw the boundary and move the
stock out.
