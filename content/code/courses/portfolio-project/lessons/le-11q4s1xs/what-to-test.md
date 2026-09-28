---
title: What to test, and what not to
version: 1
---

Tests cost time to write and time to keep working as the code changes. In a six-week project, spend
that time where a failure would be **wrong**, not merely **visible**. Three places qualify almost
always:

- **The rules.** What the system refuses and what changes state on its own. In loanbook: the second
  loan, the return of an item that is in, the date a loan becomes late.
- **The bug you just fixed.** A bug that happened once can happen again, and a test for it is the
  only thing that stops it coming back unnoticed.
- **The edge of a rule.** *Late the day after it is due* has an edge: the due date itself. A test on
  both sides of it is worth more than ten in the middle.

And three places that usually are not worth it in a small project. **Getters and plumbing** only move a
value from one place to another. **The framework or the library** has its own tests. And **the exact
layout of a page** changes every week, and you see its failures anyway.

loanbook's list is short and follows the brief of lesson 4 almost line by line:

| test | the brief's line |
|---|---|
| an item cannot be lent twice | *a second loan of an item that is out is refused, with who has it* |
| a returned item can be lent again | *a returned item shows as available straight away* |
| a loan is overdue the day after it is due | *a loan is marked late the day after it is due* |
| a borrower made of spaces is refused | the bug of lesson 9 |
| a lent item shows who has it; an item that is in cannot come back; an unknown item is not found | the rest of the rules |
