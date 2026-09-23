---
title: Two loops, and work that grows with the product
version: 2
---

```python
for a in xs:
    for b in ys:
        ...
```

The inner loop runs completely for each item of the outer one. Ten and ten is a hundred; a
thousand and a thousand is a million.

**That is the shape lesson 20 calls O(n²)**, and it is the most common reason a program that
worked on the sample takes four minutes on the real file.

## The one that hides

```python
for name in names:            # 100_000
    if name in banned:        # a LIST of 5_000
        ...
```

There is one visible loop. The second is inside `in`, because `in` on a list walks it. Same
arithmetic, same cost, and nothing in the code says `for` twice.

**Lesson 3's answer applies:** make `banned` a set and the inner walk becomes one step.

## When the pairs are the point

Sometimes you genuinely want every pair — comparing every record with every other, a grid, a
multiplication table. Then the nesting is the algorithm and the cost is honest.

`itertools.product` in lesson 7 writes the same thing as one loop, which is neater when the
nesting is three deep.

## Breaking out of both

`break` leaves one loop. To leave both, the common answers are:

```python
found = None
for a in xs:
    for b in ys:
        if ok(a, b):
            found = (a, b)
            break
    if found:
        break
```

— or put the pair of loops in a function and `return`, which lesson 5 makes available and which
is almost always clearer than the flag.

## The rule of thumb

**One loop is fine. Two is a question. Three needs an answer.** The question is whether the inner
collection could be a dictionary or a set, which turns the product back into a sum.
