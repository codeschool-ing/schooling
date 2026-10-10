---
title: The metric is a symptom
version: 1
---

The most common way to misuse the DORA metrics is also the most natural one: **a manager reads that good teams deploy often, and asks the team to deploy more often**. The request looks like a direct route to the result. It is a route around the result, and lesson 7 shows where it leads.

The four numbers are **symptoms**, in the medical sense: things you can observe that tell you about something you cannot see directly. What you cannot see directly is how a team builds and ships software, the dozens of habits that decide whether a change is small, tested, reviewed promptly, deployed safely and easy to undo. The metrics move when those habits change. Pushing on the metrics without changing the habits moves the numbers and leaves the team where it was.

## The Billing team's numbers moved without being touched

Nobody on the Billing team set a target for any of the four metrics. Lesson 5 measured what happened anyway: deployments went from about one a week to between four and five, lead time for changes from two days to a few hours, the failure rate from one in five to one in twenty, the time to restore from over two hours to under one.

What the team actually changed was **how much work it kept open and who did reviews**. That produced smaller batches, and smaller batches produced every one of the four improvements. If, instead, somebody had told the team in June to deploy daily, the pipeline would have run daily and carried whatever had merged: on most days nothing, on Thursdays the same pile as before, because the pile came from the review queue and the review queue was untouched. The deployment frequency would have improved on paper. Nothing else would have.

## What a symptom is for

A thermometer is very useful, and nobody treats a fever by cooling the thermometer. The DORA metrics are useful in the same way, for three jobs:

- **noticing** that something has changed, for better or worse, before anybody has an opinion about it;
- **confirming** that a change in habits did what it was meant to, as the Billing team's did;
- **starting a conversation** about why, which is where the work is.

What they are not for is being the goal. A team that is asked to hit a number will find the cheapest way to hit it, and the cheapest way is almost never the habit the number was supposed to reflect. **Measure the four; change the habits; read the four again.** The next section lists the habits.
