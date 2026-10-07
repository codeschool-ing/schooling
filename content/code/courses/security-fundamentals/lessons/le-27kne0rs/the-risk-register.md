---
title: The risk register
version: 1
---

Everything in this lesson so far has to live somewhere, or it lives in one person's memory and
leaves with them. **The risk register is the document that holds the organisation's risks, their
scores, their treatments and their owners**, and it is the first thing an auditor asks to see.

It is a table. A spreadsheet is enough for a shop of nine people; larger organisations use a tool
for it, and the columns are the same. One row of the shop's register, written out in full:

| field | R1 |
|---|---|
| id | R1 |
| description | a criminal scanning the internet logs in to the staff portal with the installer's default password and reads the payroll file |
| asset | payroll file (confidentiality) |
| owner | bruno, finance |
| inherent likelihood × impact | 4 × 4 = 16 |
| treatment | mitigate |
| controls | unique password; MFA; portal reachable only from the office network |
| residual likelihood × impact | 1 × 4 = 4 |
| accepted by, on | bruno, 2026-09-14 |
| next review | 2027-03-14 |
| status | controls in place |

Three columns carry most of the value.

**The description is a sentence, not a word.** "Portal" is not a risk. The chain from lesson 2,
threat, vulnerability, asset and impact, is what lets somebody six months from now understand what
was meant and check whether it is still true. If the portal is later rebuilt with a different
login, the sentence says at once whether this row still applies.

**The owner is a person.** "IT" or "management" cannot be asked a question or sign a decision.

**The review date is a promise.** Risks move: the shop starts taking orders by phone, a new law
changes the impact of a leak, a control that worked stops being maintained. A register that is
written once and filed is a snapshot of a shop that no longer exists. The shop reviews its
register every six months and whenever something large changes, and lesson 15's NIST functions
and lesson 14's ISO management system both make that review a requirement rather than a habit.

### What a register is not

It is not a list of vulnerabilities from a scanner. A scanner produces findings, and the most
severe finding on a machine nobody uses belongs nowhere near the top of this table. Findings feed
the register when they create or change a risk; most of them never become a row.

It is not a record of everything that could conceivably happen either. A register with four
hundred rows is one nobody reads. The skill is the one this lesson has practised: write the risks
that matter as sentences, rank them, decide, sign and come back to them.
