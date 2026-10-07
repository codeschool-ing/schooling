---
title: Reviewing a junior's code
version: 1
---

**When the author is learning, the review has two jobs: get the change right, and leave the author
able to get the next one right without you.** The second job changes what the reviewer does. Fixing
the code yourself, or writing the exact line to use, gets the first job done and skips the second.

## Fewer comments, chosen

A senior reviewer can usually find twenty things to say about a new engineer's pull request. Posting
all twenty buries the two that matter and teaches the author that every review is a list of failures.
**Pick the comments that teach something transferable, and let the rest go**, or batch them into one
note: "a few small naming things, take or leave them".

Lívia's rule of thumb when reviewing with Diego: at most one *issue* that is about learning rather than
about correctness per review. Correctness issues always get a comment. Learning comments are rationed,
so that each one is heard.

## Point, do not solve

| instead of | write |
|---|---|
| "Change line 12 to `slots = [first + timedelta(hours=i) for i in range(count)]`" | "nitpick: this loop could be a comprehension; worth trying if you haven't used one for this" |
| "This is wrong, use the opening-hours table" | "issue: the closing time is a constant here, but logistics has a table of opening hours. Can you find it and use it?" |
| "Why did you do it like this?" | "question: what made you choose a constant over the table? I want to understand before suggesting anything" |

The left-hand column gets the change fixed faster. The right-hand column gets the author to do the
finding, which is the part they need to practise.

## Review together, sometimes

For a new engineer's first few pull requests, a twenty-minute call reading the diff together teaches
more than any number of written comments. The reviewer can ask "talk me through this part" and hear
the author's reasoning, which a written review never shows. Lesson 12 makes the same point about pair
programming: **some knowledge only transfers when two people look at the same thing at the same time.**

## Tone, which is read as louder than intended

Written comments lose the tone of voice, and a short comment from a senior person to a junior one is
read as harsher than it was written. "Why?" reads as "this is wrong". Three habits help: **write in full
sentences, say what you liked, and use "we" for the codebase** ("we usually put these in the config")
rather than "you" for the person. And when a review thread starts going back and forth, move it to a
call, the same rule as for any disagreement in lesson 9.
