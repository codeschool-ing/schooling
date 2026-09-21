---
title: `int()`, `float()`, `str()` — and where they refuse
version: 1
---

```python
>>> int("41")
41
>>> float("3.14")
3.14
>>> str(41)
'41'
```

Each takes a value and returns a new one of that type. They do not change anything in place, and
there is nothing to change: numbers and strings are immutable.

## Where `int()` refuses

```python
>>> int("forty-one")
ValueError: invalid literal for int() with base 10: 'forty-one'
```

**That refusal is the feature.** A conversion that quietly produced `0` would put a wrong number
into your program with nothing to read. The message even quotes what it was given.

It also refuses a decimal string:

```python
>>> int("3.14")
ValueError: invalid literal for int() with base 10: '3.14'
```

`int(float("3.14"))` is the two steps, and it is honest about being two.

## `int()` truncates; `round()` rounds

```python
>>> int(3.9)
3
>>> int(-3.9)
-3
>>> round(3.9)
4
```

`int()` throws the fractional part away, towards zero. `round()` does what you expect, with one
famous exception: it rounds halves to the **even** number — `round(0.5)` is `0` and `round(1.5)`
is `2`. That is banker's rounding, it is deliberate, and it stops a long column of halves drifting
upwards.

## `bool()`

Follows the truthiness table exactly: `bool("")` is `False`, `bool("0")` is `True`.

## `str()` against `repr()`

```python
>>> str("ada")
'ada'
>>> repr("ada")
"'ada'"
```

`str` is for a person; `repr` is for you, and it shows the quotes. `print` uses `str`, the REPL
uses `repr`, and that is why a string at the prompt appears with quotes around it and the same
string printed does not. Lesson 6 is where you write both for your own classes.

## Catching the refusal

```python
try:
    age = int(raw)
except ValueError:
    print(f"{raw!r} is not a whole number")
```

That is lesson 8's material in full, and it is the right shape for anything a person typed. The
`!r` in the f-string is `repr`, which quotes the value so an empty string is visible rather than
invisible.
