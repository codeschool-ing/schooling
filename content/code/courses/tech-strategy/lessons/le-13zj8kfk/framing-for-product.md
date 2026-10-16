---
title: Framing the choice for product
version: 1
---

Once a decision is recognised as a product decision, it still has to reach product in a form
product can decide. Two habits get in the way, and both are common in good engineers.

The first is **presenting the recommendation as a necessity**: "we need to shorten the hold or the
database will fall over during on-sales." It is quick and it gets a yes, and it hides the trade.
Júlia agrees to a database fix and finds out from a venue that buyers are losing seats at the
payment step. The second is the opposite: a page of lock timeouts, transaction isolation and
connection pools that product cannot weigh, which ends with "so what do you want us to do?". **Both
leave the decision with engineering**, one by concealing it and one by burying it.

What works is a short set of options, each with its consequences written in the words of the people
who will feel them, followed by a recommendation.

## The note Davi and Mateus sent

> **Decision needed: how long Coreto holds a seat while a buyer pays**
>
> Why now: during big on-sales the seat holds queue in the database and checkout fails; this is
> the problem in our strategy's diagnosis. The length of the hold is one of the levers, and it is a
> choice about buyers, not only about the database.
>
> Option A, keep the hold as it is: slow buyers keep their seats. On-sales keep failing as they
> do now until the Reservations team's work on the locks lands.
>
> Option B, shorten the hold everywhere: fewer locks pile up during on-sales. Every buyer, on
> every show, has less time to pay; buyers whose bank asks for an extra confirmation will lose seats
> they were paying for, all year round.
>
> Option C, shorten the hold only during big on-sales: the shorter hold applies to the dozen or
> so on-sales a year where the locks queue, and buyers are told on the seat map how long they have.
> The rest of the year is unchanged. It costs the Checkout team some work to switch the setting per
> event.
>
> We recommend C, as a stopgap until the lock work is finished, after which we would go back to
> A. It can be reversed by changing one setting.
>
> What would change our mind: if venues tell you that a buyer losing a seat mid-payment hurts
> them more than a failed on-sale, A is the better choice and we live with the failures for two more
> quarters.
>
> We need an answer before the next big on-sale is scheduled, so the setting can be tested
> against Platform's load test first.

## What the note does

**Each option is described by who feels it.** "Buyers whose bank asks for an extra confirmation
will lose seats" is a sentence Júlia can put in front of a venue. "Reduce the lock TTL" is not.
The technical content is still there — it is why option C costs work — but it is in service of the
consequence rather than in place of it.

**The recommendation is separate from the options.** Engineering has a view and says it. Writing
the options first, fairly, and the recommendation after is what lets product disagree with the
recommendation without having to rebuild the options. A note whose options are built to make one
of them win is the necessity framing again, at greater length.

**It says which options can be undone.** A, B and C are all one setting away from each other, so
the decision is cheap to revisit. That changes how much care it deserves. Data retention is the
contrast: once records are deleted under a shorter retention period, no later decision brings them
back, and a note about retention has to say so in its first paragraph.

**It names the evidence that would flip it.** "What would change our mind" tells product where its
own knowledge outweighs engineering's. Here it is the venues' view, which Júlia has and Davi does
not.

**It asks for a decision by a date and says why that date.** An open question with no date gets
answered by the default, which for a disguised decision is the very thing the note was written to
prevent.

## Who decides

The note goes to Júlia because the consequences fall on buyers and venues, and those are hers. That
does not hand engineering's judgement to product. **Product owns the choice; engineering owns the
honesty of the consequences**: if the options are described accurately and Júlia picks one,
engineering builds it, and if she picks one the note warned against, the warning is on record.

That record matters later. Lesson 17 is about decision records, and a disguised decision is exactly
the kind worth one — the next engineer to see the hold length in a configuration file deserves to
know it was chosen, by whom and why. And when product and engineering disagree after a note like this, the disagreement is about a real trade with both sides visible, which is a much better argument to have. `people-leadership` lesson 22 covers that conflict, and `architect-communication` lesson 4 the wider craft of turning a technical risk into a business one.

| the framing | what Júlia hears | what it does to the decision |
|---|---|---|
| a necessity | "say yes or the database falls over" | hides the trade; product approves something it did not see |
| a technical briefing | "here is how locks work" | leaves the choice with engineering, by default |
| options with consequences | "here is who loses under each option, and what we would do" | puts the choice with the person who owns its outcome |
