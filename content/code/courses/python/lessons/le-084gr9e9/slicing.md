---
title: `[start:stop:step]`, and the copy it makes
version: 1
---

```python
>>> letters = ["a", "b", "c", "d", "e"]
>>> letters[1:3]
['b', 'c']
```

**The stop is exclusive.** `[1:3]` is positions 1 and 2. That looks arbitrary until you notice
what it buys: `len(xs[a:b])` is `b - a`, and `xs[:n] + xs[n:]` is the whole thing with no overlap
and no gap.

## Leaving parts out

```python
>>> letters[:2]     # from the beginning
['a', 'b']
>>> letters[2:]     # to the end
['c', 'd', 'e']
>>> letters[:]      # all of it — and a NEW list
['a', 'b', 'c', 'd', 'e']
```

## The step

```python
>>> letters[::2]
['a', 'c', 'e']
>>> letters[::-1]
['e', 'd', 'c', 'b', 'a']
```

`[::-1]` reverses. It works on strings too — `"ada"[::-1]` is `'ada'`, which is how you check for
a palindrome in one expression.

## A slice never raises

```python
>>> letters[10:20]
[]
```

Where `letters[10]` raises `IndexError`, the slice just gives you what is there. That is
convenient and it is also a place a bug hides: an empty result may mean *nothing matched* or *my
indices were nonsense*, and the slice will not tell you which.

## It is a copy

```python
>>> a = [1, 2, 3]
>>> b = a[:]
>>> b.append(4)
>>> a
[1, 2, 3]
```

`a[:]` is one of the three ways to copy a list — the others are `list(a)` and `a.copy()`, and all
three are **shallow**, which the `copying` section is about.

## Assigning to a slice

```python
>>> a = [1, 2, 3, 4]
>>> a[1:3] = ["x"]
>>> a
[1, 'x', 4]
```

The replacement does not have to be the same length. Rarely what you want, and worth recognising
when you read it.

## On strings

The syntax is identical, because slicing belongs to sequences and a string is one. The difference
is that a string slice is a new string and there is no assigning to it — strings are immutable.
