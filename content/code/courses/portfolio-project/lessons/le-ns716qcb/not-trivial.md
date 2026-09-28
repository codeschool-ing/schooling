---
title: A brief that is not trivial
version: 1
---

A brief can be perfectly clear and still describe a project that proves nothing. *Store items, list
them, edit them, delete them* is clear, and it is the to-do list from lesson 2 with the nouns changed.
Reviewers call that shape **CRUD**, create, read, update and delete, and a project that is only CRUD
shows that you can wire a form to a table, which everybody applying can do.

What moves a brief away from trivial is at least one of these, and loanbook has all three:

- **A rule with a consequence.** Something the system must refuse, or a state that changes on its own.
  *An item cannot be lent twice* is a refusal; *a loan becomes late after seven days* is a state that
  changes with time. Each needs a decision about where it is enforced and a test that proves it.
- **An unhappy path that matters.** What happens when the input is wrong, when two people act at once,
  when the thing is used in a way nobody planned. The first story in Marta's message is an unhappy
  path, and it is the reason loanbook exists.
- **A real constraint.** Something about the world the project has to fit: forty users on old
  computers and phones, no budget for a hosted database, no accounts. A constraint forces a decision,
  and decisions are lesson 1's second proof.

If your brief has none of the three, it is worth one more conversation, real or imagined, asking
**what must never happen**. It is the question that found loanbook's rule, in the first line of
Marta's answer.
