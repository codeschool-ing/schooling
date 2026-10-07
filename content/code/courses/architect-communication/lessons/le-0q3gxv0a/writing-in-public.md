---
title: Writing in public, and what you may say
version: 1
---

**A useful article tells readers about a problem they are likely to have, what was tried, what failed
and what worked, and it says only what the company has agreed can be said.** The second half of that
sentence comes first in practice: most of what an engineer knows about their work belongs to their
employer, and some of it belongs to clients.

## Ask before writing, not after

Lívia wanted to write about the 6 March incident and the connection quotas that followed. Before
drafting anything she asked Otávio and the person who handles Marola's public communication, with a
one-paragraph outline. They agreed, with three conditions:

1. **No client names.** Boa Praça does not appear.
2. **No revenue or order numbers**, which competitors would read. "Thousands of failed checkouts" is
   allowed; "1,350" is not.
3. **No security detail** that would help somebody attack the system, which ruled out naming the exact
   versions of anything.

Those conditions shaped the article and made it better: without the exact numbers, the article had to
explain the *shape* of the problem, which is what other engineers can actually use.

## The shape of a useful article

The post Lívia published on the engineering blog, *How one batch job took down our checkout, and the
quota that stopped it happening again*, followed a shape that suits most technical writing for an
outside audience:

| part | what it does |
|---|---|
| the problem, as the reader would recognise it | "a background job and your busiest service share a database" |
| what happened | the evening, in the order it happened, without blame |
| what was tried, including what failed | the alert that pointed at the wrong service; the first guess |
| what worked | per-service quotas, the runbook window, the connection alert |
| what we would do differently | "we would have set quotas the day we added the second service" |
| what we still do not know | honest limits, which make the rest believable |

The fifth and sixth rows are where most company blog posts are weakest, and where readers' trust is
earned. **An article that only shows success reads as an advertisement; one that shows the failures
reads as experience.**

## Lesson 1 still applies

The reader is a stranger with thirty seconds. The title says what they will learn, the first paragraph
says why it matters to them, and the headings carry the argument for somebody who only skims. The
editing passes from lesson 1 apply with one addition: **one reader from outside the company**, who will
say what the article assumes that nobody outside Marola knows.
