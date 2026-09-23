---
title: Disagreeing well, and knowing when to stop
version: 1
---

Sometimes the reviewer is wrong, and saying so is part of the job. A pull request where the author accepted
every comment to avoid friction is not a good review. It is a review in which only one person thought.

## Disagree once, with a reason

Suppose Ana had written *"blocking: use a list of times instead of a time field."* Bruno thinks the field is
better, because a list of thirty options is slow to use on a phone. The reply that works:

> I went with the time field because a list of every half hour is thirty options, and most orders come
> from phones. With `min` and `max` it cannot go outside opening hours. Does that cover what you were worried about?

It says **what he chose, why, and asks what the worry was**. Maybe Ana's worry was customers typing 7:13;
then the answer is `step="1800"`, and both of them were partly right. A reply that says *"I prefer the
field"* gives her nothing to weigh, and the thread goes round again.

## When to stop typing

Two rounds of replies that do not converge is the signal. A third written round rarely settles anything, and
each message gets a little shorter and a little colder. **Talk instead**: a five-minute call, or a
conversation at the next desk. Then write the outcome on the thread in one line, so the record says what was
decided and why, for whoever reads it later.

## Who decides

- **A blocking defect** (it does not work, it loses data, it is unsafe): fixed before merging, and a reviewer
  should not approve until it is.
- **A preference labelled as blocking**: the author may push back, as above. If it is a preference on both
  sides and nothing is at stake, **the cheapest thing is often to just do it** and spend the energy elsewhere.
  Do it once. If it keeps coming up, it is not a review question any more.
- **A pattern that keeps coming back** (two people who disagree about the same thing in every pull request)
  belongs to the team, not to the thread. Decide it once and write it down, in the same `CONTRIBUTING.md`
  lesson 9 suggested. After that, the answer to the comment is a link.

## Afterwards

Say thanks, and mean it. Somebody spent half an hour reading your work so a customer would not have to find
its bugs. Then notice what came up. If three reviews in a row find a missing `required`, that is a checklist
item for the next form, and the fourth review will not need to say it.
