---
title: Where the data comes from, and what to agree first
version: 1
---

The Billing team's four numbers came from two clean files. A real team's come from three or four systems that were never designed to agree, and most of the work of measuring DORA is deciding, once and in writing, how those systems will be read.

## Three sources

| metric | where it comes from |
|---|---|
| deployment frequency | the deployment pipeline: every run that reached production and finished |
| lead time for changes | the version control system for the commit time, the pipeline for the deployment time |
| change failure rate | the pipeline for the deployments; the incident tracker, or rollback records, for which ones failed |
| time to restore | the incident tracker, or the time between a failed deployment and the one that fixed or reverted it |

**Read the systems; do not survey the people.** The original research used surveys because it was comparing thousands of organisations that could not share their pipelines. A single team has its pipeline, and asking people "how often do we deploy?" when a machine has recorded every deployment is asking for an estimate of a fact. Tools that compute the four from a pipeline and an issue tracker exist, open-source and commercial; the work below has to be done whichever one you use.

## Decide before you look

Each of the four has a choice inside it, as the previous section showed. Make those choices **before** looking at the numbers, write them in one place, and change them only with a note saying when. The decisions worth writing down:

- **What is a deployment?** Per service or per release; whether configuration changes and database migrations count.
- **What is the start of lead time?** The first commit, the opening of the pull request, or the merge.
- **What is a failure?** A rollback, a hotfix, any incident caused by a change, or only incidents above a certain severity (lesson 13).
- **When does restoring start and end?** From the deployment or from detection; until users are unaffected, not until the cause is fixed.

A team that decides these after seeing the numbers will, without anybody intending it, decide them in the direction that looks better. That is not dishonesty; it is how people read ambiguous rules. Lesson 7 is about what that drift does to a metric over a few quarters.

## The merge-as-commit shortcut

This course measures lead time for changes from the merge, because the Billing team's files have nothing earlier. That leaves out the time a change spends in review, which lesson 2 found was the largest queue in July. **A lead time for changes measured from the merge cannot see a review bottleneck at all.** If your pipeline lets you measure from the first commit, do; if it does not, say which you measured every time you quote the number.
