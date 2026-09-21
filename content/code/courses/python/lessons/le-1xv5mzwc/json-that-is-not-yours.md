---
title: The key that was there yesterday
version: 1
---

The documentation said every record has an `address` with a `city` in it. Then one of them does
not, and `record["address"]["city"]` raises three hundred rows in.

## `get`, with a default

```python
city = record.get("address", {}).get("city", "")
```

Lesson 3's shape, and the empty dictionary in the middle is what keeps the second `get` legal. It
is not elegant and it does not raise.

**Decide what missing MEANS before you write the default.** An empty string that flows into a
report as a blank cell is fine; an empty string that becomes a database key is a bug you have
just written.

## `null` is not missing

```python
{"city": null}      → record["city"] is None
{}                  → record["city"] raises
```

Two different situations, and `get` with a default only catches the second. `record.get("city")
or ""` catches both — and also turns `0` and `False` into `""`, which is the trap in that idiom.

```python
value = record.get("city")
if value is None:
    value = ""
```

Longer, and it means exactly what it says.

## The type you did not expect

```python
data = json.load(f)
for row in data:          # data is a dict, not a list
    row["name"]           # row is a KEY — a string
```

Iterating a dictionary gives keys, so this fails with a `TypeError` about string indices, three
lines from the real problem. **Check the shape at the boundary:**

```python
if not isinstance(data, list):
    raise ValueError(f"{path}: expected a list of records, got {type(data).__name__}")
```

One line, at the edge, and every later failure is about the data rather than about the shape.

## Numbers that are strings

`{"score": "91"}` is legal JSON and a string in Python. `sum` over those raises, `sorted` sorts
them as text — `"100" < "91"` — and neither says the word "string". Convert at the boundary, and
name the row when it fails.

## The rule

**Read it as though they meant the documentation, and handle it as though they did not.** The
error you raise should name the file, the row and the field — because when this fires you will be
looking at somebody else's export, and nothing else in the program knows where it came from.
