---
title: Five headings on one page
version: 1
---

The usual picture of a serious strategy is a long document: a market analysis, an architecture
review, a history of how the company got here, and an appendix with every team's proposals. It
looks thorough. **Its length is where the choice hides.** A reader who has to get through all of
it to find what the company decided will usually not find it, and the people who most need to know
are the ones least likely to read that far.

A strategy that a team can use fits on one page, under five headings:

| heading | what it says | where it comes from |
|---|---|---|
| Diagnosis | what is going on, and which part of it matters | the kernel, lesson 1 |
| Guiding policy | the approach, in a sentence somebody can repeat | the kernel, lesson 1 |
| What we will do | the actions, each with an owner and a start | the kernel, lesson 1 |
| What we will not do | the proposals the policy rules out, by name | the next section |
| How we will know | the signals that would show it working, or failing | this section |

The first three are Rumelt's kernel. The last two are what make the page usable on an ordinary
Tuesday, by somebody deciding whether their next piece of work fits.

## A one-pager, and what is particular to this one

The one-page document as a genre — who it is for, how it is structured, how to cut it down until
it fits — is lesson 2 of the `architect-communication` course. Everything there applies here. A
strategy page differs from a proposal page in a few ways, and they decide how it is written.

**A proposal asks for one decision. A strategy page is a tool for hundreds of later ones.** The
proposal is read once, by the people who approve it. The strategy is consulted again and again, by
people who were not in the room, when they are deciding something the page never mentioned. So it
is written for the engineer in Box Office who wants to know whether her change to the seat map can
go out next week, not for Helena, who already agreed to it.

It carries a header that a proposal does not need: **who owns it, who signed it, and when it will
next be reviewed.** The page is going to be quoted in arguments, and a quotation needs a source
with a date. It also leaves the evidence out. The incident analysis that supports the diagnosis is
a link, not a paragraph, because the reader of the page needs the conclusion and the reviewer of
the evidence knows where to look.

## Davi's page

Davi wrote the page as a Markdown file in a plain-text editor, the tool lesson 1 set up, and put it
in the engineering handbook beside the incident reports it cites. This is the version that went
out after the test in the third section of this lesson:

> **Coreto technical strategy: protect the on-sale first**
>
> Owner: Davi Moreira · Signed: Helena Prates, CTO · Next review: end of each quarter
>
> **Diagnosis.** Coreto earns its reputation in about twelve big on-sales a year, and those are
> exactly when it fails. The failures come from the seat-hold code in the reservation module,
> which every team changes and no team owns. Everything else on the teams' lists is real, and none
> of it costs us a venue the way a failed on-sale does.
>
> **Guiding policy.** Protect the on-sale first. Work on the seat-hold path comes before any other
> technical investment, and nothing ships to it without evidence from a load test.
>
> **What we will do.**
>
> 1. From 1 March, a Reservations team of four, drawn from Checkout and Payments, owns the
>    reservation module. Changes to the seat-hold code need its review.
> 2. Platform builds a load test that replays an on-sale, before anybody changes the hold path.
> 3. Reservations spends its first two quarters removing the row locks from the hold path,
>    measured by the load test.
> 4. No deploys to the reservation module in the 24 hours before a big on-sale.
>
> **What we will not do this year.**
>
> - Start the migration to microservices, including one service at a time.
> - Move to a new front-end framework.
> - Rewrite the reservation module from scratch.
> - Change the reservation path in the on-sale season for cost or for features, unless the change
>   has passed the load test.
>
> **How we will know.**
>
> - Every big on-sale this year completes without a checkout incident traced to seat holds.
> - Checkout availability on on-sale days reaches 99.99%.
> - Every change to the hold path carries its load-test result.
> - By the end of the Reservations team's second quarter, the hold path takes no row locks.

The policy is in the title. That was not the first version, and the third section explains why it
moved.

## How we will know

The last heading is the one most often left out, and the one that keeps the page honest. **Each
line under it should be able to come out false.** "Teams feel more confident about on-sales" cannot
be false: there is always somebody who feels better. "Every big on-sale completes without a
checkout incident traced to seat holds" can be false on a Tuesday morning at 10:05, and everybody
will know.

The four signals on Davi's page are of two kinds, and a page needs both. Two are **outcomes**: the
on-sales complete, and availability on on-sale days reaches the target that lesson 1 demoted from
goal to measure. Two are **evidence that the actions are happening**: load-test results on every
change, and the row locks gone by a date. The outcomes say whether the strategy is right. The
evidence says whether anybody is carrying it out, and it arrives months before the outcomes can.

A signal that measures activity rather than effect — tickets closed, meetings held, a document
published — is not on the list, because it can go green while the on-sales keep failing.

## If it does not fit

When a draft runs past one page, the cause is nearly always upstream of the writing. A diagnosis
covering three problems produces three policies and a page of actions; a policy that rules out
nothing produces a not list with nothing in it, and the space fills with background instead. **Cut
the diagnosis to the one challenge that matters, and the rest of the page usually follows.**

Try it on your own organisation before reading on. Open a new Markdown file, write the five
headings, and fill each with what is true where you work today. The heading you cannot fill is the
part of your strategy that does not exist yet.
