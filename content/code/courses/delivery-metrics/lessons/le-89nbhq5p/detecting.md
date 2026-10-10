---
title: Detecting it, and making it pointless
version: 1
---

Gaming is easier to prevent than to catch, and easier to make pointless than to prevent. The habits below do all three, roughly in that order of importance.

## Read the four together

Every trick in this lesson's catalogue improves one or two metrics and leaves the others alone or makes one undefined. **Read as a set, the four DORA metrics are hard to fake.** A report that improves deployment frequency and failure rate while lead time and restore stay flat is asking a question; a report that shows a 0% failure rate with no time to restore has answered it.

## Keep a log of definitions

Write down what counts as a deployment, a failure, a start and a restore, as lesson 5 asked, and **put every change to a definition in the same log with its date**. A chart with a step in it can then be checked against the log in a minute. Most changes of definition are reasonable; all of them should be visible, because an invisible one is indistinguishable from an improvement.

## Look at the events, not only the rates

A rate hides its numerator and denominator. "3%" could be 2 of 72 or 1 of 38. Showing the counts beside the rate, as `game.py` does, makes a sudden jump in the denominator visible. **Whenever a number improves sharply, open the raw events behind it**: the list of deployments, the list of failures, the items that left the board. Five minutes with the list finds most tricks.

## Pair every metric with the one it can be traded against

| if you watch | also watch |
|---|---|
| deployment frequency | change failure rate, and the number of pipeline runs |
| change failure rate | time to restore; a sudden "-" means the definition moved |
| throughput | cycle time, and items reopened |
| cycle time | items split or moved off the board |

## Make it pointless

The strongest defence is the one lesson 6 and lesson 20 argue for: **nobody's pay, rating or standing depends on the number**. A team that reads its own metrics to improve its own work gains nothing by fooling itself, and loses the instrument. A team ranked or rewarded by them gains everything. Goodhart's law is not a law of nature; it is what happens under one particular use of a number, and the use is a choice.

## When you find it

You will. When you do, **fix the incentive before you talk about the people**. The person who split the deployments was answering a question somebody asked them to answer. Change the question, write the definition down, and the trick stops being worth doing. Treating it as misconduct teaches everybody to hide the next one better, which is the opposite of the generative culture lesson 6 described.
