---
title: When each one wins
version: 1
---

**The choice between a data flow and a notebook is rarely about the data; it is about who will look
after the transformation for the next three years.** Both run Spark, both can clean Quitanda's night,
and both bill a cluster by the minute. What differs is how a change is made, reviewed, tested and
undone. This section is a summary of the lesson's argument, taught from the documentation and from
the two practised sections; none of it was run on Azure.

## Side by side

| | mapping data flow | notebook |
|---|---|---|
| written by | drawing boxes in the editor | writing code |
| a change, reviewed | a diff of a script the editor wrote | a diff of the code somebody wrote |
| tested | by running it on a cluster against a fixture | by a function on four rows, on a laptop, as in this lesson |
| what it can do | the boxes Data Factory offers, and their expression language | anything Spark and its libraries can |
| the cluster | started per run by the Azure runtime, nothing to look after | a pool, a session or a cluster, depending on the platform |
| where it moves | Data Factory and Synapse pipelines; not Fabric's dataflows | Synapse, Fabric and Databricks, with small changes |
| the bill | vCore-hours of the run, plus start-up and time to live | vCore-hours, capacity units or DBUs, plus idle minutes |

## When a data flow wins

**A data flow wins when the people who own the transformation do not write code, and the
transformation is the kind its boxes do well**: joining, deriving, filtering and aggregating tables
that are already tidy. A team of analysts who know SQL and Data Factory, and no Python, can build and
change it, see rows at each step in debug, and never meet a cluster. The price is paid later and
quietly: a transformation nobody can test without a cluster, a diff nobody reads, and a move to another
platform that means drawing it again.

## When a notebook wins

**A notebook wins when the transformation will grow**, when it has rules worth testing, when it needs a
library, a file format or an API the boxes do not offer, or when the team expects to move between
Synapse, Fabric and Databricks. Quitanda's night is that kind: the totals with a comma are the first
rule, and the second will be a return that cancels an order, and the third a promotion that changes
how a total is computed, and each one should arrive with a test that fails before the fix. The price
is a team that writes code well, and a cluster that someone has chosen and sized.

## And when neither

**A small night does not need Spark at all.** The section on the same night cleaned a day of Quitanda
in one Python process; at that size a cluster spends more time starting than working, and the arithmetic of
the clock section is all overhead. Data Factory can call such code as an Azure Function, and Fabric
can run it as a Python notebook with no Spark session behind it. The right moment for Spark is
when the data stops fitting one machine's memory or one night's window, and it is worth measuring
that moment rather than starting there.
