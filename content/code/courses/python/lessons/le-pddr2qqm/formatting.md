---
title: The f-string, and what goes after the colon
version: 1
---

```python
name = "Ada"
print(f"Hello, {name}")
```
```
Hello, Ada
```

An `f` before the quote, and braces around **any expression** — not just a name:

```python
>>> f"{2 + 2}"
'4'
>>> f"{name.upper()}"
'ADA'
```

## `=` for debugging

```python
>>> total = 41
>>> f"{total=}"
'total=41'
```

The name and the value, from one character. This is the print-debugging idiom in modern Python
and it is worth the muscle memory.

## The format spec

After a colon inside the braces, you say **how**:

```python
>>> f"{3.14159:.2f}"
'3.14'
>>> f"{1234567:,}"
'1,234,567'
>>> f"{0.734:.1%}"
'73.4%'
>>> f"{42:>8}"
'      42'
>>> f"{42:08}"
'00000042'
```

| | |
|---|---|
| `.2f` | two decimal places, fixed |
| `,` or `_` | thousands separator |
| `%` | as a percentage, and it multiplies by 100 |
| `>` `<` `^` | right, left, centre, in a width |
| `0` | pad with zeros |
| `e` | scientific |
| `b` `o` `x` | binary, octal, hex |

**The width can itself be a variable**: `f"{name:>{w}}"`.

## Braces you want to keep

Double them: `f"{{literal}}"` prints `{literal}`.

## The two older ways

You will meet both in code you did not write.

```python
"Hello, {}".format(name)     # .format, from Python 2.6
"Hello, %s" % name           # %, from the beginning
```

Both still work. Neither is worth writing now, with one honest exception: logging calls take the
`%` form on purpose, so the formatting is skipped when the message is not going to be emitted.

## What an f-string is not

It is not a template you can store and fill in later — it is evaluated where it is written. And
it is **not** how you build SQL, a shell command or HTML. `sql-databases` has a section on
exactly the hole an f-string opens there, and the answer is a parameter every time.
