---
title: The split, seen as a leak
version: 1
---

Lesson 3 measured two leaks without calling them that. Both put information on the training side
that the model would not have in use, which is the definition, and both arrive through the split
rather than through a column.

**Relatives across the split.** When the question was *will this subscriber ever cancel?*, a random
split let the model learn a person's answer from one of their rows and be scored on another. The
share of right answers in the top tenth was 76.0% on a random split and 54.7% with subscribers kept
whole. The 21 points between them were a leak.

**The future across the split.** A random split of the 18 months let the model learn from the
months after the price rise and be scored on months before it. It was worth R$ 1,007 per thousand
rows against R$ 893 when split by time. The 13% between them were a leak.

Seen this way, lesson 3 and this lesson are one subject. A split is a promise that the scoring
rows are as new to the model as tomorrow's rows will be, and every leak is a broken promise of
that kind. Three practical consequences:

- **The split comes first**, before any column is chosen, any gap filled or any rule written, so
  that nothing learned from the data can see across it.
- **When a split and a column disagree, believe the split by time.** In section 04 the random
  split approved `days_since_last_order` and the time split refused it, and the time split was
  right.
- **The last check is the future itself.** A model is only cleared of leakage when it has scored
  rows written after it was built, and been as good as promised. Lesson 22 is that check.
