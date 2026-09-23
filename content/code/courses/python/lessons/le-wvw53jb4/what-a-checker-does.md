---
title: A checker reads the program and runs none of it
version: 2
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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 248\" role=\"img\" aria-label=\"The checker reads the annotations and follows the calls: dict.get answers None when the key is absent, so find may return None, so multiplying by its result may multiply by None. The error is reported without the program ever being run.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <defs><marker id=\"ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs> <rect x=\"20\" y=\"26\" width=\"440\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"240\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">rates.get(code) answers None when the key is absent</text> <rect x=\"20\" y=\"72\" width=\"440\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"240\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">so find(code) may hand back None</text> <path d=\"M240 62 L240 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"20\" y=\"118\" width=\"440\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"240\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">so amount * find(code) may multiply by None</text> <path d=\"M240 108 L240 114\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"20\" y=\"164\" width=\"440\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"240\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">error: Unsupported operand types for * (&quot;float&quot; and &quot;None&quot;)</text> <path d=\"M240 154 L240 160\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"592\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">what actually ran</text> <text x=\"592\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no file was opened</text> <text x=\"592\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">total() was never called</text> <text x=\"592\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no test existed</text> </svg>", "caption": "A test finds what you thought to try. A checker follows every call, including the branch nobody has taken."}
```

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
