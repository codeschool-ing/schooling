---
title: The project this course builds
version: 2
---

Every lesson that follows adds one piece to a project, and shows that piece on a real one: **loanbook**,
a small web service for the IT room of a school. Teachers borrow projectors, laptops and adapters, and
the record of who has what is a paper sheet on the door. loanbook replaces the sheet with a page that
shows what is out, who has it and when it is due back.

It is deliberately small: one page, one API, one SQLite file, about two hundred lines of Python with
no framework. It has one hard part, which lesson 5 is about. It ends deployed on a server, with a
README, tests, a licence and a two-minute presentation. Its history is told a lesson at a time: when
a lesson says *commit 6 refused the second loan*, the transcript of commit 6 is right there.

**You read loanbook; you do not type it.** The course does not hand you its code, and its transcripts
are not steps to repeat. Each one shows a step done properly on a real project, and the step you take
is the same one on yours. Two things you do build by hand, because your own project needs them too:
your computer, ready to work, in the next section, and the server you deploy to, in lesson 15.

The example is a web service because that shape has the most moving parts to show. Your project will
have the shape your track needs:

::: track frontend mobile
For you the project is the interface: something a person opens and uses, on a real device or in a
real browser. Take the lessons on accessibility, empty states and the demo as the centre of the course.
:::

::: track backend ai prompt
For you the project is a service with a contract: an API, what it refuses, and what happens when it
fails. loanbook is close to your shape already, and the lessons on errors, tests and deploy are yours.
:::

::: track data data-science bi
For you the project is a question answered with data: a pipeline, an analysis or a dashboard. Where
loanbook has an API, you have a dataset and a method; where it has a page, you have the result a
reader looks at.
:::

::: track devops devsecops cloud-engineering
For you the project is the path from a commit to something running: the build, the deploy, what keeps
it up and how you find out it has stopped. Treat loanbook as the workload and lesson 15 as your centre.
:::

::: track it-support networks-infra dba
For you the project is an environment someone else can rely on: a lab you built, documented well enough
that another person could rebuild it. Where loanbook has code, you have configuration and a runbook.
:::

::: track qa security
For you the project is evidence about somebody else's system: a test suite, an assessment, a finding
written up so it can be reproduced. loanbook can be that system; its tests and its refusals are a start.
:::

::: track *
Whatever your field, the project is the thing a stranger can open and check. Read loanbook as one
example of that, and lesson 3 for what people hiring in your field open first.
:::

Lesson 3 goes further into what people hiring in each field actually open.
