---
title: A name is a label on a value, not a box
version: 2
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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"The names a and b are two arrows pointing at one list. Appending through either name changes the single list both of them refer to, because the assignment b = a copied nothing.\"> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <text x=\"24\" y=\"22\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">two names</text> <rect x=\"24\" y=\"32\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"84\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">a</text> <rect x=\"24\" y=\"96\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"84\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">b</text> <path d=\"M150 52 L322 74\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <path d=\"M150 116 L322 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"448\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">one list, at one address</text> <rect x=\"328\" y=\"32\" width=\"240\" height=\"104\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"448\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--paper)\">[1, 2, 3, 4]</text> <text x=\"360\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">A million-row table is handed to a function this way, without being copied.</text> <text x=\"360\" y=\"185\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">It is a surprise exactly once, and after that it is a tool.</text> </svg>", "caption": "An assignment between names moves an arrow. It never duplicates what the arrow points at."}
```

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
