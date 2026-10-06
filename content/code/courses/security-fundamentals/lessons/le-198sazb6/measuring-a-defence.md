---
title: Measuring a defence
version: 1
---

Red, blue and purple are ways of finding out how good a defence is, and that finding out is worth
more when it produces numbers that can be compared from one exercise to the next. Three kinds are in
common use.

### Coverage: which techniques would we see?

Attackers reuse a fairly stable set of techniques, and **MITRE ATT&CK** is a public catalogue of them,
organised by what the attacker is trying to achieve at each stage: getting in, staying, moving,
taking data out. A blue team can mark each technique as detected, partly detected or not detected,
and purple exercises are how those marks get proved rather than assumed. The result is a map of
where the defence is blind. `attacks-threats` lesson 26 explains the catalogue itself.

### Time: how long until we notice, and until it stops?

| measure | what it counts |
|---|---|
| **time to detect** | from the moment something happens to the moment somebody knows |
| **time to respond** | from knowing to having contained it |
| **dwell time** | how long an attacker was inside before being found |

These are usually reported as averages across incidents and exercises, as **MTTD** and **MTTR**, mean
time to detect and to respond. The previous section's exercise could not have produced either number
for password guessing, because the log had no times in it; fixing that is what makes the measure
possible at all.

### Practice: do the people know what to do?

Not every exercise needs a red team. A **tabletop exercise** is a meeting in which somebody describes
an incident step by step, "the shop's server is encrypted and a ransom note is on the screen", and the
people who would respond say what they would do at each step. It costs an afternoon and finds the
gaps that only show up under pressure: nobody knows where the backup is kept, the owners' phone
numbers are on the encrypted server, the insurance company's number is in an email nobody can open.
Lesson 12 builds the backup that answers the first of those.

### How often

A defence changes every time the systems change, so a test from last year describes last year's shop.
A sensible rhythm for an organisation the shop's size: a purple check whenever a control is added or
changed, as in this lesson's exercise; a tabletop exercise once a year; and, once the basics are in
place, an external penetration test of what faces the internet. Lesson 18 describes the careers on
both sides of these exercises, and `soc-response` and `pentest` are the courses that teach each side
properly.
