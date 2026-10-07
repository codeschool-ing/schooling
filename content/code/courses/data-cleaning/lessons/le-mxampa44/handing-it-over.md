---
title: Handing it over
version: 1
---

The test of everything in this lesson is a person who was not there. Somebody joins the team next
month, or an auditor asks how a number was produced, or the next course, `visualization`, needs
clean data to draw. What they should receive is short:

1. **The repository**, at a named commit: the code, the maps, `sources.csv`, `raw.sha256`.
2. **The raw files**, or where to get them, matching the manifest.
3. **One command**, `python run.py && python checks.py`, which rebuilds `out/` and proves the
   promises hold.
4. **`out/changes.csv`**, which lists every value that differs from what arrived, and why.

Nothing else should be needed, and in particular nothing that lives only in somebody's head. Every
decision in this course, from lesson 2's choice to read everything as text to lesson 14's choice not
to send postcodes to a web service, is either in a file or in a rule in the code.

It is worth listing, one last time, what the clean data does **not** promise, because a handover
that only lists achievements invites overconfidence:

- **The survey's NPS describes who answered**, not the customers; lesson 3 measured the gap.
- **Delivery times of the own fleet stop at 120 minutes**, and the blanks are not random.
- **246 orders have no customer details**, for two different reasons, and the 12 erased customers
  must stay unidentified.
- **The two product codes missing from the catalogue have no name or category.**

A pipeline that states its limits beside its outputs is the last piece of the course's argument:
**clean data is not data without problems; it is data whose problems are known, measured and
written down.**
