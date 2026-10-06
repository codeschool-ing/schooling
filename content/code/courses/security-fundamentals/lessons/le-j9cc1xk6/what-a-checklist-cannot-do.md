---
title: What a checklist cannot do
version: 1
---

Checklists are one of the most effective tools in security, and in many other fields: aviation and
surgery adopted them because experts under pressure forget steps they know perfectly well. A checklist
is also easy to over-trust, and its limits are worth stating as precisely as its strengths.

### It only knows what it was told

A checklist catches **known** problems: settings somebody already identified as risky, written down in
advance. It says nothing about the problem nobody listed. The shop's four lines say nothing about who
holds an SSH key to `www`, whether one of those keys belongs to somebody who left in March, or whether
the server should be reachable over SSH from the internet at all. Those questions belong to lessons 5 and
6, and a passing checklist does not answer them.

**All PASS means "no known misconfiguration", not "secure".** It is lesson 13's compliance-is-not-security
in miniature: the boxes can all be ticked while the risk that matters sits elsewhere.

### It is true on the day it runs

A server checked in March and changed in April is a different server. An administrator in a hurry
switches password logins back on to fix an urgent problem and forgets to switch them off; a package
update ships a new default; somebody copies a configuration from an old machine. This is
**configuration drift**, and the defence is the one the previous section ended on: run the checks
automatically and often, and treat a line that turns to `FAIL` as an alert. A checklist run once a year
for the auditor finds the drift eleven months late.

### It needs exceptions, written down

Sometimes a checklist item is wrong for one system. A server that must accept password logins from a
partner who cannot use keys is a real case. The answer is not to delete the line from the checklist, which
hides the decision, nor to let it fail forever, which teaches everybody to ignore failures. It is a
documented **exception**: the item, the system, the reason, who accepted it and until when, in the risk
register of lesson 3, with a compensating control from lesson 4 where one exists. The checklist then
reports the item as an accepted exception rather than a failure.

### It must be understood, not just run

A checklist applied without reading the rationale breaks things. A Level 2 setting that disables a
feature somebody depends on, applied blindly, becomes an outage, and the next time the team skips the
checklist entirely. Each line exists for a reason; the person applying it should know the reason, which
is why the shop's checklist has a "why" column and the benchmarks have a rationale for every item.

### Where it fits

None of this is an argument against checklists. It is an argument for using them as **one layer**:
the cheap, automatable layer that catches the large class of known mistakes, so that people's attention
is free for the questions only people can answer. In the CSF's terms of lesson 15, a checklist is a
strong tool for Protect and a weak one for everything else; in the shop's IG1 list, it is the first line
of control 4 and nothing more.
