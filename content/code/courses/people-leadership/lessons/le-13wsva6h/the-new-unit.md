---
title: The unit of your work has changed
version: 1
---

Most people who become managers of engineers were promoted for being good engineers. **The work
they were good at is now somebody else's job**, and the thing they are measured by is something
they cannot do with their own hands. That is the whole difficulty of the first year, and most of
what goes wrong in it comes from measuring the new job with the old ruler.

This course follows one person through that year. **Caju** is fictional: a company in Belo
Horizonte that sells scheduling, reminders and billing software to medical clinics, with about
ninety engineers in eleven teams. Renata Moura was a senior engineer on the Agenda team, the one
that owns appointment booking, and two weeks ago she became its engineering manager. The team is
seven engineers, a product manager called Helena, and a backlog that was already late when she got
it. Her own manager is Otávio, who runs engineering for the clinic product.

## Grove's sum

Andy Grove, who ran Intel, put the change into one line in *High Output Management* (1983).
With his pronoun made neutral, it reads:

> A manager's output = the output of their organisation + the output of the neighbouring
> organisations under their influence.

Read it as a definition and it is almost boring. Read it as an instruction and it rearranges a
week. **Nothing Renata produces alone appears in that sum unless it changes what the team
produces.** A pull request she merges counts once. An hour spent unblocking Paula, who then ships
for three days without waiting on anybody, counts for three days. A hiring decision she gets right
counts for years, and one she gets wrong costs for about as long.

The second term matters as much as the first. Agenda depends on the Payments team for anything that
charges a clinic, and on the platform team for deploys. When Renata persuades Payments to expose
an endpoint a quarter earlier than planned, her team's output goes up without anybody on it
working harder. That is managerial work too, and it is invisible to anyone counting commits.

## What it feels like from the inside

The sum explains a feeling almost every new manager reports and few expect. **At the end of a full
day there is nothing to point at.** No merged branch, no closed ticket, no green build that is
yours. Renata's first Friday went on four one-to-ones, a planning session, a conversation with
Payments about that endpoint, and forty minutes reading a candidate's take-home. She went home
feeling she had done nothing, and by Grove's sum she had done a reasonable week's work.

The feeling has a predictable consequence. A manager who feels unproductive goes back to the work
that used to make them feel productive, which is writing code. Renata picked up a ticket on the
second Monday, because it was small and nobody else was free. By Wednesday two people were waiting
on decisions only she could make, and the ticket was still open, because she had been in meetings
for most of the time she meant to spend on it.

None of that makes code wrong for a manager. Lesson 2 is about the two shapes this role takes, and
in one of them writing code is part of the job. The point here is narrower: **the code is no
longer what you are measured by**, so it is a choice you make for a reason, and "it is the only
part of my day that feels like work" is a reason that makes the team slower.

## Three things that move

It helps to name exactly what changes, because each of the three has its own lesson later.

- **Your leverage.** Your hours used to turn into output one to one. Now an hour can turn into
  nothing, or into a week of somebody else's progress. Lessons 3 and 4 are about spending it
  where it multiplies: delegating outcomes, and deciding how much freedom goes with them.
- **Your information.** You used to know the state of the code because you were in it. Now you
  know what people tell you, and they tell their manager less than they told a colleague. Lessons
  5 to 7 are about the meeting that fixes that.
- **Your effect on people.** A colleague's opinion of somebody's work is an opinion. Yours is now
  an input to their pay, their promotion and, in the worst case, their job. Everything from
  lesson 8 onwards depends on handling that weight honestly.

## The ruler for the new job

If commits are the wrong measure, what is the right one? Grove's answer is the team's output, and
in a software team that means what reaches users and how reliably it does. A team that ships what
it said it would, keeps the service up and keeps its people, is a team whose manager is doing the
job — whoever wrote the code.

The difficulty is the delay. **A manager's decisions take weeks or months to show in that output**,
which is the subject of the next section, and it is why the first months feel like flying with
instruments that answer late.
