---
title: Chained comparisons, and `==` against `is`
version: 1
---

## The operators

`==` `!=` `<` `>` `<=` `>=`, and they work on numbers, strings, and anything that defines them.

**Strings compare by code point**, so `"apple" < "banana"` is `True` and `"Z" < "a"` is also
`True`, because uppercase letters come first. For sorting text a person will read, `key=str.lower`
is usually what you meant.

## Chaining

```python
if 0 <= index < len(items):
```

That is one expression and it means what it looks like. Most languages cannot do this; in Python
`a < b < c` is `a < b and b < c`, with `b` evaluated once.

## `==` against `is`

```python
>>> a = [1, 2]
>>> b = [1, 2]
>>> a == b
True
>>> a is b
False
```

**`==` asks whether the values are equal. `is` asks whether they are the same object.**

Use `is` for `None`, `True` and `False` — there is exactly one of each — and `==` for everything
else. `is` on strings or small numbers sometimes answers `True` because the interpreter reuses
them, which makes it look like it works right up until it does not.

## `in`

```python
>>> "ada" in "ada lovelace"      # substring
True
>>> 3 in [1, 2, 3]               # membership
True
>>> "name" in person             # a dictionary's KEYS
True
```

One operator, three containers, and on a dictionary it is the keys rather than the values. Lesson
3's table has the cost of each.

## Comparing different types

`1 == 1.0` is `True`; `1 == "1"` is `False` and does not raise. But ordering raises:

```python
>>> 1 < "1"
TypeError: '<' not supported between instances of 'int' and 'str'
```

**Equality answers; ordering refuses.** That asymmetry is deliberate: two values of different
types are certainly not equal, and there is no honest answer to which of them is larger.
