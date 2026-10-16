---
title: Smaller batches, for real or for the chart
version: 1
---

The DORA research says small batches are good, and the Billing team's August says the same thing with numbers. That makes "smaller batches" the most convincing disguise a trick can wear, because the real improvement and the fake one produce the same headline: **more deployments, lower failure rate**.

## Two teams, one headline

The Billing team in August made its batches smaller **by changing how work flowed**. Fewer items open meant each item finished sooner, so each day's merges were fewer, so each deployment carried fewer changes. The batch got smaller because the work got smaller and faster.

The "one per change" version of the previous section made its batches smaller **by changing how deployments were counted**. Thirty-eight pipeline runs became seventy-two deployments. The batch got smaller on paper and stayed exactly the same size on the wire.

## The four tests

Put the two side by side and four questions tell them apart, each one answerable from the data.

| question | August, for real | one per change, for the chart |
|---|---|---|
| **did lead time for changes fall?** | from about 50 hours to 4.5 | no: 4.5 before and after |
| **did time to restore fall?** | from about 166 minutes to 52 | no: 52 before and after |
| **did the number of pipeline runs grow?** | from 9 to 38 | no: 38 runs, counted as 72 |
| **did anything upstream change?** | work in progress fell to a quarter | nothing |

**Real batch reduction moves the metrics that are measured on changes and failures, not only the ones measured on deployments.** A change waits less for its deployment, because deployments are frequent; a failure is quicker to undo, because there is less in it to untangle. A counting trick cannot fake those, which is why lesson 5 insisted the four be read together.

## A small batch that is real and still pointless

There is a third case, and it is not a trick. A team can deploy every change separately, for real, with a separate pipeline run each time, and gain little, because its changes were already small and its problem was elsewhere: a review queue, a backlog, a slow test suite. The numbers improve honestly and the requester waits as long as before. That is lesson 6's point about symptoms, met from the other side: **a real improvement in a metric is not the same as an improvement in what the metric was for**. Check the clock the customer reads, lesson 2's lead time, before celebrating any of the four.
