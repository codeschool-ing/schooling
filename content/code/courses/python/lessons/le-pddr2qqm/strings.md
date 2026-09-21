---
title: Text is a sequence, and it cannot be changed
version: 1
---

```python
name = "Ada"
name = 'Ada'
```

Single and double quotes are identical. Pick whichever avoids escaping: `"it's"` needs no
backslash, and `'say "hi"'` needs none either.

## Escapes

`\n` is a newline, `\t` a tab, `\\` a backslash, `\"` a quote inside the same kind of quote.

```python
print("first\nsecond")
```
```
first
second
```

**A raw string turns them off**, and it is why Windows paths and regular expressions are written
with an `r` in front:

```python
r"C:\Users\ada"     # not an escape sequence in sight
```

Lesson 10 uses this on every pattern.

## Triple quotes

Three quotes open a string that may run over several lines, and the newlines are part of it. This
is also the syntax lesson 1 met as a docstring — the same literal, in a position that gives it a
second job.

## Immutable

```python
>>> name = "Ada"
>>> name[0] = "E"
TypeError: 'str' object does not support item assignment
```

**A string cannot be changed in place.** Every method that looks like it edits one actually
returns a new string:

```python
>>> name.upper()
'ADA'
>>> name
'Ada'
```

`name` is untouched. To keep the result you have to assign it: `name = name.upper()`. This catches
everybody once, and after that it never does again.

## The two operators

`+` joins, `*` repeats:

```python
>>> "ab" + "cd"
'abcd'
>>> "-" * 20
'--------------------'
```

**Joining in a loop is the wrong tool.** Each `+` builds a whole new string, so a thousand of them
is a thousand copies. `"".join(pieces)` is the one to use, and it is in the next section.

## Indexing and length

```python
>>> "Python"[0]
'P'
>>> "Python"[-1]
'n'
>>> len("Python")
6
```

Counting from zero, and negative indices count from the end. Slicing is lesson 3's section,
because it is the same syntax for every sequence and strings are one.
