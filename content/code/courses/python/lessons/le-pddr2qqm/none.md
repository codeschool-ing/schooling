---
title: `None` is a value, and `is None` is how you ask
version: 2
---

`None` is the value that means *there is no value*. It is a real object, there is exactly one of
it, and its type is `NoneType`.

## Where it comes from

**A function with no `return` returns it.** This is the single most common way to meet it:

```python
>>> result = print("hello")
hello
>>> result is None
True
```

`print` does its work and returns nothing, so `result` is `None`. A method that changes a list in
place — `sort`, `append`, `reverse` — does the same, which produces the classic:

```python
>>> names = ["b", "a"]
>>> names = names.sort()      # names is now None
```

`sort` sorted the list and returned `None`, and the assignment threw the list away. `sorted(names)`
returns a new list; `names.sort()` is called for its effect and not assigned.

## Asking

```python
if value is None:
if value is not None:
```

**`is` and not `==`.** `is` asks whether it is the same object, and there is only ever one `None`,
so this is both exact and fast. `== None` usually works and can be overridden by a class that
defines `__eq__` badly — lesson 6 shows how. The convention is `is`, everywhere, and the linter in
lesson 17 will say so.

## As a default argument

```python
def greet(name, greeting=None):
    if greeting is None:
        greeting = "Hello"
```

This looks like a long way round and it is the correct one. Lesson 3 has the section on why
`greeting=[]` is a bug that grows between calls, and `None` is the fix for exactly that.

## It is not zero, empty or false

`None` is falsy, which means `if not value` is `True` for `None`, `0`, `""` and `[]` alike. When
the difference matters — and for a value that came from a file or an API it usually does — ask
`is None`.
