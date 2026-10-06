---
title: SOC and incident response
version: 1
---

The **security operations centre (SOC)** is where lessons 10 and 11 become a job. It collects logs from
across the organisation, runs detection rules over them, and has people looking at the alerts that come
out, often around the clock in shifts.

### The work

| task | what it means | where you met it |
|---|---|---|
| **triage** | look at an alert, decide whether it is real, how serious, and what happens next | lesson 11's four outcomes, decided by a person |
| **investigation** | follow a real alert back: which account, which machine, what else it touched | lesson 4's log, read for a story |
| **detection engineering** | write and tune rules, cut false positives, close gaps found in exercises | lesson 11's thresholds; lesson 10's purple loop |
| **incident response** | contain, eradicate, recover, and write up what happened | lesson 12's restore; lesson 17's three working days |

### A day

A first-line SOC analyst's shift is mostly triage: a queue of alerts, each closed as harmless with a note
saying why, or escalated to a more experienced analyst. The skill being built is judgement under volume,
and lesson 11's base-rate arithmetic is the reason it is hard: most of the queue is noise, and the one
real alert looks like the rest. Analysts who write good notes on what they closed and why are the ones
whose escalations get taken seriously.

Many SOCs organise people in **tiers**: tier 1 triages, tier 2 investigates what tier 1 escalates, tier 3
hunts for what no alert caught and builds detections. The names vary; the idea of increasing depth does not.

### What it asks of you

Patience with repetitive work, curiosity about the one alert that is different, and enough of networks,
operating systems and logs to read what a machine was doing. It is the most common first job in security,
because organisations need many analysts and the work teaches the whole field: every attack technique
eventually shows up in somebody's queue.

**Incident response** is the senior end of the same family. When something real happens, the responders
lead the containment and the recovery, coordinate with management, legal and communications, and run the
lessons-learned meeting afterwards. `soc-response` covers the SOC and the whole response cycle, from
preparation to the post-incident report.
