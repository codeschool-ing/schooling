---
title: Twenty lines
version: 1
---

Here is loanbook's whole history, oldest first:

```
ana@laptop:~/loanbook$ git log --oneline --reverse
19e36eb Say what loanbook is for
64f0369 Serve a page with nothing on it yet
8623595 List the equipment from SQLite
3227967 Lend an item to somebody
28edce4 Take an item back
2fb7c61 Refuse to lend an item that is already out
55012ed Test the loan rules
b7f4c5f Answer every error as JSON
946c9a3 Say what to do when there is nothing to lend
5e90846 Mark a loan overdue the day after it is due
a087fae Label every field and announce what happened
be0bfbb Fit the table on a phone
69aa266 Refuse a borrower made of spaces
ff1a9d1 Read the database path and port from the environment
40303b1 Answer /healthz so a monitor can ask
ca4540f Build and run in a container
09f10f8 Deploy with systemd and Caddy
0f5e8a6 Seed a week that looks real
5579396 Explain how to run it and why it is built this way
c40ef55 License under MIT
```

Read only the subjects and the project explains itself. It said what it was for, served an empty
page, listed, lent, took back. Then it met the problem of lesson 5 and refused a second loan, tested
the rule, cleaned up its errors, handled the empty list, marked late loans. Then accessibility, the
phone, a bug found by a test, configuration for the container, a health check, the container, the
deploy. Then the things that make it worth showing.

That is what a reviewer gets from `git log --oneline` in ten seconds, and three things produce it.

- **Each line is one change.** Not *several fixes*, not *day 4*. One thing that can be described in
  one sentence, which is also one thing that can be reverted on its own.
- **Each subject says what the project does after the commit**, in the imperative: *refuse*, *mark*,
  *answer*, as if completing the sentence *this commit will…*. That is git's own convention, which is
  why git's generated messages read *Merge branch…* and *Revert…*.
- **The order is the order of the work.** Nothing here was reordered to look better. The accessibility
  commit comes after the rules because that is when it was done, and a reviewer can see it.

Compare the history this replaces, which everybody has written once:

```
a1b2c3d fix
d4e5f6a wip
b7c8d9e more changes
e0f1a2b fix tests
c3d4e5f final
f6a7b8c final 2
```

Six lines, and a reviewer knows nothing about the project and one thing about the author.
