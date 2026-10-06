---
title: Choosing, one column at a time
version: 1
---

The type is a decision about **each attribute**, not about the table. Ana's customer dimension mixes
three of them, and every choice has a reason that can be written down:

| attribute | type | why |
|---|---|---|
| tier | 2 | the loyalty programme is analysed by tier over time |
| city, state | 2 | sales by region must count a sale where the buyer lived when buying |
| name | 1 | every change in the log is a correction of a typo |
| joined on, state when joined | 0 | they describe a moment, and cohort analysis needs them frozen |
| e-mail | not kept | no report groups by it, and it is personal data with no analytical use |

The questions that decide it, in order:

1. **Was the old value ever true?** If not, it is a correction: type 1.
2. **Does anybody analyse facts by this attribute over time?** If not, type 1 is enough, and cheaper.
3. **Does a fact need the value that was true when it happened?** Then type 2.
4. **Is there one transition that people will want to see both sides of?** Type 3, or type 2 and a view.
5. **Does it change so often that type 2 would multiply the rows?** A mini-dimension, type 4.

**The same attribute can get different answers in different businesses.** A customer's city is type 2
for a shop analysing regional sales, and type 1 for a utility that only needs to know where to send the
bill. The type follows the questions, which is why lesson 2's four steps start from them.

Books change too. A book's department might be reclassified, *Comics* moving a title to *Young adult*.
If the shop wants "sales by department" to show the arrangement that was in force at the time, the
department is type 2 on `dim_book`. If it wants every year shown under today's arrangement, which is
the more common wish for a product hierarchy, it is type 1. Ana's `dim_book` is rebuilt from the
current catalogue, so it is type 1 on everything, and that is a choice that should be written in
lesson 12's dictionary rather than discovered.
