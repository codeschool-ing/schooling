---
title: The condition has to change
version: 2
---

```python
attempts = 0
while attempts < 3:
    if try_once():
        break
    attempts += 1
```

`while` repeats as long as the condition holds. **Something inside the loop has to change it**, or
it never stops — and that is the whole risk of this construct compared with `for`.

## When to use it

`for` when you know what you are iterating. `while` when you do not:

- reading until a sentinel or the end of a stream
- retrying until it works or you run out of attempts
- a game loop, running until somebody quits

If you can express it as `for … in`, do. `while` over an index is `for` with the safety removed.

## `while True` with a `break`

```python
while True:
    line = input("> ")
    if line == "quit":
        break
    handle(line)
```

This is idiomatic Python rather than a smell, and it is often clearer than duplicating the read
before the loop and at the end of it. The rule is that the `break` has to be **visible**: one, near
the top, and not buried three levels in.

## The infinite one

```python
i = 0
while i < 10:
    print(i)          # i never changes
```

No error, no message, and the program never ends. `Ctrl-C` stops it. Then look for the line that
should have moved the condition — it is missing, or it is inside an `if` that did not run.

## `else`, again

`while … else` runs when the condition became false without a `break`, exactly like the `for`
version. Same usefulness, same tendency to be misread.

## The pattern to avoid

```python
i = 0
while i < len(items):
    print(items[i])
    i += 1
```

Three lines of bookkeeping and two chances to get it wrong, for something `for item in items`
says in one. If you meet this in code you are reading, it is almost always a translation from a
language without `for … in`.
