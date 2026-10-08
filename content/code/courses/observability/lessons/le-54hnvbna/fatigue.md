---
title: Noise, and the team that stops reading alerts
version: 2
---

**Alert fatigue** is what happens to a team that is paged often for things that need no action. The
mechanism is human and reliable: the third page in a night that turned out to be nothing is read more
slowly than the first, and somewhere after that a real page is dismissed with the others. Every
noisy alert spends the attention that the important one will need.

The sources of noise are few, and each has a fix this course has already built:

| noise | fix |
|---|---|
| alerts on causes that often heal themselves | page on the symptom; causes become tickets |
| one short blip, at any hour | two windows: the long one for size, the short one for now |
| one failure, a hundred alerts | grouping in Alertmanager, and inhibition of tickets by pages |
| alerts during planned work | silences, with a reason and an end |
| a threshold nobody remembers choosing | a burn rate derived from the objective |

And one habit no tool provides: **review every page.** Once a week, whoever was on call reads the list
of pages with the team and asks of each one: *was it real, did it need a person, and did it need one
at that hour?* A page that fails the test is changed that week: its threshold moved, its severity
lowered, or the alert deleted. A team that does this keeps its pages rare and true; a team that does
not ends up with an alert channel nobody reads.

Two numbers make the review honest. **Pages per on-call shift** shows the load; Google's SRE book
suggests no more than two incidents a shift, so that each gets the attention it deserves.
**Actionable pages as a share of all pages** shows the noise; anything well below one half is a pager
training its owner to ignore it. Both can come from Alertmanager's own records, and lesson 18 puts
them into the on-call routine.

Before the next lesson, take this lesson's rules and override away:

```sh
rm prometheus/rules/burn.yml compose.override.yaml
curl -s -X POST localhost:9090/-/reload
docker compose up -d alertmanager
```
