---
title: Order and length
version: 2
---

Kappa says the judge is weak. It does not say why. Two biases are well known in model judges, and
each can be measured from outside, without reading anything but the verdicts, which is how you would
find them in any judge.

## Position

`--swap` asks every question twice, the second time with the replies in the other order, and maps
the second answer back to the reply it chose:

```
ana@lab:~/triage$ python3 judge.py cases/pairs.jsonl --swap
j01  human b  judge b  swapped a  FLIP
j02  human b  judge b  swapped b
j03  human a  judge b  swapped a  FLIP
j04  human a  judge a  swapped a
j05  human b  judge b  swapped a  FLIP
j06  human a  judge b  swapped a  FLIP
j07  human b  judge b  swapped a  FLIP
j08  human a  judge b  swapped a  FLIP
j09  human b  judge b  swapped ?  FLIP
j10  human a  judge b  swapped a  FLIP
j11  human b  judge b  swapped a  FLIP
j12  human a  judge ?  swapped a  FLIP
j13  human b  judge b  swapped a  FLIP
j14  human b  judge b  swapped b
j15  human a  judge b  swapped a  FLIP
j16  human a  judge b  swapped b

agrees with the human on 9 of 16
Cohen's kappa 0.18
changes its mind when the order is swapped: 12 of 16
agrees AND keeps its verdict: 3 of 16
```

**Twelve of sixteen verdicts flip.** Read the two columns together: in the first order the judge
chose `b`, the reply shown second, thirteen times; with the order swapped it chose `a`, which was now
the reply shown second, twelve times. Whatever it is reading, it is mostly reading the position. **A
verdict that changes when only the order changes is a verdict about the order.** Of the eight pairs
it agreed with the person on in the first run, only three keep their verdict in both orders.

Look at the `judge` column, too. It is the first question asked again, the same prompt at
temperature 0, and it should be the run above it line for line. It is not: `j05` was `?` the first
time and `b` this time, so the agreement moved from 8 to 9 and kappa from 0.11 to 0.18. That is
lesson 8's finding about temperature 0, inside a measuring instrument. A judge whose verdict on one
pair depends on what it was asked just before is a judge whose numbers have a margin, and sixteen
pairs is not enough to see how wide.

## Length

Four verdicts survive the swap: `j02`, `j04`, `j14` and `j16`. Here are the lengths of the replies:

```
ana@lab:~/triage$ python3 -c 'import json; [print(p["id"], p["human"], len(p["a"]), len(p["b"])) for p in map(json.loads, open("cases/pairs.jsonl"))]'
j01 b 274 137
j02 b 22 158
j03 a 151 220
j04 a 134 23
j05 b 225 135
j06 a 126 62
j07 b 199 47
j08 a 153 115
j09 b 24 177
j10 a 153 286
j11 b 231 115
j12 a 123 30
j13 b 211 113
j14 b 37 220
j15 a 107 187
j16 a 92 209
```

In all four, the judge chose the longer reply: 158 characters against 22 in `j02`, 134 against 23
in `j04`, 220 against 37 in `j14`, 209 against 92 in `j16`. The person agreed three times, because
in three of those pairs the long reply was the useful one. `j16` is the fourth:

```
ana@lab:~/triage$ grep '"j16"' cases/pairs.jsonl
{"id": "j16", "message": "Do you buy second-hand books?", "a": "We don't, sorry, but the Bookswap in Market Street does, and it's two minutes from the shop.", "b": "Thank you for thinking of us! We're always delighted to hear from book lovers. Second-hand books are a wonderful way to give stories a new life, and there are many good places in town where you can sell yours.", "human": "a"}
```

`a` answers the question and sends the customer somewhere useful; `b` is warm and says nothing. **No
swap can catch this bias, because the longer reply is longer in both orders.** Four stable verdicts
is far too few to measure it: the set has nine pairs where the longer reply is the worse one, and
only `j16` survived the swap.

## What the literature found

*Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena* (Zheng and others, 2023) documented
position bias, a preference for the answer in a particular position, and verbosity bias, a
preference for the longer answer, in language models used as judges. The same paper reported that
a strong model's verdicts agreed with human preferences about as often as people agreed with each
other, which is why the technique spread, and why its biases matter. A three-billion-parameter model
is not the strong model that paper measured, and this lesson shows what that difference looks like.

## What reduces them

- **Ask both orders and keep only the verdicts that agree.** Treat a flip as no verdict. Here that
  leaves four verdicts, three of them right, instead of sixteen with eight right.
- **Calibrate against people first**, on the task the judge will do, and report kappa rather than
  raw agreement.
- **Measure the length preference directly.** Count how often the judge picks the longer reply, and
  compare that with how often people do.
- **Read the judge's answers, not only its letters.** A judge told to answer *A or B and nothing
  else* still answered with neither twice, and its parser has to say what it does then.
- **Keep a person reading a sample** of the judge's verdicts for as long as it is in use, because a
  judge's habits can change when its model does.
