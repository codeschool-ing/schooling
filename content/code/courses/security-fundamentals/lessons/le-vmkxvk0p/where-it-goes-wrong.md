---
title: Where it goes wrong
version: 1
---

The OWASP Top 10, the most widely used list of web application risks, put **broken access control**
in first place in its 2021 edition. Almost every case is one of a few mistakes, and each one is a
version of confusing the two questions of this lesson.

### Authenticated, therefore allowed

The portal checks the payslip's owner against the signed-in user. Imagine a version that did not:
any signed-in user could change `/payslips/ana` to `/payslips/bruno` in the address and read it.
This flaw has a name, **insecure direct object reference** (IDOR): the address refers directly to an
object, and the program never asks whether this user may have that object. It is common because it
is invisible in normal use. Every user who clicks the links they were given sees only their own
data, and only somebody who edits the address finds the hole.

### The check that lives in the page

A page that hides the "admin" menu from ordinary users has not stopped them using the admin
functions; it has stopped them seeing the button. If the server behind the button does not check
the role again, anybody who sends the same request directly, as `curl` did in the lab, gets
through. **Every check that matters runs on the server.**

### A missing check on one path

An application with forty pages checks permissions on thirty-nine. The fortieth, an export
added in a hurry, returns the whole customer list to anyone signed in. Access control fails at its
weakest page, which is why `secure-code` teaches putting the check in one place that every request
passes through, the way lesson 7's enforcement point sits in front of every resource.

### Answers that leak

A login form that says "no such user" for one mistake and "wrong password" for the other has told
an attacker which usernames exist. The lab's portal answers 401 for both, and its payslip pages
refuse before checking existence, both for the same reason: **a refusal should not answer a
question the person was not allowed to ask.**

### 401 and 403 are not cosmetic

Getting the codes right helps the people operating a system as much as its users. A rise in 401s
in the log is people failing to prove who they are: forgotten passwords, or somebody guessing.
A rise in 403s is people who proved who they are and are asking for things they may not have: a
role that is wrong, or an account being used by somebody exploring. Two different problems, and the
code says which one to look at. Lesson 11 is about turning signals like these into alerts.
