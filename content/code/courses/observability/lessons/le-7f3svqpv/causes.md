---
title: Contributing factors, not a root cause
version: 1
---

The phrase *root cause* promises that an incident has one cause at the bottom, and that removing it
prevents the incident. **Real incidents in systems that are already reliable rarely have one.** They
happen when several conditions, each harmless alone, line up on the same afternoon.

The **five whys** is the classic method: ask why the failure happened, then why that happened, five
times. Applied to lesson 17's incident:

1. Why did checkouts fail? Payments failed one charge in eight.
2. Why? Release 1.4.2 of payments had a bug in its handling of the card network's answers.
3. Why did it reach production? The tests ran against a mock that never answers with that error.
4. Why did nobody notice for minutes? The release went to every instance at once.
5. Why? The pipeline has no canary step for payments.

It is useful, because it keeps asking past the first answer. Its weakness is that it walks **one**
chain and stops at whatever the fifth answer happens to be. Asked by somebody else, the same incident
could end at *the mock is maintained by another team*, or *nobody owns the release checklist*.

A postmortem therefore lists **contributing factors**: every condition without which the incident would
not have happened, or would have been smaller. For the same incident:

| factor | kind |
|---|---|
| the bug in 1.4.2's handling of an error response | trigger |
| tests against a mock that never returns that error | missing defence |
| release to every instance at once, with no canary | missing defence |
| a fast-burn alert that needs its five-minute window to fill before it pages | slower detection |
| a deploy annotation existed, so *what changed?* had an answer in seconds | defence that worked |

The last row matters as much as the others. **What went well is recorded too**, because it is the part
most likely to be removed by somebody tidying up a pipeline who does not know it ever helped.

Each missing defence, not the trigger, is where the actions come from. Fixing the bug fixes this bug;
a canary step and a better mock catch the next one, whatever it is.
