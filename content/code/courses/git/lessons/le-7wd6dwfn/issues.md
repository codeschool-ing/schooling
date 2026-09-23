---
title: Issues: work written down before it starts
version: 1
---

Every hosting service has an **issue tracker**: a list of things somebody wants done, each with a
number. GitHub and GitLab call them issues, Bitbucket teams more often use Jira, and lesson 15 calls
the same thing a ticket. The name changes; the idea does not.

An issue carries:

- **a title** that says what is wrong or what is wanted, in one line;
- **a description** with enough detail for somebody else to start: what happens, what should happen,
  how to see it;
- **a number**, `#12`, which is how everything else refers to it;
- **an assignee**, the person doing it, and **labels** — *bug*, *menu*, *urgent* — for finding it among
  two hundred others.

**The number is the part that matters to Git.** A commit message or a pull request that mentions `#12`
becomes a link on the website, so the issue collects every change made for it. GitHub and GitLab go
further: a pull request whose description says `Closes #12` closes the issue automatically when it is
merged into the main branch. The history then answers *why was this changed?* by pointing at the
conversation where the reason was agreed.

## What an issue is not

It is not a place for the solution. *"The Sunday opening hours are missing from the home page"* is a
good issue; a list of the lines to change is not, because it decides the answer before anybody has
looked. The discussion of *how* belongs on the pull request, next to the code.

And it is not a promise. An issue can be closed without any change, because the problem was not real,
or was already fixed, or is not worth fixing. Closing it with a sentence saying which is part of the
job; lesson 16 comes back to the ticket that should not have been started.

## Why bother, for a two-person bakery site

Because the alternative is a chat message. *"Can you add Sunday hours?"* in a chat is gone in a week,
has no status, and cannot be linked from a commit. An issue is where the request, the decision and the
change end up together, and a year later that is the difference between knowing why the site says
*7:00* and guessing.
