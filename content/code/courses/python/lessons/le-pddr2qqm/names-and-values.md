---
title: A name is a label on a value, not a box
version: 1
---

```python
x = 5
```

Read that as *the name `x` now refers to the value 5*, not *the box called `x` now contains 5*.
The difference is invisible with numbers and becomes the whole story in lesson 3.

## Rebinding

```python
x = 5
x = "five"
```

Perfectly legal. The name stops referring to the number and starts referring to the string. Python
is **dynamically typed**: values have types, names do not.

That is freedom and it is also rope. A name that holds a number in one branch and a string in
another is a name nobody can reason about, and it is exactly what lesson 14's annotations are for.

## Two names, one value

```python
a = [1, 2, 3]
b = a
b.append(4)
print(a)
```
```
[1, 2, 3, 4]
```

`b = a` did not copy anything. Both names refer to the same list, and changing it through one
shows through the other. `id(a) == id(b)` is `True` — `id` is the identity of the value itself.

**With numbers and strings you will never notice**, because they cannot be changed in place. With
lists and dictionaries it is lesson 3's `copying` section, and it is the single most common
surprise in the language.

## Naming

`snake_case`, lowercase, and a name that says what the thing is. Letters, digits and underscores;
not starting with a digit.

**You cannot use a keyword** — `class`, `import`, `from`, `is`, `in`, `lambda` and about thirty
others. `list = [1, 2]` is not a keyword and is legal, and it is still a mistake: you have just
lost the ability to call `list()` for the rest of that scope. Lesson 17's linter flags exactly
this.

## Deleting

`del x` removes the name. The value goes when nothing refers to it any more, and that is the
interpreter's business rather than yours.
