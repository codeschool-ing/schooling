---
title: Every machine has an owner
version: 1
---

**A finding without an owner is a finding nobody fixes.** The drift report put a name beside every line
because `hosts.csv` has an `owner` column, and the two machines with no row got the one sentence the
report can say about them: nobody owns it. In an organisation larger than Jatobá that list grows into
a **configuration management database**, a CMDB, and its value is the same few fields kept true.

| field | what depends on it |
|---|---|
| owner | who receives the findings of lessons 1, 16 and 18, and who approves an exception |
| role | which baseline applies, and which ring of lesson 17 it belongs to |
| criticality | how lesson 16's priorities are weighed, and which ring goes last |
| address and name | how every tool finds it, and how a log line is traced back to it |
| lifecycle | when it was commissioned, when its operating system stops receiving updates, when it is retired |

**The owner is a person, not a team.** "IT" owns nothing: a finding sent to a team is read by
everybody and acted on by nobody. A person can delegate, but the name on the row is the one who
answers when the finding is late.

## The machines at the end of their life

Lifecycle is the field most often empty, and the one that fails most quietly. Ubuntu 24.04 receives
standard security updates until 2029; a machine still running it afterwards gets no fixes at all, and
lesson 16's comparison will show it clean, because no advisory will ever list a fixed version for a
release nobody fixes. **An end-of-life system is a finding that no scanner reports**, so the inventory
has to: the date is on the row, and the report flags it a year ahead.

## Keeping the list true

A list that is updated by memory decays. Three habits keep it honest:

- **The list is checked against measurement on a schedule**, as this lesson did: every unlisted
  machine and every listed one that did not answer is a line on a report somebody reads.
- **Adding a machine to the network and adding it to the list are one act.** Lesson 4's network access
  control can enforce it: a port opens only for a device the inventory knows.
- **Retiring a machine is a step, not an absence.** It is taken off the list, its keys are removed from
  the bastion and its address is released; otherwise the list and the network disagree in a way that
  looks like a missing machine.
