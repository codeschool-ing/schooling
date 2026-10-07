---
title: Turning a finding into money
version: 1
---

The R$ 790 thousand on the board slide in lesson 4 came from four steps. **Each one is a multiplication, and
each one carries an assumption that should be said out loud.**

## The four steps

**First, the extra cancellations.** 1,058 late first boxes in six months, and late customers cancel 24.1
points more often than on-time ones. If the late customers had cancelled like the others, how many fewer
would have left?

```localised
=ROUND(1058*(439/1058-881/5055),0)
```

Calc gives **255** in six months, so 510 a year.

Second, the margin lost per extra cancellation: R$ 1,554.14, from the previous section, the lifetime
margin of a survivor minus what an early canceller paid. Third, the margin lost a year: 510 times
R$ 1,554.14 is **R$ 792,611.40**, said on every page as "about R$ 790 thousand", for lesson 8's reasons.

Fourth, the acquisition spent on them: 510 customers at R$ 152 each is **R$ 77,520** a year, paid to win
customers who left before paying it back. This is not added to the margin figure. It answers a different
question, *how much of marketing's budget is wasted?*, and it belongs to a different reader.

## The assumptions, said out loud

- **That the gap is caused by the delay.** Step 1 assumes late customers would have behaved like on-time
  ones. Lesson 10 removed region as an alternative; the pilot tests the cause directly.
- **That the after-90-day churn of 4% a month holds.** It is Faro's recent rate; it could change.
- **That the margin of 31% holds.** Food and shipping costs move.

**Each assumption is a place a sceptic can push**, and naming them first moves the conversation from
"I don't believe it" to "which assumption do you doubt?", which is a conversation you can have with
numbers.

## The common mistakes

- **Using revenue instead of margin.** 510 customers times 28 months times R$ 189.90 is about R$ 2.7 million,
  and it is wrong as a cost: Faro would also have spent most of that on food and shipping.
- **Counting the same loss twice.** Margin lost and acquisition wasted are both real, and adding them
  pretends the acquisition money would otherwise have produced margin too.
- **Annualising carelessly.** Doubling six months to a year is fine here because the monthly pattern is
  stable (lesson 7's sparkline). For a seasonal business, it would not be.
