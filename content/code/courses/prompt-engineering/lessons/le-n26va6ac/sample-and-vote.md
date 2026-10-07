---
title: Sampling several chains and taking a vote
version: 2
---

Lesson 26 ended on a chain that read well and was wrong. The tempting fix is to make the one
chain more careful: a better instruction, a longer example. **Self-consistency takes a different
route: it asks for several chains of thought to the same question and keeps the final answer that
most of them reach.** It does not try to make any single chain right. It relies on wrong chains
going wrong in different ways, while right chains, whatever their wording, arrive at the same
number.

## Why the samples have to differ

A vote among copies is no vote. At temperature 0 a model takes the top-scoring token at every
step (lesson 13), so the same prompt gives the same text each time. `toylm` shows it with five
seeds:

```
ana@lab:~/pe$ toylm generate "the café closes at" --temperature 0 --samples 5
[seed 1] six.
[seed 2] six.
[seed 3] six.
[seed 4] six.
[seed 5] six.
```

Five identical answers say nothing that one did not. **The samples have to be drawn at a
temperature above 0**, so that each one can take a different path. Lesson 1's `--samples` does
exactly that at `toylm`'s default temperature:

```
ana@lab:~/pe$ toylm generate "the café closes at" --samples 7
[seed 1] six.
[seed 2] noon on sunday.
[seed 3] six.
[seed 4] six.
[seed 5] six.
[seed 6] noon on sunday.
[seed 7] six.
```

That is already a small vote, counted by eye: `six` five times, `noon on sunday` twice. Both are
true in the café's corpus, and the next reading section comes back to what that means for a vote. A large model sampled the same
way gives chains that differ in wording, in the order of the steps, and sometimes in a step that
goes wrong.

## Seven chains for the café order

The question is lesson 26's: three flat whites at R$ 12, two slices of cake at R$ 15, and a
loyalty card already on 9 stamps. The prompt is the one that got the right answer there, ending in
an `Answer:` line, saved as `~/pe/prompts/order-chain.txt`. One loop draws seven samples at
temperature 0.7, each with its own seed, into a file each. Two of them, whole:

```
ana@lab:~/pe$ mkdir -p chains; for i in 1 2 3 4 5 6 7; do ask - --temperature 0.7 --seed $i --plain < prompts/order-chain.txt > chains/s$i.txt; done
ana@lab:~/pe$ cat chains/s2.txt
To find out how much the customer pays, we need to calculate the total cost of the items first.

The customer orders 3 flat whites at R$ 12 each, so the total cost of the flat whites is:
3 x R$ 12 = R$ 36

The customer also orders 2 slices of cake at R$ 15 each, so the total cost of the cake is:
2 x R$ 15 = R$ 30

Now, let's add the cost of the flat whites and the cake together:
R$ 36 + R$ 30 = R$ 66

Since the customer has 9 stamps on their loyalty card, they can get one free item with the tenth purchase. This means they get the 10th coffee for free.

The customer has already made 9 purchases, so the 10th purchase is the 10th coffee, which is free.

Now, let's subtract the cost of the 10th coffee (which is free) from the total cost:
R$ 66 - R$ 0 = R$ 66

However, considering that with the loyalty card, the tenth coffee is free, the customer won't have to pay for it.

So, the final amount the customer needs to pay is:
R$ 66 - R$ 12 (cost of 10th coffee) = R$ 54

Answer: R$ 54
ana@lab:~/pe$ cat chains/s3.txt
To calculate the total cost, we need to calculate the cost of the flat whites and the cake separately, then add them together.

Cost of flat whites:
3 flat whites at R$ 12 each = 3 x R$ 12 = R$ 36

Cost of cake:
2 slices of cake at R$ 15 each = 2 x R$ 15 = R$ 30

Total cost:
R$ 36 (flat whites) + R$ 30 (cake) = R$ 66

Since the customer already has 9 stamps on their loyalty card, they are eligible for the free coffee on their 10th purchase, not on this purchase. So, the customer will pay for all items, but they won't pay for the 10th coffee.

Answer: R$ 66
```

Both start the same way, 36 and 30 and 66, and both then reason about the card. `s2` talks itself
out of the free coffee, subtracts nothing, and then subtracts it after all: 54. `s3` decides the
free coffee belongs to some other visit and stops at 66. The steps are the same kind of uneven
text lesson 26 showed, and the vote will not look at them.

`vote` takes the last answer line in each file and counts them. Save it as `~/pe/bin/vote` and
make it executable:

```python
#!/usr/bin/env python3
"""vote FILE...: self-consistency. Each FILE is one sampled answer to the same
question, reasoning and all. The final answer is taken from its last
"answer is ..." or "Answer: ...", with a leading R$ dropped; a file with
neither casts no vote. The most common final answer wins."""
import re
import sys
from collections import Counter

finals = []
for f in sys.argv[1:]:
    text = open(f, encoding="utf-8").read()
    found = re.findall(r"answer(?: is|:)\s*:?\s*(?:R\$\s*)?([^\s.,]+)", text, re.I)
    if found:
        finals.append(found[-1].lower())
    print("%-16s %s" % (f, found[-1].lower() if found else "(no answer line: no vote)"))
if not finals:
    print("no votes")
    sys.exit(1)
tally = Counter(finals).most_common()
print("votes: " + ", ".join("%s x%d" % kv for kv in tally))
best, n = tally[0]
if len(tally) > 1 and tally[1][1] == n:
    print("no majority: a tie between %s" % " and ".join(k for k, v in tally if v == n))
else:
    print("majority: %s (%d of %d answers, %d files)" % (best, n, len(finals), len(sys.argv) - 1))
```

```
ana@lab:~/pe$ vote chains/*.txt
chains/s1.txt    72
chains/s2.txt    54
chains/s3.txt    66
chains/s4.txt    66
chains/s5.txt    66
chains/s6.txt    78
chains/s7.txt    54
votes: 66 x3, 54 x2, 72 x1, 78 x1
majority: 66 (3 of 7 answers, 7 files)
```

**The majority is 66, and it is wrong.** The right answer, 54, came twice; the bill that forgets
the card came three times, and two more chains invented 72 and 78. The wrong chains did not
scatter: three of them made the same mistake, the obvious reading of the order, which is also the
likeliest text for this model to write. A vote rewards the likeliest answer, and here the likeliest
answer is the error. The next reading section is about exactly this.

**Only the final answers are compared; the reasoning is thrown away.** That is what makes the vote
possible: seven paragraphs worded differently cannot be counted, seven numbers can. It is also why
each chain needs a fixed answer line, the same habit as lesson 26's `Answer:` line, so a program
can find what to count. `vote` drops a leading `R$` before counting, so `R$ 54` and `54` are one
answer.

## The procedure

1. Write one chain-of-thought prompt that ends in a fixed answer line.
2. Send it N times at a temperature above 0, or once with a parameter that asks for N samples, if
   the API has one.
3. Extract the final answer from each reply, and treat a reply with none as no vote; `vote`
   says which files cast none.
4. Take the most common answer.

The share the winner got is useful too. **3 of 7 is a weak result**, and a program can act on that:
accept a unanimous or near-unanimous vote, and send a split one, like this one, to a person or to a
second round of samples. Here that rule would have caught the wrong answer before it was used.
