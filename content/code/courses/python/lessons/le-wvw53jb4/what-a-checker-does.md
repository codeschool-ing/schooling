---
title: A checker reads the program and runs none of it
version: 1
---

```python
rates = {"BRL": 1.0, "USD": 5.4}

def find(code: str) -> float | None:
    return rates.get(code)

def total(amount: float, code: str) -> float:
    return amount * find(code)
```

```sh
a.py:7: error: Unsupported operand types for * ("float" and "None")  [operator]
a.py:7: note: Right operand is of type "float | None"
```

**Nothing ran.** No file was opened, no `total` was called, no test existed. The checker read
the annotations, followed `find` to its `return`, saw that `dict.get` answers `None` when the key
is absent, and looked at what line 7 does with the result.

## What this finds that a test would not

A test finds what you thought to try. A checker follows every call in the program, including the
branch nobody has taken and the caller in the file you were not looking at.

```sh
error: Argument 1 to "totals" has incompatible type "list[str]"; expected "list[int]"  [arg-type]
error: Incompatible return value type (got "int", expected "str")  [return-value]
error: Item "None" of "Row | None" has no attribute "city"  [union-attr]
error: "Point" has no attribute "z"  [attr-defined]
error: Name "sendmail" is not defined  [name-defined]
error: Missing positional argument "name" in call to "greet"  [call-arg]
```

Each of those is a program that imports cleanly and raises at some point in the future. The last
two do not even need annotations — a misspelled name and a call with the wrong number of
arguments are found in a file with no types in it at all.

## What it does not find

```python
def average(values: list[float]) -> float:
    return sum(values) * len(values)
```

Correct in every type and wrong in the only way that matters. A checker has no opinion about
`*` against `/`, about the formula being backwards, or about the file being the wrong file.

**A checker is not a test.** It says the pieces fit; it says nothing about whether the thing they
build is the thing you wanted. Lesson 16 is the other half, and neither half replaces the other.

## And the one it is honest about

```python
row = {"city": "Recife", "code": "BR"}
print(row["citty"])
```

```sh
Success: no issues found in 1 source file
```

A plain `dict[str, str]` accepts any string as a key, so the typo is a valid expression that
raises `KeyError` at run time. **The checker only knows what the types told it** — and lesson 14's
`TypedDict` is how you tell it, which is when the same line becomes
`TypedDict "Row" has no key "citty"` with a `Did you mean "city"?` underneath.
