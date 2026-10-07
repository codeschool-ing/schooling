---
title: The author's half of the review
version: 1
---

**A review teaches as much as the change allows it to, and the author decides how much that is.** A
2,000-line pull request with no description gets a skim and an approval; a 200-line one that says what
it does and why gets read. The author's side of the review is mostly about making the reviewer's
attention go where it is needed.

## Small changes get real reviews

A widely cited study of code review at Cisco, run by SmartBear in 2006, found that reviewers' ability
to find defects fell sharply once a review went past about 400 lines, and once a reviewer went faster
than about 500 lines an hour. The exact numbers depend on the team and the code. The shape is not in
doubt and every reviewer has felt it: **past a certain size, a reviewer stops reading and starts
scrolling.**

So the author splits the work. A change that renames a module, fixes a bug and adds a feature is three
pull requests, each small enough to be read, and each reviewable on its own terms.

## The description is a short document

Lesson 1 applies directly: a pull request description is read by the reviewer first, and by whoever
runs `git log` on the file a year later. Rafael's second pull request, after Diego's review, had
this description:

> **What.** Delivery windows stop at the depot's closing time, which now comes from the opening-hours
> table instead of a constant.
>
> **Why.** Drivers were offered windows after closing (22:00 and later). See Diego's review on the
> previous PR.
>
> **How to check.** `test_slots.py` covers 21:10 on a weekday, 18:30 on a Saturday (closes at 19:00)
> and a closed Sunday.
>
> **Not in this PR.** Holidays: the table doesn't have them yet; separate issue linked.

Four short blocks: what changed, why, how to verify it, and what was deliberately left out. The last
one prevents the most common review comment, "what about holidays?", by answering it in advance.

## Review your own change first

Before asking anybody, read your own diff in the review tool, as the reviewer will see it. It is
surprising how often the author finds the debugging line left in, the commented-out block, or the
test that was meant to be written. **Every problem the author catches is one the reviewer does not
spend a comment on**, and that comment can go to the design instead.

## Answering comments

The author owes every comment an answer, the same three states as an RFC comment in lesson 2: changed,
declined with a reason, or recorded for later. "Done" is a fine answer to a nitpick. A suggestion the
author disagrees with gets a reason, and **disagreeing with a reviewer is part of the job**, including
a junior disagreeing with a senior, as long as the reason is about the code.
