---
title: One function and a table of rows
version: 1
---

```python
@pytest.mark.parametrize("title,expected", [
    ("Hello World", "hello-world"),
    ("ALL CAPS", "all-caps"),
    ("already-done", "already-done"),
    ("Trailing ", "trailing-"),
])
def test_slugify(title, expected):
    assert slugify(title) == expected
```

```sh
test_slug.py::test_slugify[Hello World-hello-world] PASSED               [ 25%]
test_slug.py::test_slugify[ALL CAPS-all-caps] PASSED                     [ 50%]
test_slug.py::test_slugify[already-done-already-done] PASSED             [ 75%]
test_slug.py::test_slugify[Trailing -trailing-] PASSED                   [100%]
```

**Four tests, not one.** Each row runs on its own, gets its own name built from the arguments, and
fails on its own — so a report names the row that broke rather than the function that contains it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"One parametrised function becomes four independent tests. Each gets its own name built from its arguments and its own verdict, so a failure names the row that broke rather than the function that contains it.\"> <text x=\"160\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">as a loop inside one test</text> <rect x=\"20\" y=\"36\" width=\"280\" height=\"132\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"160\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">test_slugify</text> <text x=\"160\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">PASSED</text> <text x=\"500\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">parametrised</text> <rect x=\"340\" y=\"36\" width=\"244\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"462\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">test_slugify[Hello World-hello-world]</text> <text x=\"596\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">PASSED</text> <rect x=\"340\" y=\"78\" width=\"244\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"462\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">test_slugify[ALL CAPS-all-caps]</text> <text x=\"596\" y=\"94\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">PASSED</text> <rect x=\"340\" y=\"120\" width=\"244\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"462\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">test_slugify[already-done-already-done]</text> <text x=\"596\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">PASSED</text> <rect x=\"340\" y=\"162\" width=\"244\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"462\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">test_slugify[Trailing -trailing-]</text> <text x=\"596\" y=\"178\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">PASSED</text> <text x=\"360\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Both are green today. On the day a row breaks, one of them names the input that broke it</text> <text x=\"360\" y=\"241\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">and the other names the function that contains it — and stops before trying the rest.</text> </svg>", "caption": "Four tests, not one. A loop inside a single test stops at the first failure and reports the function; this reports the row."}
```

## Which is the point, and the loop is not it

```python
def test_slugify():
    for title, expected in CASES:      # one test
        assert slugify(title) == expected
```

A loop stops at the first bad row and tells you nothing about the rest. The decorator is the same
table with each row reported separately, and that difference is the whole reason to write it this
way.

## Running one row

```sh
pytest "test_slug.py::test_slugify[ALL CAPS-all-caps]"
```

The bracketed id is a real address. Quote it — brackets and spaces belong to your shell otherwise.

## Naming the rows

```python
@pytest.mark.parametrize("value,expected", [
    pytest.param("", "", id="empty"),
    pytest.param("  ", "", id="only-spaces"),
])
```

When the arguments are long or unprintable the generated id is unreadable, and `id=` replaces it.
A row that earns a name usually earns a comment too.

## Stacking

```python
@pytest.mark.parametrize("code", ["BRL", "USD"])
@pytest.mark.parametrize("amount", [0, 1, 1000])
def test_conversion(code, amount):
    ...
```

Two decorators produce every combination — six tests here. **It multiplies**, so three of these is
a suite nobody meant to write.

## And what does not belong in the table

A row that needs its own setting up, a row whose assertion is a different sentence, a row that is
really testing something else. When the body grows an `if` on which row it is, the table has
stopped being a table.
