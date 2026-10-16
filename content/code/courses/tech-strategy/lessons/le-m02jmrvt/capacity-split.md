---
title: A capacity split, agreed before the arguments
version: 1
---

Every planning meeting at Coreto used to hold the same argument. A product item and a piece of
engineering work were compared, one against the other, and the engineering work lost. It did not
lose because anybody was unreasonable. **It lost because the comparison was built to make it lose**,
and the fix is to stop holding that comparison at all.

## Why item-by-item always tips one way

Put a feature and a debt item side by side and look at what each brings to the meeting. The
feature has a customer, a date somebody promised and a person in the room who wants it. The debt item
has a payoff that is spread across many future sprints and belongs to nobody in particular. Each
single decision to defer it looks sensible, and each one is.

The sum is not. Lesson 5 priced the seat-hold debt as interest: about 31 engineer-hours a sprint,
paid whether anybody decides to or not, and growing when nobody touches it. A team that defers the
fix one sprint at a time pays that interest every sprint, and no meeting ever sees the total,
because no meeting looks at more than one sprint.

There is a second wrong answer, and teams reach for it once they notice the first. **Engineers
start hiding the investment inside feature estimates.** A feature is quoted with room in it, and the
room goes to the refactoring nobody would have approved. It works for a while. Then
product learns that estimates carry padding, starts discounting every estimate, and loses the one
signal it had about how long things take. Engineering's honest estimates get cut along with the
padded ones.

## A share agreed in advance

The alternative is to make the decision once, for a period, and then stop re-arguing it. Product,
engineering and the CTO agree what share of each team's capacity goes to engineering investment.
**Inside that share engineering chooses the work.** Outside it, product does.

Coreto's agreement, made in January between Júlia Sato, Davi and Helena Prates, reads like this:

> **Capacity split for the year**
>
> Each product team keeps one fifth of every sprint for engineering investment: debt repayment,
> upgrades, adoption of the platform's golden paths, and the work the technical strategy asks of
> that team. The tech lead chooses what goes in it and publishes the list at sprint planning.
> Product sees the list and may question it, and does not approve it item by item.
>
> The Reservations team is outside this split. For its first two quarters, all of its capacity is
> engineering investment, as the strategy's third action says.
>
> In the on-sale season a team may lend its share to product work for one sprint at a time. Every
> sprint lent is repaid in the next quarter, and the tech lead records both in the sprint notes.
>
> We review the share each quarter, against what it bought.

**One fifth is Coreto's choice, not a law.** You will hear fixed fractions quoted as if they were
industry rules, and each of them is another company's decision for its own debt. The right share
depends on how much interest your debt charges. A team whose code costs it a large part of every
sprint in interest needs more than a team on a young codebase, and the share should come down as
the interest does.

## What goes inside, and what does not

A split needs a boundary, or it becomes the place where everything engineering wants to avoid
arguing about gets filed. Coreto drew the line on purpose, and wrote down the cases that came up in
the first month.

| work | which side | why Coreto put it there |
|---|---|---|
| repaying a priced debt, such as the flaky end-to-end suite | engineering | it is what the share exists for |
| moving a service onto the deploy template (lesson 14) | engineering | platform adoption is investment |
| a bug a venue reported | product | product decides its order against other customer work |
| discovery time for an engineer (the previous section) | product | it serves a product idea |
| an on-call improvement after an incident | engineering | it lowers future interest |

The bug row was the contested one. Engineers argued that bugs are quality, and quality is theirs.
Júlia argued that a venue's bug competes with a venue's feature request for the same reason, and the
person who talks to venues should order them. Coreto took Júlia's side. **What mattered was that it was
decided once**, in January, and stopped being decided again every sprint.

## Accounting for the share

**A share that buys nothing visible will be taken back at the first bad quarter.** So each quarter the
tech leads report what it bought, in terms product cares about: hours of interest removed, incidents
that did not recur, a release step that no longer needs somebody watching it. Lesson 5's interest figures are the
natural unit. When the seat-hold debt is paid off, the 31 hours a sprint it charged come back to
the teams that touched it, and that is a number Júlia can plan features with.

This lesson does not teach how to measure a team's capacity, or why a team planned at full capacity
delivers less. That is `delivery-metrics` lesson 12, on capacity and slack, and the split here is a
division of whatever capacity that lesson leaves you with. The split is about who decides; slack is
about how much there is to decide over.

When a product lead pushes back on the share in the middle of a quarter, the agreement is what makes
the conversation short. Without it, the push is one more item-by-item comparison, and the debt loses
again. `people-leadership` lesson 22 covers that conflict for when the agreement alone does not end
it.
