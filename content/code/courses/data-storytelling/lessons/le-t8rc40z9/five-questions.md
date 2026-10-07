---
title: The five questions every finding gets
version: 1
---

The questions a room asks about an analysis are less varied than they feel in the moment. **Almost all of
them fall into five families**, and each family can be prepared for.

| family | the question | Faro's version |
|---|---|---|
| **source** | where did this come from? | how do we know a box was late? whose timestamp? |
| **cause** | is it really this, or something else? | is it the delay, or the region, or the kind of customer? |
| **size** | so what? how big is it? | 1,058 late boxes; what is that in money? |
| **cost** | what will it take? | what does removing the check cost us, and what can go wrong? |
| **blame** | whose fault is this? | is logistics failing? |

## Why these five

They are the questions a careful decision maker has to ask before acting on somebody else's analysis.
**Source and cause ask whether it is true. Size asks whether it matters. Cost asks whether acting is worth
it.** Blame is different: it is rarely asked in those words, and it is often the question behind another
one. When Sandra asks "did you include the interior?", the question underneath may be "are you about to
tell Paulo my team is the problem?"

## Which one is most dangerous

For a finding like Faro's, the most dangerous family is **cause**. A source question can be answered with a
definition, a size question with arithmetic, a cost question with the options table from lesson 9. A cause
question, if it lands, **dissolves the finding**: if late customers cancel more because they live in the
interior, and interior customers cancel more anyway, then fixing deliveries would change little, and the
whole recommendation falls.

That is why the next section spends its whole length on one cause question, with the data.

## Your list

Write the five families in `my-analysis.txt` and, under each, the hardest version of the question
somebody could ask about your own analysis. **If you cannot think of a hard cause question, ask a
colleague**, because the person who did the analysis is the worst-placed to see its alternative
explanations.
