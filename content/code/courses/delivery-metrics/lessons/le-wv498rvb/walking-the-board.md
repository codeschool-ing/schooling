---
title: Walking the board, and the item nobody is looking at
version: 1
---

Most standups go round the people: each person says what they did yesterday, what they will do today, and whether anything is in their way. That format has a structural blind spot, and `BIL-189` fell into it. **An item that nobody is working on is mentioned by nobody**, because every person truthfully reports what they are doing, and nobody is doing that.

## Walk the items instead

The alternative is to walk the board: go through the items rather than the people, **from the right-hand column to the left**, oldest first within each column. For each item the question is the same: what does this need to move today? People still speak, but about items. The order puts the work closest to done, and the oldest work, at the top of the conversation, which is where finishing pays most.

Walked that way, the Billing team's standup on 30 September would have started with the review column, where `BIL-219` had been for less than a day, and then reached development, where the first item, by age, was `BIL-189`, forty days old. It is hard to skip an item that is first on the list.

## Rules that keep the stuck item visible

Three policies close the gap the Billing team's new rule left open. Each is a sentence written on the board, so that nobody has to remember it.

- **A blocked item stays where it is, marked, and keeps ageing.** It does not move to a separate list. If the team wants to see blocked items together, it marks them on the board, it does not move them off it.
- **A blocked item counts against the limit.** Otherwise the limit has a door in it, and every awkward item walks through it. Lesson 4 comes back to this.
- **An item past the 85th percentile gets a named owner for unblocking it**, by the end of the day. Not necessarily its developer: often it is the tech lead, because the block is in another team, and getting another team to move is precisely the tech lead's job.

## Why it matters more than one bug

`BIL-189` is one point. Its cost is not its size; it is what it says about the system. An item that can sit unseen for forty days on a board walked every morning means the board is not, in practice, how the team sees its work. And the customer who reported the bug has been waiting since July, which is the lead time lesson 2 taught you to care about.

The ageing chart and the walk are cheap. Together they are the difference between a team that learns about a stuck item from an angry customer and a team that learns about it on the day it crosses the median.
