---
title: The technology-list trap
version: 1
---

**An audience of decision-makers does not decide technologies, so a presentation organised around
technologies gives them nothing to decide.** It is the most common shape of an architect's
presentation, and the most common reason the meeting ends with "let's take this offline".

## What it looks like

Here is the outline of Lívia's first draft, before Bruna read it:

1. Current architecture (a diagram with eleven boxes and the logos of six products)
2. PostgreSQL connection limits and how they work
3. Streaming replication: synchronous against asynchronous
4. Connection pooling options compared
5. Proposed architecture (the same diagram with twelve boxes)
6. Migration plan in four phases
7. Questions

Every slide is accurate. The word *checkout* appears for the first time on slide 5, the cost on
slide 6, and the decision nowhere. Otávio would have spent eight minutes learning how PostgreSQL
replication works, which he had not asked to learn and will not need again, and the meeting would
have ended without anybody being asked for anything.

## Why it happens

The list is the shape of the work. Lívia spent two weeks on replication modes and connection pools,
so they feel like the substance of the proposal. **To the audience they are the method, and nobody
approves a method; they approve an outcome at a price.** It is the curse of knowledge from lesson 3
again: the details the presenter fought with feel essential because she fought with them.

There is a less comfortable reason as well. A technology slide is safe. Nobody can disagree with how
streaming replication works, so a presentation full of them never meets resistance, and never gets
a decision either. **A decision slide invites disagreement, which is the point of it.**

## The rewrite

The second outline, after Bruna's question "what do you want them to say at the end?":

1. Friday evening: our busiest three hours, and a growing share of checkouts fail
2. 6 March: what a bad Friday costs (32 minutes, 1,350 failed checkouts)
3. Why: two systems share one database and compete at peak
4. Four options and their prices
5. The recommendation: a replica, six engineer-weeks and R$ 4,000 a month
6. What we need today: approval, so the platform team can start on 6 April

Six slides, each with a sentence for a title, and one diagram with three boxes on slide 3. The
replication mode is not mentioned. If Caio asks how the replica is kept up to date, the answer is
one sentence and a link to the design document, and the fact that he asked is information about
what worries him.

## Technology in its place

Technologies appear in a decision presentation in exactly two ways:

- **as the name of an option**, priced and compared ("a larger database server: R$ 9,000 a month");
- **as the answer to a question**, when somebody asks.

Everywhere else, say what the technology does for the decision. Not "we will add PgBouncer", but
"we will ration connections so that one system cannot take all of them".
