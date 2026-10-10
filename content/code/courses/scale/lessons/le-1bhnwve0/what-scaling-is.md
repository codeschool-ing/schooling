---
title: What it means for a system to scale
version: 1
---

**A system scales when the next unit of load costs about what the last one did.** It is a claim
about cost, not about speed. A box office that sells a hundred tickets a second on one machine and
two hundred on two machines scales; one that sells a hundred on one machine and a hundred and ten
on four does not, however fast each sale is.

The common picture is a different one: that a scalable system is a fast one, or one built with
the right technology. Neither is true. A program can answer in a millisecond and still fall over
at the first thousand users, and the same database runs systems that scale and systems that do
not. What decides is **where the work waits when there is more of it**, and that is a property of
the design, measured rather than chosen.

## Two numbers

Everything in this course comes back to two measurements:

- **Throughput** is how much work finishes per unit of time: requests per second, tickets sold per
  minute, rows written per hour.
- **Latency** is how long one piece of work takes from the moment it is asked for to the moment it
  is answered.

They are not two views of one quantity. One cashier who takes a minute per customer serves sixty
an hour; ten cashiers who take a minute each serve six hundred, and each customer still waits a
minute. **Adding capacity raises throughput and leaves latency alone, until something is shared.**
When the ten cashiers share one card machine, the queue for the machine is what every customer
waits in, and adding an eleventh cashier adds nothing.

That shared thing is the **bottleneck**: the one resource that is fully busy while the others
wait for it. A system has one at any moment, and only one, because it is by definition the
narrowest point. Making anything else faster changes nothing you can measure. Making the
bottleneck faster moves it somewhere else, and finding the next one is most of the work.

## The two directions

There are two ways to give a system more capacity, and they are the subject of this lesson:

- **Vertical scaling**, or scaling up: a bigger machine. More processors, more memory, faster
  disks, for the same program.
- **Horizontal scaling**, or scaling out: more machines, or more copies of the program, with the
  work divided between them.

Vertical scaling asks nothing of the program and runs out at the size of the largest machine
anybody sells. Horizontal scaling has no such ceiling and asks a great deal of the program: the
copies have to be able to divide the work without asking each other about it. Sections 07 and 08
measure both on the same box office, and section 09 finds the work that cannot be divided at all.

## What this course is not

`architecture` gave the patterns their names: replication and sharding in its lesson 10, the
circuit breaker in lesson 11, back pressure in lesson 12. This course **measures the limits that
force them**. Each lesson runs something on your own machine, pushes it until it stops keeping up,
and reads what it says when it does. That is also the second half of the course's title:
**observability** is being able to answer, from the outside, what a running system is doing and
why. Lessons 7 and 8 build that; every other lesson uses it.
