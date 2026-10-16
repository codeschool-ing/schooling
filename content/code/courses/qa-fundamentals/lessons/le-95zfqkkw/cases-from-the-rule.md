---
title: Cases from the rule, one sentence at a time
version: 1
---

**The simplest systematic black-box test is to take the requirement one sentence at a time and ask,
for each, what input would show whether it holds.** Here is Joana's rule again, with each sentence
numbered:

> 1. A ticket costs R$ 36,00 for a session that starts at 17:00 or later, and R$ 28,00 for one that
>    starts earlier.
> 2. Students, over-60s and children under 12 pay half.
> 3. On Wednesdays every ticket is half price.
> 4. An order holds between one and six tickets.

Sentence 4 is about orders, which `tickets.py` does not handle; lesson 8 meets the program that does.
The other three become a table.

## The table

For each sentence, Lia wrote what she expected before running anything. Writing the expectation first
matters: an expectation written after seeing the output tends to agree with it.

| sentence | case | why this one | expected |
|---|---|---|---|
| 1 | adult, Thursday, 16:59 | the last minute of the matinée | R$ 28,00 |
| 1 | adult, Thursday, 17:00 | the first minute of the evening | R$ 36,00 |
| 2 | student of 20, Thursday evening | the student reduction alone | R$ 18,00 |
| 2 | child of 11, Thursday evening | the oldest child who still pays half | R$ 18,00 |
| 2 | child of 12, Thursday evening | the youngest who no longer does | R$ 36,00 |
| 3 | adult, Wednesday evening | the Wednesday reduction alone | R$ 18,00 |

Notice the pairs: 16:59 and 17:00, 11 and 12. Each sentence of the rule draws a line, and a line is
tested from both sides, at the last value on one and the first on the other. That is the habit the
technique called boundary value analysis makes systematic, and it is how lesson 1 found the
sixty-year-old.

## Running it

```
lia@lab:~/aurora$ python tickets.py 35 no thu 16:59
R$ 28,00
lia@lab:~/aurora$ python tickets.py 35 no thu 17:00
R$ 36,00
lia@lab:~/aurora$ python tickets.py 20 yes thu 20:00
R$ 18,00
lia@lab:~/aurora$ python tickets.py 11 no thu 20:00
R$ 18,00
lia@lab:~/aurora$ python tickets.py 12 no thu 20:00
R$ 36,00
lia@lab:~/aurora$ python tickets.py 35 no wed 20:00
R$ 18,00
```

Six for six. Every sentence of the rule, tested from its edges, holds.

## What six passing cases say

Exactly what lesson 1 said four passing cases did: that these six inputs give these six outputs. They
say the lines at 17:00 and at 12 are where the rule puts them, which is worth knowing; those are the
places a reading could differ, as it did at sixty.

They say nothing about the **combinations**. Every case in the table exercises one sentence at a time:
a student on a Thursday, an adult on a Wednesday. Real customers do not arrive one sentence at a time.
A student goes to the cinema on a Wednesday, because that is when it is cheapest. The table has no row
for that, and the rule has no sentence for it. The next section runs it.
