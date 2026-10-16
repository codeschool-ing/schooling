---
title: Leaving the column out
version: 1
---

The instinct is reasonable: if the model should not decide by age, do not show it age. The name for that
is **fairness through unawareness**, and the second table of `by_age.py` shows what it did here.

**It made the youngest subscribers worse off.** With age in the model, 26.7% of young leavers got a credit;
without it, 19.4%. Young subscribers leave more often for reasons the data captures only through age, so a
model that cannot see age stops recognising some of them, and the credit that might have kept them goes
elsewhere. If the credit is a benefit, and it is, removing the column took a benefit away from the group it
was meant to protect.

**And it did not remove age.** The model without the column still treats the bands differently; it moved
credits from the young to the old, because some other columns move with age and the model reads them
instead. Those columns are **proxies**, and the next section measures how much of age they carry.

None of this means age belongs in every model. It means that **whether to use a protected characteristic
is a decision about outcomes, not about columns**, and it has to be made by looking at what each choice
does to each group. Three positions are defensible, and they suit different situations:

- **Leave it out, and accept what the proxies carry**, when using it would be unlawful or unacceptable,
  as it would be for most credit, hiring or insurance decisions.
- **Leave it out of the model, keep it for measuring**, so that the tables of this lesson can still be
  printed. Without the column, nobody can check whether a model treats a group differently.
- **Use it, openly and for a stated reason**, when the decision benefits the group and the reason survives
  being said aloud: *younger subscribers leave more, so they are offered more retention credits.*

The middle position is the one this lesson recommends as a default. A company that deletes the protected
column from its data has not made its model fair; it has made itself unable to find out.
