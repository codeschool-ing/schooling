---
title: What "non-functional" means
version: 1
---

A functional requirement says **what** the system does: a customer picks a seat and the seat is
booked. A non-functional requirement says **how well** it does it, and under what conditions: the
booking answers within half a second when two hundred people are booking at once, a person who
cannot see the screen can complete it with a screen reader, and nobody can book a seat in another
customer's name. The first kind is a list of behaviours. The second is a list of properties, and a
property holds or fails across every behaviour at once.

The name misleads, and it is worth correcting before anything else. "Non-functional" sounds like
"optional", or like the part of the work that has nothing to do with what the system is for.
**A booking page that takes forty seconds under load is a booking page that does not work**, for
the people who leave before it answers. The properties are as much a part of what was promised as
the behaviours; they are just harder to see in a demonstration, because a demonstration has one
user, on a fast connection, who can see the screen and wishes the system well.

## The properties this course tests

ISO/IEC 25010, the standard most quality models descend from, lists nine characteristics of a
software product. Its 2023 revision names them functional suitability, performance efficiency,
compatibility, interaction capability, reliability, security, maintainability, flexibility and
safety. The first is what your functional tests already cover. This course takes four of the
others, the ones a tester is asked about first and can measure from outside the code:

| | the question | lessons |
|---|---|---|
| **performance** | does it answer in time, at the load it will meet? | 1 to 11 |
| **accessibility** | can everybody use it, including with a keyboard and a screen reader? | 12 to 15 |
| **security** | does it refuse what it should refuse, to somebody trying on purpose? | 16 to 21 |
| **operability** | when it misbehaves in production, does somebody find out first? | 22 to 24 |

Accessibility is part of what the standard calls interaction capability, and operability borrows
from reliability and maintainability. The labels matter less than the shape: four subjects, each
with its own tools and its own way of saying *pass*.

**That last point is the one to hold on to across the whole course.** A functional test has a
grader built in: the seat is booked or it is not. A load test answers with a distribution of
timings, and *pass* depends on a threshold somebody had to write down. An accessibility audit
answers with a list of findings, and a tool can only decide some of them. A security scan answers
with a report in which most entries are not real problems in your system. In each third the hard
part is not running the tool; it is knowing what result would mean *fail*, before you run it.

## Why a tester owns these

Developers measure performance when something is slow, and a security team reviews the parts that
look dangerous. Neither of those is a test plan. **What a tester adds is the habit of asking the
question before the answer is needed**: writing down the load the release has to survive, checking
the form with a keyboard before a user writes in to say they cannot, looking for the key in the
repository before somebody else does.

The course builds on what the previous one left you with. `web-automation` gave you a suite that
drives a browser, and lesson 10 of it was Playwright; lessons 13 to 15 of this course use
Playwright again, for an audit rather than a click-through. Nothing here assumes you remember its
details, and every program a lesson runs is shown whole in that lesson.
