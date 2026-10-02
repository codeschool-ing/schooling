---
title: What a call costs
version: 1
---

Providers charge by the token, with one price for tokens read and a higher one for tokens written.
The lab's prices are in `prices.json`:

```
ana@lab:~/triage$ cat prices.json
{
  "model": "standin-1",
  "note": "cents per million tokens; written by the course, not any provider's price list",
  "input": 300,
  "cache_read": 30,
  "cache_write": 375,
  "output": 1500
}
```

**These prices were written by the course**, as the file says, and they are in whole cents per
million tokens: 300 cents for a million input tokens, 1500 for a million output tokens. The two
`cache` prices belong to lesson 17. Real price lists have the same shape, a price per million
tokens with output dearer than input, and change often enough that any number copied into a lesson
would be wrong within a year.

## The arithmetic

`pl cost` adds up the tokens of a run and multiplies:

```
ana@lab:~/triage$ pl cost runs/v3.jsonl
tokens          count   per call
input            9539      238.5
cache_read          0        0.0
cache_write         0        0.0
output           1497       37.4

cost of these 40 calls: 5.1072 cents
cost of a million calls like them: 127,680 cents
```

The forty calls read 9539 tokens and wrote 1497. At 300 and 1500 cents a million, that is
9539 × 300 + 1497 × 1500 = 2,861,700 + 2,245,500 = 5,107,200 millionths of a cent, which is the
5.1072 cents on the line below. Divide by forty for one call, 0.12768 cents, and multiply by a
million for the last line. **Output was under 14% of the tokens and 44% of the cost**, because each
output token costs five times as much. That is the same lesson as the last section, in money.

The last line is the one to put in front of somebody deciding whether to ship: 127,680 cents for a
million calls like these. A cost per call sounds like nothing; a cost per million is a budget.

## Why money is never a float

The harness never touches a fractional number on the way to that total. Its comment says why:

```
ana@lab:~/triage$ grep -n -A1 "Prices are whole cents" promptlab/cli.py
357:    # Prices are whole cents per million tokens, so tokens times price is in
358-    # millionths of a cent: an integer, and nothing is rounded until the end.
```

Tokens are whole, prices are whole cents per million, so their product is a whole number of
millionths of a cent, exact. **Nothing is rounded until the very end**, once, half up, at the last
place printed. The alternative looks harmless and is not:

```
ana@lab:~/triage$ python3 -c 'print(0.1 + 0.2)'
0.30000000000000004
```

A binary floating-point number cannot hold most decimal fractions exactly, so `0.1` is stored as
the nearest value it can hold, and sums of such values drift. One drift is invisible; the same
computation over every call of a month, compared with an invoice computed another way, produces a
difference somebody has to explain. **Keep money as an integer count of the smallest unit you
charge in**, multiply integers, and round once, with a rule you wrote down.
