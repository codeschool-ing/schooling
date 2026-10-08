---
title: ITIL and DevOps
version: 1
---

ITIL and the agile and DevOps movements were for years presented as opposites: one the world of approval boards and tickets, the other of automated pipelines and small, frequent changes. The opposition is partly real and partly a misreading, and the evidence on one point is unusually clear.

## What the research found

The State of DevOps research, summarised by Nicole Forsgren, Jez Humble and Gene Kim in *Accelerate* (2018), surveyed thousands of technology professionals over several years and measured how their organisations deliver software. On change approval the finding was blunt. Requiring approval of changes by an **external body**, such as a change advisory board or a senior manager, was associated with **worse** delivery — slower lead times, less frequent deployments, longer recovery — and was **not associated with a lower rate of failed changes**. The authors concluded that such approval was little better than none, and recommended lightweight approval close to the work, such as peer review, combined with automated testing to catch bad changes before they reach production.

That is not a finding against controlling change. It is a finding that a weekly meeting of people far from the code is a poor way to do it.

## Where they meet

Read carefully, ITIL 4 and DevOps say compatible things:

- ITIL 4's guiding principles include *progress iteratively with feedback* and *optimise and automate*, and its change enablement practice asks for authority close to the work.
- An automated deployment pipeline with tests, peer review and the ability to roll back is a **standard change procedure**: approved once, executed every time.
- Incident and problem management, service levels and service requests remain necessary however a team deploys. DevOps teams that run their own services discover them under other names: on-call, post-incident reviews, error budgets.

## What a lead should do in an ITIL organisation

An architect or lead joining an organisation with a weekly change board has a practical path. Show the record of a class of change — the same automated deployment, made many times, with its failure rate — and ask for it to become a **standard change**. Each class moved off the board shortens lead time without removing any real control, and the board's attention is left for the changes that are genuinely new. Lesson 13 measures the effect with the four DORA metrics, which come from the same research.
