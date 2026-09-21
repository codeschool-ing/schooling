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
