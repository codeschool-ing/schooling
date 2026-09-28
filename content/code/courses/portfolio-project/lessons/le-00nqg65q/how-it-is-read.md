---
title: How a reviewer reads a history
version: 1
---

A reviewer does not read twenty commits from top to bottom. They sample, as lesson 1 said, and a good
history gives them places to start.

**The subjects, in a range.** Between two tags, the log is a milestone's story, with its dates:

```
ana@laptop:~/loanbook$ git log --format='%h %ad %s' --date=short v0.2.0..v0.3.0
09f10f8 2026-06-29 Deploy with systemd and Caddy
ca4540f 2026-06-26 Build and run in a container
40303b1 2026-06-25 Answer /healthz so a monitor can ask
ff1a9d1 2026-06-24 Read the database path and port from the environment
69aa266 2026-06-22 Refuse a borrower made of spaces
be0bfbb 2026-06-18 Fit the table on a phone
a087fae 2026-06-17 Label every field and announce what happened
```

**One commit in full**, usually the one with the most interesting subject. `git show` gives the
message and the diff together; the reviewer reads the message and checks that the diff does what
it says. If it does, they trust the other subjects without opening them.

**The links**, if there are any: a `Closes #3` takes them to the issue and its discussion, lesson 8.

Three things to make sure of before anybody reads it:

- **No commit breaks the build.** A reviewer who checks out a tag or a commit from the middle expects
  it to run. A history where every other commit fails its tests says the tests were run once, at the end.
- **No secret, and no debugging, in any commit.** Deleting a key in a later commit does not remove it
  from the earlier one; lesson 14 is about this.
- **Your name and e-mail are the ones you want on it.** Every commit carries them, publicly; lesson 18
  shows how to use a no-reply address.

A history that passes those three and reads like the one in this lesson is evidence of the thing a
team most wants to know about a new colleague: **what their work looks like when nobody is watching.**
