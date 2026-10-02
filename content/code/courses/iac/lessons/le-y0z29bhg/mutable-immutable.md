---
title: Changing a server, or replacing it
version: 1
---

Declaring what should exist settles *what*. It leaves open *how* a running thing gets from what it
is to what it should be, and there are two answers with very different consequences.

**Mutable infrastructure changes things in place.** A new version of the shop's web server means
logging in to each machine (or letting a tool log in) and upgrading the package, editing the file,
restarting the service. The machine keeps its name, its address and its disk, and carries the
history of every change ever made to it. That is how almost every server was run for decades, and
it is how configuration management tools began.

**Immutable infrastructure never changes a running thing.** A new version means a new machine, built
from scratch with the new version on it, put into service, and the old one destroyed. Nothing is
ever edited, so nothing can drift: a machine is exactly what it was built as, until the day it is
thrown away.

| | mutable | immutable |
|---|---|---|
| a change is | an edit to what is running | a new copy, then a swap |
| drift | accumulates on every machine | has nowhere to live |
| rolling back | undo the edit, if anybody knows what it was | start the previous copy again |
| what it needs | access into running machines | a fast way to build and replace them |
| what it costs | nothing up front | a build step, and a design where losing one machine is fine |

The second column is the reason Terraform's plans, from lesson 2 onwards, show some changes as an
update and others as **replace**: for many attributes the cloud itself offers no edit, and the only
way to change them is a new resource. A machine's image is one. Lesson 6 is about controlling that
choice, and lesson 20 about building the images that make replacement the normal way of working.

**Neither column is a virtue in itself.** A database is the clearest mutable thing there is,
because its whole value is the data that has accumulated on it. The usual arrangement keeps the
state in a few carefully managed places (a database, a bucket) and makes everything around them
replaceable. The trade has a nickname, *pets and cattle*: a pet has a name and is nursed back to
health; cattle are numbered, and a sick one is replaced. The question for any machine you look
after is which of the two it ought to be, and whether that is what it is.
