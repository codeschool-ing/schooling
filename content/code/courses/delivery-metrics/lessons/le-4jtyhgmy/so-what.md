---
title: The question every chart has to survive
version: 1
---

When Bia showed her first draft to Marta, Marta looked at the chart of story points completed per sprint, which went up and to the right, and asked: **"So what?"**

It is the most useful question anybody can ask of a chart, and most charts in a review cannot answer it. Points went up. Does that mean shops get their features sooner? Does it mean the team is working harder, or estimating bigger, or splitting work differently? Lesson 9 showed that points predict little, and lesson 7 showed how easily they inflate. The chart was accurate and it supported no decision, so it went.

## The test

A chart belongs in a review if somebody can say, in one sentence each:

1. **what it shows**, in words a person outside the team understands;
2. **why it changed**, or why it did not;
3. **what anybody should do about it**, including "nothing; keep going".

The third sentence is the one that kills most charts. "Deployments went from 5 a month to 20" passes the first; "because the team now releases each item when it is ready" passes the second; "so fixes reach the shops within a day, and other teams should consider the same rule" passes the third. That chart stays.

## Charts that fail it

Some charts fail every time, and recognising them saves a draft:

| chart | why it fails |
|---|---|
| story points or velocity | measures the team's estimates, not anything a customer feels |
| tickets closed | rewards splitting work, and counts a typo fix like a feature |
| lines of code, commits | rewards activity; the best change of the quarter may have deleted code |
| utilisation, % of time busy | lesson 12: a fully busy team is a slow team |
| a number per developer | lesson 8: measures people against each other, and the team stops sharing work |
| anything with no comparison | a single number with nothing to compare it to cannot point anywhere |

The last row is the commonest. "Median cycle time: 4 days" is a fact; "4 days, down from 23 in July" is a finding. Every number in a review needs its **before** beside it, and if there is no before yet, it needs to say so.

## When the answer is uncomfortable

The test cuts both ways. A chart that survives "so what?" with an answer the team does not like stays in, and the 30 September incident is the obvious example: one failed deployment, 54 minutes of double charges, 212 of them, and the error budget 201% spent. The "so what" is that October's features wait. Leaving it out would make the review more pleasant and less believable, and the people in the room already know about it: Marta's shop owners rang her.
