---
title: Reading a tree out loud
version: 1
---

A tree is a set of rules, one per leaf, and each rule is the path from the root to that leaf. The
tree from `first_tree.py` reads, leaf by leaf, as four sentences anybody at Feira em Casa could check:

| path | leavers in the leaf | the rule, out loud |
|---|---|---|
| rating ≤ 3.6, complaints = 0 | 525 of 2,386, 22% | an unhappy subscriber who has not complained leaves at about one in five |
| rating ≤ 3.6, complaints ≥ 1 | 353 of 896, 39% | an unhappy subscriber who has complained leaves at about two in five |
| rating > 3.6, skips ≤ 2 | 1,091 of 33,424, 3% | a happy subscriber who keeps their boxes almost never leaves |
| rating > 3.6, skips ≥ 3 | 232 of 1,922, 12% | a happy subscriber who skips a lot leaves at about one in eight |

**That table is the model.** Nothing else is in it. It can be printed, argued with and pinned to a
wall, and the retention team can apply it without a computer. For a small tree this legibility is
the main reason to choose one, and it is why trees are used in places that must justify each
decision, such as which claims an insurer sends for review.

The legibility fades with depth. The best tree of the last section, depth 7, has 110 leaves and
paths of up to seven conditions; it can still be printed, but it no longer fits in anyone's head, and
by depth 10 it is as opaque as any other model. **A tree is legible when it is small, and it is
accurate when it is not**, and on most data those two pull in opposite directions.

## Three ways the reading goes wrong

**Reading a path as a cause.** *Complaining raises the chance of leaving from 22% to 39%* is what
the table seems to say. It says that among unhappy subscribers, the ones who complained left more
often; whether complaining had anything to do with it is a different question, and the warning from
lesson 5 applies to trees as well.

**Reading the order of questions as importance.** The column at the root is the best single cut,
not necessarily the most useful column overall. A column that never appears near the top can still
be used in dozens of lower splits.

**Reading a missing column as irrelevant.** A column can be absent from the tree because another,
correlated one was chosen first at every step. `orders_90d` never appears in `first_tree.py`'s output
because `skips_90d` carries the same information and won the cut.
