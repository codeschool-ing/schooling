---
title: Where the four metrics come from
version: 1
---

For most of the history of software, people who ran teams believed in a trade-off: **you could go fast or you could be safe, and moving one meant giving up the other**. Releasing often meant breaking things often; stability meant change control, release trains and freezes. The belief was reasonable and it was never measured.

The DORA metrics come from the work that measured it. From 2014 a yearly survey, the *State of DevOps Report*, asked thousands of people in technology organisations how their teams delivered software and how their organisations performed. It was run first with Puppet and then by DORA, DevOps Research and Assessment, the company Nicole Forsgren, Jez Humble and Gene Kim founded. Their 2018 book *Accelerate* set out what four years of it had found, and Google acquired DORA at the end of that year and has published the report since.

## The finding

The surprise was in the shape of the data. **Teams did not trade speed for stability. The teams that delivered most often were also the ones whose changes failed least, and that recovered fastest when they did.** Speed and stability went up together, and down together. The explanation the researchers gave is the one this course has been building since lesson 1: small changes, delivered often, are easier to test, easier to understand when they break and easier to undo.

To show it, they needed a way to measure delivery that did not depend on the kind of software or the size of the company. They settled on four numbers, two for speed and two for stability, and those are the **four key metrics**:

| metric | the question it answers | kind |
|---|---|---|
| **deployment frequency** | how often do we put changes into production? | speed |
| **lead time for changes** | how long from a commit to that commit running in production? | speed |
| **change failure rate** | what share of our deployments cause a failure that needs fixing? | stability |
| **time to restore** | when a deployment fails, how long until service is back? | stability |

## They keep moving, a little

The research is a yearly survey, and its vocabulary has shifted over the years. Reliability, whether a service meets its own targets, was added as a fifth measure in 2021. The 2023 report renamed time to restore as **failed deployment recovery time**, to say plainly that it is about recovering from a bad deployment rather than from any outage. The 2024 report added a measure of **rework**, deployments made to fix earlier ones. Each report also groups teams into performance clusters with thresholds that change from year to year.

This course uses the four by their long-standing names and quotes **no thresholds**, for a reason lesson 6 develops: the thresholds describe thousands of other organisations, and a team learns more from its own trend than from its place in somebody else's table. When you read a DORA report, check its year; the figures in it are a citation, not a constant.
