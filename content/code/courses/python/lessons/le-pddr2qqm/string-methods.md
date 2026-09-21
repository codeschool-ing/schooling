---
title: The dozen that carry the work
version: 1
---

Every one of these returns a **new** string. None of them changes the one you called it on.

## Cleaning up

```python
>>> "  ada  ".strip()
'ada'
>>> "ada.csv".removesuffix(".csv")
'ada'
```

`strip` removes whitespace from both ends; `lstrip` and `rstrip` do one end each. Given an
argument it removes those *characters*, not that string:

```python
>>> "report.csv".strip(".csv")
'report'
>>> "discos.csv".strip(".csv")
'disco'
```

The first one is a coincidence. `strip(".csv")` means *remove any of `.`, `c`, `s`, `v` from both
ends, for as long as they keep appearing* — and `discos` ends in an `s`, so the `s` goes too. **Use
`removesuffix` when you mean a suffix**, which is what it is for.

## Splitting and joining

```python
>>> "a,b,c".split(",")
['a', 'b', 'c']
>>> ",".join(["a", "b", "c"])
'a,b,c'
```

`split` with no argument splits on any run of whitespace and drops the empties, which is almost
always what you want for a line of text.

**`join` is called on the separator**, which reads backwards until it does not. It is also the
right way to build a string from many pieces — the section above said why.

## Asking

```python
>>> "report.csv".endswith(".csv")
True
>>> "ada" in "ada lovelace"
True
>>> "ada lovelace".find("love")
4
```

`startswith` and `endswith` take a tuple if you want several: `name.endswith((".csv", ".tsv"))`.

**`find` returns `-1` when it is not there** and `index` raises instead. Use `in` when you only
want to know.

## Changing

```python
>>> "2026-09-21".replace("-", "/")
'2026/09/21'
>>> "Ada".lower(), "Ada".upper()
('ada', 'ADA')
```

`replace` takes a count as a third argument. `casefold()` is `lower()` for comparing text in
languages where lowercase is not enough, and it is the right one for a case-insensitive check.

## The table worth keeping

| | |
|---|---|
| `strip` `lstrip` `rstrip` | whitespace off the ends |
| `split` `join` | apart, and back together |
| `replace` | one substring for another |
| `lower` `upper` `title` `casefold` | case |
| `startswith` `endswith` `find` `count` | asking |
| `removeprefix` `removesuffix` | when you mean a prefix or a suffix |
| `zfill` `ljust` `rjust` | padding, when a format spec is not to hand |
| `isdigit` `isalpha` `isspace` | what the characters are |

`dir("")` lists the rest, and `help(str.partition)` explains any of them without leaving the
prompt.
