---
title: The table worth knowing
version: 1
---

| operation | cost | measured at n = 100,000 |
| --- | --- | --- |
| `data[i]` | O(1) | 13 ns |
| `data.append(x)` | O(1) | 19 ns |
| `data.pop()` | O(1) | 26 ns |
| `data.insert(0, x)` | **O(n)** | 32,527 ns |
| `data.pop(0)` | **O(n)** | 13,247 ns |
| `x in list` | **O(n)** | 885,901 ns |
| `x in set` | O(1) | 69 ns |
| `x in dict` | O(1) | 44 ns |

All measured with `timeit` on one machine. **The ratios are the point**, not the nanoseconds.

## Why `in` on a list is a walk

A list is a sequence of slots. Nothing about it says where a value is, so `x in data` compares
`x` against each element until it finds one — `n` comparisons in the worst case, and that is the
`885,901` nanoseconds above.

## Why `in` on a set is one step

A set stores each value at a position computed **from the value itself** — its hash. Asking
whether `x` is present is computing `hash(x)`, going to that position, and looking. The size of
the set does not enter into it.

A dict is the same machinery with a value attached, which is why `x in dict` and `d[x]` are both
`O(1)`.

## What that costs you

```python
{"a": 1}        # a dict of one
[("a", 1)]      # a list of one
```

The set and the dict use more memory per element and need their keys to be **hashable** — so
strings, numbers and tuples yes, lists and dicts no. They also lose ordering guarantees
of the kind a list gives you, although both preserve insertion order in modern Python.

That is the whole trade, and it is almost always worth taking.

## `insert(0, …)` and `pop(0)`

```python
data.insert(0, x)     # everything after it shifts up one slot
```

A list is contiguous, so putting something at the front moves every other element. At a hundred
thousand items that is 32 microseconds against `append`'s 19 nanoseconds — **about seventeen
hundred times** — and the next section is what to use instead.

## Strings, and a rule that is half a myth

```python
s = ""
for word in words:
    s += word
```

```python
s = "".join(words)
```

```text
+= over 10,000 words   0.515 ms       join over 10,000   0.077 ms
+= over 20,000 words   1.023 ms       join over 20,000   0.148 ms
+= over 40,000 words   2.046 ms       join over 40,000   0.298 ms
```

Strings are immutable, so the usual telling is that `s += word` copies everything each time and
the loop is `O(n²)`. **Measured, it is linear** — double the words, double the time — because
CPython has an optimisation that grows the string in place when nothing else refers to it.

`join` is still about seven times faster, and it is still the thing to write: the optimisation is
CPython's rather than the language's, and it stops applying the moment anything else holds a
reference to `s`. But the reason is "this is what `join` is for", not a quadratic you can
measure.

