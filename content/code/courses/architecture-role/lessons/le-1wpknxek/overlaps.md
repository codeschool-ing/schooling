---
title: Where the roles overlap
version: 1
---

**The three roles share most of their activities, so the titles alone never settle whose decision
something is.** All three write code (lesson 15 argued why the architect must keep doing it), all
three review designs, and all three take technical decisions every week. The common belief is that
clear titles prevent conflict. They do not, because a title says who somebody is and not which
decisions are theirs. Carreto has been through both ends of this: one person holding every role, and
two people each sure that one decision belonged to them.

## One person, three roles

In Carreto's second year there were six engineers, and Tomás Viana, already leading engineering,
held all three roles at once. He wrote about a third of the code, decided how the team built it,
and decided how the monolith was divided into modules. It worked, and not by luck: **when one head
holds all the context, there is no gap between roles for a decision to fall into.** Nobody had to
ask whose call it was, because every call was his and he was in every conversation.

The arrangement fails gradually, and it gives warnings before it does. Three of them showed at
Carreto when the company passed eighteen engineers in three teams:

- **Decisions waited for one person.** A pull request that touched two modules sat for two days
  until Tomás could look at it, and the teams started splitting changes to avoid needing him.
- **Teams found out about each other's decisions in production.** The Shipper and Payments teams
  each added a field for the shipper's tax number, with different validation, and nobody noticed
  until an invoice was refused.
- **The person in all three roles was doing none of them well.** Tomás's code was the code most
  often reverted, because he wrote it between meetings.

None of this argues that a small company needs an architect. It argues for something cheaper:
**name the hat a decision is taken in.** In a team of nine engineers with one tech lead, that tech
lead takes the architectural decisions too. The difference is whether those decisions get the
treatment from this course: a record (lesson 5), the advice of the people affected (lesson 3) and a
scenario with a number in it (lesson 6). The alternative is taking them in the same breath as
deciding which ticket goes first. The title can wait. The habits cannot.

## Two people, one decision

At fifty engineers the opposite problem appears: two people who are each right on their own axis.

Kátia Lemos, the tech lead of Matching, wanted Matching to read prices straight from Pricing's
database tables. Asking the Pricing service took about 400 ms per load at peak, reading the tables
took about 40 ms, and offering a load to drivers ten times faster is exactly the kind of decision a
tech lead is there to take. For her it was an internal performance decision. For Renata it was a
decision about **who owns which data**, which crosses two teams and is very expensive to undo once a
second team's code depends on another team's table layout. Lesson 1 made the same point about
connectors: a shared database is a different architecture from a call, with different ways to fail.

Both of them were right about the decision as they saw it. The argument took two weeks, and the
answer was not what took the time. **What took the time was that nobody knew whose question it was**,
so each conversation reopened that before it reached the substance.

The opposite gap is quieter. The message broker that a few teams use had been running a version out
of support for fourteen months. Platform operated it, three teams depended on it, and each assumed
one of the others owned the upgrade. Nobody was wrong; nobody was responsible either.

## A table of decision rights

Carreto's answer was a table, written by Renata with the seven tech leads and Tomás in one long
afternoon and kept beside the decision records, in the same repository, reviewed like code
(lesson 8). It is a lighter cousin of the RACI matrix, with three columns where RACI has four:

| decision | who decides | who must be asked first | who is told |
|---|---|---|---|
| a library or internal design inside one team's service | the team, through its tech lead | the people on the team who will maintain it | nobody outside the team |
| a table the team alone reads and writes | the team | Platform, if it needs a new database | — |
| a contract between two teams' services: an API, an event | the two tech leads together | the architect | the teams that consume it |
| who owns which data, and who may read it | the architect | the tech leads of the teams involved | Tomás |
| a new language, database or broker in production | the architect | Platform, and the teams that would run it | everybody, in the architecture forum |
| what gets built next | product, with the team's tech lead | the architect, on structural cost | the team |
| who is hired, promoted or moved between teams | the engineering manager | the tech lead | — |

Three things about it are worth seeing.

**The architect decides two rows out of seven.** That is the point of the table rather than a gap in
it. Most technical decisions at Carreto belong to the teams, and the table protects them from an
architect drifting into their space as much as it protects the cross-team decisions from being
taken by whoever moves first.

**It does not replace the advice process from lesson 3.** Under that process anybody may take a
decision, as long as they first ask the people affected and the people with expertise. The table
says who **answers for** each kind of decision and whose advice is not optional. Kátia could still
have proposed reading Pricing's tables; the fourth row says that Renata answers for whether it
happens, and that Kátia and the Pricing tech lead must be asked before she decides.

**Each row is a pair of axes.** The first two rows are one team and a short horizon; the next three
are several teams or a long horizon. The last two are not technical decisions at all, and this lesson's
last section is about why they stay outside the architect's reach.

Kátia's case, put through the table, lands on row four in a minute. The broker upgrade lands on row
five, and the table adds what was missing: a name.

## When the table is wrong

A decision-rights table ages like any other document, and the symptoms are easy to see. **A decision
that lands in no row**, or one that two people point at in two different rows, is a reason to change
the table rather than to argue the case. Carreto's carries the date of its last review at the top
and is looked at again whenever a team is created or split, because a new team boundary is a new
place for a decision to fall between two chairs.

And the table is not a substitute for talking. Renata still goes to Kátia before Matching's next
design review, not because the table requires it, but because the decisions that cross teams are the
ones where a conversation in advance is cheaper than a correction afterwards.
