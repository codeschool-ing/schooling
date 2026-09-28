---
title: Tasks you can finish in a day
version: 1
---

A bucket is still too big to start on. *Refuse a second loan* is one line of the list and, in
practice, a decision, a schema change, a new error, a change to the page and a test. So the last
step of scoping is breaking each must into **tasks of a day or less**.

loanbook's must bucket, broken down, with the estimate written beside each task before starting:

```localised
must: refuse a second loan
  [ ] decide where the rule lives (database or code)          0.5 day
  [ ] add the partial unique index; turn the error into 409    0.5 day
  [ ] show the refusal on the page                             0.5 day
  [ ] test: second loan refused; returned item lends again     0.5 day
must: show what is late
  [ ] compute overdue when listing                             0.5 day
  [ ] mark it on the page                                      0.5 day
  [ ] test: late the day after the due date, not on it         0.5 day
```

Three things a list like this buys. **A task of a day either finishes or tells you something**: if it
takes three, you learned that the estimate was wrong while it was still one task, not after the whole
milestone slipped. **Every task has a visible end**, which is what lesson 8's board tracks. And **the
first task of a hard item is a decision**, written down, which later becomes a line in the README.

Write the estimates before starting, and keep them. Comparing them with what happened is half of
lesson 21's retrospective, and it is the only way your next estimate gets better.
