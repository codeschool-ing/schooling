---
title: The four, defined closely enough to compute
version: 1
---

Each metric sounds obvious until two people try to compute it from the same data and get different numbers. These are the definitions this course uses, with the choices each one hides.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 230\" role=\"img\" data-fig=\"l05-timeline\" aria-label=\"A timeline of one change: committed, merged, deployed, a failure noticed, service restored. Lead time for changes runs from the commit to the deployment. Time to restore runs from the failed deployment to the restore. Deployment frequency counts the deployments, and change failure rate is the share of them that fail.\"><path d=\"M40.0 100.0 L640.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"60.0\" cy=\"100.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"60.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">commit</text><circle cx=\"210.0\" cy=\"100.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"210.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">merge</text><circle cx=\"360.0\" cy=\"100.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"360.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">deploy</text><circle cx=\"470.0\" cy=\"100.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"470.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">failure noticed</text><circle cx=\"620.0\" cy=\"100.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"620.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">restored</text><path d=\"M60.0 132.0 L360.0 132.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M60.0 126.0 L60.0 138.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M360.0 126.0 L360.0 138.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"210.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">lead time for changes</text><path d=\"M210.0 30.0 L360.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M210.0 24.0 L210.0 36.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M360.0 24.0 L360.0 36.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"285.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what this course measures, from the merge</text><path d=\"M360.0 170.0 L620.0 170.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M360.0 164.0 L360.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M620.0 164.0 L620.0 176.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"490.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">time to restore</text><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">deployment frequency counts these; change failure rate is the share that fail</text></svg>", "caption": "Two of the metrics are durations on this line and two are counts of the deployments on it."}
```

## Deployment frequency

**How many deployments to production in a period**, usually quoted per day or per week. A deployment is a change reaching the environment users actually use. A deployment to a test environment does not count, and neither does merging to the main branch: code that has merged and is waiting for Thursday's train has not been delivered.

The choice it hides is **what counts as one deployment**. A team with five services that deploys all five at once can count one or five. Either is defensible; switching from one to the other halfway through a quarter multiplies the metric by five overnight.

## Lead time for changes

**The time from a change being committed to that change running in production.** It measures the pipeline and the review: everything that happens to finished code before a user has it. It is not lesson 2's lead time, which starts when a request is written down, and the shared name is a trap worth naming every time you quote it.

The choice it hides is **which commit**. The first commit on a branch includes development time; the merge commit measures only what comes after review. The Billing team's files record the merge, so this course measures from there, and the number is correspondingly shorter than it would be from the first commit.

## Change failure rate

**The share of deployments that cause a failure in production needing remediation**: a rollback, a hotfix, a patch, an incident. It is a fraction of deployments, not a count of incidents, so a team that deploys more often can have more failures and a lower rate.

The choice it hides is **what counts as a failure**. A deployment rolled back because of a typo in a log message, a deployment that caused an outage four days later, a deployment that was fine but whose feature nobody wanted: a team has to decide in advance which of those it counts. Lesson 7 shows what happens when the decision is made afterwards.

## Time to restore

**For a failed deployment, how long until service is restored for users**, usually quoted as a median because a few long recoveries dominate any average. Restored means users are no longer affected, which often happens long before the cause is fixed. Rolling back is a restore; finding the bug is not required.

The choice it hides is **when the clock starts**: when the deployment happened, when somebody noticed, or when an incident was declared. Starting at detection hides slow detection, which is often the largest part. Lesson 14 takes an incident apart into those pieces.

## Two of each, on purpose

The metrics come in pairs that pull against each other. Deploying more often is easy if you stop caring whether deployments fail; never failing is easy if you never deploy. **Only the four together describe delivery**, and a report that shows the two speed metrics without the two stability metrics, or the reverse, is showing half a picture chosen by somebody.
