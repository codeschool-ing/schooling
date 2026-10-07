---
title: The same decision, written four ways
version: 1
---

**The test of adapting a message is to write the same decision for each reader and compare what
moved.** Here is the replica decision from lesson 2, after it was approved on 19 March, as Lívia
announced it to each of the four audiences.

## To the board, in Otávio's monthly report

> Friday-evening checkout failures, about 180 failed payments a week, will be fixed in April for
> six engineer-weeks and R$ 4,000 a month. The fix also removes the risk of checkout stopping
> completely at peak, which is what caused the 32-minute outage on 6 March.

Two sentences. The unit is payments and reais. The outage is named because the board already heard
about it; the replica is not, because nobody on the board will decide anything about it.

## To Renata, head of product

> The replica work is approved and takes six engineer-weeks from the platform team in April. That
> moves the substitution flow from April to the first two weeks of May; nothing else on the
> roadmap moves. In exchange, Friday checkout failures should drop from about 180 a week to near
> zero, and support stops getting the Friday-evening complaints Sofia's team logs every week. I will
> confirm the May date on 30 April, once the switch-over is done.

What changed: **what it displaces** is in the second sentence, and the benefit is stated in effects
she already tracks, failed checkouts and support complaints. There is a date for the next update,
because product plans around dates.

## To the engineering team, in the platform channel

> Approved: the route planner moves to a read replica of the orders database in April (proposal
> linked). Platform owns the replica; logistics owns the route planner's switch-over. Two things
> that affect other teams: the replica can lag the primary by a few seconds, so **do not read
> from it anything you are about to write back**; and per the connections RFC, every service gets a
> fixed connection quota on the primary from 1 May. Questions in the thread, please, not in DMs,
> so the answers are findable.

The longest version, with the constraint that matters to other engineers in bold, the owners named,
and a rule about where questions go. **The reason for the replica is not repeated**: it is in the
linked proposal, and the team will read it there.

## To Tânia, operations director at Boa Praça

Boa Praça is a supermarket chain whose deliveries Marola runs, and Tânia is the person there who
answers to her own directors when deliveries go wrong.

> Tânia, on the evening of Friday 24 April, between 23:00 and 23:30, we will switch over part of
> our delivery planning system. Orders already placed are not affected, and no action is needed
> from your stores. If you see anything unusual that evening, call me directly on the number you
> have. — Lívia

Nothing about databases, replicas or the incident. **What changes for her, when, what she must do
(nothing), and who to call.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Four bars, the word counts of the same decision written for four readers. The board: 44 words, in payments and reais. Renata: 76 words, about what moves on the roadmap. The team: 87 words, with owners, constraints and rules. Tânia: 53 words, about what changes for her stores.\"><defs><marker id=\"lengths-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the board</text><rect x=\"130\" y=\"22\" width=\"176\" height=\"24\" rx=\"3\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"314\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">44</text><text x=\"346\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">payments, reais</text><text x=\"20\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Renata</text><rect x=\"130\" y=\"68\" width=\"304\" height=\"24\" rx=\"3\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"442\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">76</text><text x=\"474\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">what moves on the roadmap</text><text x=\"20\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the team</text><rect x=\"130\" y=\"114\" width=\"348\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"486\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">87</text><text x=\"518\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">owners, constraints, rules</text><text x=\"20\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Tânia</text><rect x=\"130\" y=\"160\" width=\"212\" height=\"24\" rx=\"3\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"350\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">53</text><text x=\"382\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">what changes for her stores</text><text x=\"130\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">words in each version of the same decision</text></svg>", "caption": "Word counts of the English versions. The length follows what the reader decides, not how important the reader is: the board gets the shortest."}
```

## What stayed the same

Every version that gives a number gives the same one: 180 failures a week, six engineer-weeks,
R$ 4,000 a month, April. **The facts are fixed and everything around them adapts.** If one of the
four had said "a few failures" and another "180", a reader holding both would have reason to wonder
which one was being managed.
