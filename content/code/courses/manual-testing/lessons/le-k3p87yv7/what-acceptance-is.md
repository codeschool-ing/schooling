---
title: What acceptance testing is
version: 1
---

A common picture of user acceptance testing is a last lap of system testing: the same cases, run
once more by the test team, with a client's name on the cover. **Acceptance testing asks a different
question, and somebody else answers it.** System testing asks whether the product meets its
requirements, and the testers judge. Acceptance testing asks whether the people who will own the
product can do their work with it, and they judge. The theatre's manager does not want to know
whether R5 passes. She wants to know whether she can open the box office on Saturday with this.

The two questions can have different answers. Lesson 6 called the second one
**validation**: are we building the right thing, as opposed to building the thing right. Acceptance
testing is validation made formal, with a date, a set of criteria agreed in advance and a decision
at the end, taken by the client. `qa-fundamentals` placed it at the top of the V model, facing the
requirements; this lesson is about what happens there in practice.

## The kinds of acceptance

**User acceptance testing**, UAT, is the one most people mean. The users, or the client acting for
them, use the product to do their real tasks and decide whether it does the job. For boxoffice
that is the manager and the two clerks who sell at the counter.

**Operational acceptance testing** asks whether the people who run the system can run it: back it
up, restore it, start it after a power cut, see when it is in trouble. It finds a different kind of
problem. boxoffice keeps everything in memory, so a restart empties every order. That is fine in a
test build and a disaster for a theatre on a Saturday night, and no functional test of booking will
ever say so, because each one starts by restarting.

**Contractual** and **regulatory** acceptance check a product against a contract, or against a law
or a standard: a bank's system against the central bank's rules, a website against an
accessibility law. Each has its own paperwork, and the shape is the same.

## Alpha and beta

Two more words come from companies that sell one product to many customers, where there is no
single client to ask.

**Alpha testing** is done by people inside the company that built the product, but outside the team
that built it, usually in the developers' own environment: staff from sales or support using the
product as a customer would. **Beta testing** gives a nearly finished product to some real users,
in their own environment, before the general release, and collects what they report. A beta reaches
the machines, networks and habits that no test environment has.

boxoffice is built for one client, and the words still fit with a little stretching. An alpha would
be the two clerks using the test build of 1.1 for a morning, with Ana beside them. A beta would be
selling the real tickets for one Sunday matinee of The Little Prince through 1.1, with the old way
of selling kept ready in case it fails.

## Who does what

Most UAT that goes wrong goes wrong over the roles.

**The client decides.** They choose what acceptable means, they run the session or have their users
run it, and they say yes or no at the end. A UAT in which the testers run the cases and the client
signs the result is a system test with a signature, and it misses exactly what UAT exists to find.

**The tester prepares and supports.** Ana sets up the environment, writes the criteria into cases
the manager can follow, records everything that happens, and turns what she sees into defect
reports and questions. She does not argue the manager out of a finding, and she does not decide
whether the release goes out.

**UAT starts when system testing has finished**, with its results known. Handing a client a build
that still fails its own system tests wastes the one afternoon they have, on defects the team
could have found alone. Lesson 10's regression run is part of that: the student discount defect is
already reported when the manager sits down, and she will meet it anyway, which section 04 of this
lesson follows.
