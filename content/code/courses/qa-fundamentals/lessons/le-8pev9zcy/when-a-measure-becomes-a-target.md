---
title: When a measure becomes a target
version: 1
---

**A number that is used to judge people stops measuring what it measured, because people start working on the
number.** The economist Charles Goodhart made the observation about monetary policy in 1975, and the anthropologist
Marilyn Strathern gave it the form usually quoted: *when a measure becomes a target, it ceases to be a good measure.* It
is called **Goodhart's law**, and testing is full of it.

This is not a complaint about people cheating. Most of the damage is done by honest people doing what they were asked.
If the number is what is rewarded, the number is what gets improved, by the cheapest route available, and the cheapest
route rarely goes through quality.

## The pattern, five times

| the target | what people reasonably do | what happens to quality |
|---|---|---|
| more test cases per sprint | write smaller, more obvious cases | coverage of what matters does not move |
| more defects found per tester | report each symptom separately; avoid long investigations | the subtle defects, which take a day each, stop being found |
| fewer defects open at release | close defects as "won't fix" or downgrade them on the last day | the release looks clean and is not |
| higher code coverage | write tests that run lines without checking results | lesson 7: a line run is not a line checked |
| shorter lead time on the board | move cards to *done* before they are tested | lesson 13: the diagram looks wonderful |

Every row has already appeared in this course, usually as a warning. Here they are in one place, because they are the
same mistake.

## Why testing numbers are especially vulnerable

Most testing numbers count **activity** or **defects**, and both are easy to change without changing the product.
Activity can be made larger by splitting it; defects can be made fewer by not looking, or more by looking at the
trivial. A number that can be moved without moving quality will be, once somebody's bonus depends on it.

There is a second, quieter effect. A team measured on defects found starts to see developers as the source of its
score, and the whole-team approach of lesson 5 dies on the spot. Testing becomes a contest between the people who write
defects and the people who find them, which is exactly the relationship this course has argued against from the start.

## Metrics theatre

When numbers stop informing decisions and start being performed, the result is **metrics theatre**: a dashboard updated
every week, presented at every review, believed by nobody and acted on by nobody. Its signs are easy to spot:

- the numbers always go the right way;
- nobody can say what decision the last change in a number led to;
- people spend more time producing the report than the report saves;
- a question about a number is answered with a story about why it is fine.

The cure is not more numbers. It is fewer, each with a question above it, looked at by the people who make decisions,
and never used to rank the people who produce it.
