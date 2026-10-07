---
title: After: the summary, and the letter
version: 1
---

**When an incident is over, two documents are owed: a short summary within a day, to everybody who was
affected or told, and later the full postmortem, which lesson 15 is about.** The summary closes the
loop opened by the updates. Without it, the last thing people heard was "resolved", and the questions
that follow ("what happened?", "will it happen again?") are answered by rumour.

## The internal summary, within 24 hours

Lívia sent it on Saturday morning, to all of engineering, support and leadership:

> **Checkout incident, Friday 6 March, 19:09 to 19:41**
>
> **Impact.** For 32 minutes, most customers could not complete checkout. About 1,350 checkouts
> failed. No one was charged for a failed payment, and no order data was lost.
>
> **Cause, as far as we know.** A data backfill job for delivery zones was started at 19:05. It opened
> more connections to the orders database than the database allows, and checkout could not get any.
> Stopping the job at 19:38 restored checkout within three minutes.
>
> **Already done.** The backfill runbook now says not to run it between 17:00 and 22:00.
>
> **Next.** A blameless review on Tuesday at 14:00, open to anyone. The full write-up will follow by
> Friday 13 March.

Five short blocks: what, how bad, why (as far as known), what is already done, what happens next.
**"As far as we know" is not hedging; it is accuracy.** The full review often finds more than one
cause, and a summary that claimed certainty on Saturday would have to be corrected the following week.

## The customer letter

Customers who had a failed checkout received an email on Monday:

> On Friday evening, between 19:10 and 19:41, many of you could not complete your order. That was our
> fault, and we're sorry. You were not charged for any payment that failed. To make up for it, your
> next delivery fee is on us. We've already changed how we run maintenance so that it doesn't happen
> during busy hours, and we'll do more this week.

Four things a customer letter needs, and nothing else: **what happened in their terms, an apology that
takes responsibility, what it means for them (not charged, a credit), and that something has
changed.** No technology, no internal names, and no promise that it can never happen again.

## Why "that was our fault" is allowed here

Lesson 3 warned against apologies that admit what is not established. Here the cause *is* established,
and it was Marola's own system. Taking responsibility plainly for something that is plainly yours is
what makes the rest of the letter believable; hedging it would make Marola sound like it was blaming the
customer's phone.
