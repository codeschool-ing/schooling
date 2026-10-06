---
title: When a snowflake is the right answer
version: 1
---

The star is the default because most dimensions are small and most readers are people. Each of the
cases below breaks one of those assumptions, and each is a reason to normalise **one branch** of a
dimension, never the whole model.

**A dimension that is very large, with a part that is not.** A telecom's customer dimension can have
tens of millions of rows, and the demographic description of where each customer lives, perhaps two
hundred columns of census data, is shared by thousands of them. Repeating those columns in every
customer row is real storage and real load time. Moving them to a table of their own, pointed at from
the customer, is a snowflake on one branch, and Kimball calls a table used that way an **outrigger**.

**A description shared by several dimensions.** If shops and customers both have an address in a
city, and the city carries its own attributes (population, region, the sales territory it belongs
to), one `dim_city` that both point at keeps the two from describing the same city differently. That
is a second outrigger, and it is also what section 09 calls conforming.

**A hierarchy that changes on its own schedule.** If the shop reorganised its departments every
quarter and kept the history of each version, the category tree would be a dimension with a life of
its own. Lesson 5's techniques would apply to it separately from the books.

**A semantic layer in front of the warehouse.** Some report tools, and the modelling layers of some
cloud warehouses, prefer a normalised model and flatten it themselves for the reader. Then the
person never sees the joins, and the argument about readers in section 06 does not apply.

What is **not** on the list: "it is more correct", "it saves space" and "the source is normalised".
The first is the operational database's standard applied to a different job. Section 06 measured the
second. The third is the reason most snowflakes exist, and the reason lesson 2's four steps start from
the business process rather than from the source tables.

**The test, for any branch you are tempted to split off:** name the reader or the load that is
better off for it. If the only beneficiary is the diagram, leave it in the star.
