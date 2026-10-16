---
title: Why the four numbers do not rank teams
version: 1
---

The DORA reports group thousands of organisations into performance clusters, and it is a short step from there to a spreadsheet that ranks a company's own teams by their four numbers. **That step is a mistake**, and it fails in three separate ways, any one of which would be enough.

## The systems are different

Take two teams in the same company. One runs a web service in containers and can ship a change in minutes; it deploys fifteen times a day. The other builds the point-of-sale app that runs on the shops' own tablets; every release goes through the app stores' review, which takes from hours to days, and shops update when they choose. It releases every two weeks.

Ranked by deployment frequency, the first team is a hundred times better. In fact neither number says anything about how good either team is, because **each is mostly a property of what the team ships, not of how it works**. The tablet team could be outstanding and still never deploy daily; asking it to would be asking the app stores to change.

## The definitions are different

Lesson 5 listed the choices hidden in each metric: what counts as a deployment, which commit starts lead time, what counts as a failure, when restoring starts. Two teams that made those choices differently are not measuring the same thing, and a company with twenty teams has twenty sets of choices unless somebody has written one down for all of them. Even then, a definition written for a web service does not fit firmware.

## Ranking changes what is measured

The third failure is the one that makes the first two worse. **Once teams know they are ranked, the numbers start answering a different question**: not "how do we deliver?" but "how do we look?". Splitting deployments, redefining failures and starting the clock later are all available, each is defensible on its own, and each improves the rank without improving the team. Lesson 7 is a catalogue of exactly these moves, and lesson 20 is about the rules that stop them.

## What to compare instead

**A team against its own past.** The Billing team in September against the Billing team in June is a fair comparison: same system, same definitions, and a change everyone knows about in between. That is how this course has used the numbers in every lesson.

**Questions, not ranks, across teams.** Across a company, the four are useful as a way to find teams worth talking to: "your time to restore is much longer than the others'; what makes recovery hard for you?" is a conversation that can find a missing capability. "You are last in the table" is a sentence that teaches a team to change the table.
