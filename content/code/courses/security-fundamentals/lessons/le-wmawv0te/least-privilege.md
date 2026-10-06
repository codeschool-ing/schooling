---
title: Least privilege
version: 1
---

**The principle of least privilege says that every person, program and system gets only the access
its task needs, and only for as long as it needs it.** It is old: Jerome Saltzer and Michael
Schroeder listed it in 1975 among the design principles for protecting information in computers,
and nothing since has made it less true.

The usual objection is about trust: "I trust my staff, why limit them?" That misreads what the
principle protects against. Least privilege is not a judgement about a person's honesty. It limits
the **damage** of anything that goes wrong while acting as that person, and most of what goes wrong
is not the person:

| what goes wrong | without least privilege | with it |
|---|---|---|
| a staff member's password leaks | the attacker has everything that person could touch | the attacker has only what the job needed |
| a program has a bug | the bug can do anything the program's account can | the bug is confined to a small account |
| somebody makes a mistake | a wrong command can delete anything | a wrong command fails for lack of permission |
| malware runs on a laptop | it runs as whoever is logged in | an everyday account cannot install it system-wide |

Every row is a case where the person was trustworthy and the access still did harm. **The smaller
the access, the smaller the blast radius**, which is the phrase people use for how far damage spreads
from one failure.

### Two related ideas

**Need to know** is least privilege applied to information. A person may have the clearance or the
role to see a category of data and still be given only the part their current task requires. bruno
in finance needs the salaries; the person packing orders needs the delivery address and not the
customer's purchase history.

**Default deny** is the same idea applied to rules, and lesson 5 already used it on the network:
start from nothing allowed and add what is needed. A system designed the other way, everything
allowed and some things removed, leaks every permission somebody forgot to remove.

### What least privilege costs

It is not free. Every permission that has to be granted is a request somebody makes and somebody
approves, and every task that needs a permission nobody predicted is a delay. The common failure is
to give up on the principle after the third delay and make everybody an administrator. The fix is
to make granting access quick and recorded, not to grant everything in advance. Lesson 3's risk
register is where a deliberate exception goes, with a reason and a date.
