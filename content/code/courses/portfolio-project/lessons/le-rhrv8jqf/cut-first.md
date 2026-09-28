---
title: What to cut first
version: 1
---

Not all features cost the same. Some sit in one corner of the project; others run through all of it.
**Cut first what multiplies**: the features that add work to every other feature.

| feature | what it multiplies |
|---|---|
| accounts and login | every route needs a check, every screen a signed-in and a signed-out state, every test a user |
| roles and permissions | every action needs *who may do this*, and every test runs once per role |
| notifications by e-mail | a mail server or provider, templates, failures to retry, and a way to test it that sends nothing |
| an admin area | a second interface, with its own forms, validation and access control |
| several languages | every string twice, and every layout tested with the longer one |
| multiple organisations | every table and every query gets a *which one*, and a mistake leaks data between them |

None of these is a bad idea, and each is common in real systems. That is precisely the problem: in a
six-week project, any one of them can take half the time, and **none of them is the point** of most
projects. A reviewer has seen a thousand logins; they have not seen your rule.

So the order is: cut what multiplies, then what is large, then what is merely nice. The first cut
usually frees more time than all the others together, which is why loanbook's first decision in lesson
4's brief was *the borrower is a name typed in*.
