---
title: The description
version: 1
---

A pull request has a description, and for a portfolio project it is one of the most-read things in the
repository: a reviewer who opens the *pull requests* tab reads descriptions before diffs. Four short
parts cover it:

```localised
Say what to do when there is nothing to lend

What: when the list is empty, the page says so and says how to add equipment,
instead of showing a table with only its header.

Why: the first time Marta opened it on the server, before anything was added,
she thought the page was broken (#6).

How I checked: opened it with an empty database and with the seed data; the
message shows in the first case and not in the second. No test: this is
markup and a single line of JavaScript.

Not in this change: the table builds rows with innerHTML, so a borrower's name
is drawn as markup. It predates this change; opened #7 for it.

Closes #6
```

**What** is the change in one or two sentences, from the user's side. **Why** is the reason, ideally
something that happened. **How I checked** is the part people skip and reviewers value most: it says
what you ran and looked at, and, just as important, what you decided not to test and why. **Not in
this change** is where the problem found in review goes, with its card number, so it is recorded
without being fixed here.

For a change to the interface, a screenshot, before and after, saves a reviewer from running anything.

Open the pull request even though you will merge it yourself. It costs a minute, it runs any checks
the repository has, lesson 12, and it leaves the description where the next reader will find it.
