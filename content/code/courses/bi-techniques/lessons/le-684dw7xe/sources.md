---
title: Where bias comes from
version: 1
---

**A model is biased, in the sense this lesson uses, when its errors fall more heavily on one group of
people than on another.** Nobody has to intend it. A model learns from data that people produced and
is used for decisions that people chose, and each of those steps can tilt it. The usual sources have
names, and it helps to know them, because each points to a different place to look.

- **Historical bias.** The data records what happened, including the effects of past decisions. If
  Panela had always sent its best offers to the Southeast, the Southeast's customers would have stayed
  longer, and a model trained on that history would learn that the Southeast is loyal. It would be
  right about the past and would carry the old decision forward.
- **Representation bias.** Some groups are scarce in the data. The North is 4 per cent of Panela's
  customers, 117 of the 2,558 in lesson 17's test, and 17 of those churned. A model fitted mostly on
  the Southeast fits the Southeast, and any measure of how it does in the North rests on a handful of
  people.
- **Measurement bias.** An input means different things for different groups. Days since the last
  order looks like a neutral number. It stops being neutral if one group's orders take longer to
  arrive, and section four shows that this is exactly Panela's case.
- **Aggregation bias.** One model for everybody assumes the same pattern holds for everybody. When a
  group behaves differently for reasons the inputs do not capture, the single model is tuned to the
  majority and wrong about the rest in a consistent direction.
- **Deployment bias.** A model built for one decision is used for another. The churn model was built
  to choose who receives an offer. The marketing team now wants to use it to choose who joins a club.
  Nothing in the model changed, and what its mistakes cost changed completely.

A sixth source belongs to any model whose decisions shape its future data: the **feedback loop**,
where customers who receive an offer behave differently because of it, and next year's model learns
from behaviour the current one caused. Lesson 19 returns to it.

None of these shows up in overall accuracy, precision or recall. A model can be 89 per cent accurate
and much less accurate for one region, because the region is small enough to vanish in the average.
**Bias is found by breaking the measures down by group**, which is what the next section does.
