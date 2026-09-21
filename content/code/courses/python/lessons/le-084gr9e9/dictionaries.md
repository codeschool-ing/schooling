---
title: Keys to values, and the lookup that does not walk
version: 1
---

```python
person = {"name": "Ada", "city": "London"}
```

Braces, `key: value`, comma-separated. Keys are usually strings; they may be any **immutable**
value, which is why a tuple works and a list does not.

## Reading

```python
>>> person["name"]
'Ada'
>>> person["email"]
KeyError: 'email'
>>> person.get("email")
None
>>> person.get("email", "unknown")
'unknown'
```

**`[]` raises and `get` does not.** Use `[]` when a missing key is a bug you want to hear about,
and `get` when it is a case you are handling — which for anything that came out of a JSON file is
most of the time.

## Writing

```python
person["email"] = "ada@example.com"   # add or replace
person.setdefault("city", "Paris")    # only if absent
del person["email"]
value = person.pop("city", None)      # remove and return, with a fallback
```

`update` merges another dictionary in, and `a | b` does the same as a new dictionary.

## Walking it

```python
for key in person:                    # keys
for key, value in person.items():     # both — and this is the one you want
for value in person.values():
```

**Insertion order is guaranteed** since Python 3.7. What you put in first comes out first, and it
is a promise of the language rather than an accident.

## Asking

```python
>>> "name" in person
True
```

`in` on a dictionary checks the **keys**. And it is one step rather than a walk — Python computes
a hash of the key and goes straight there, however many entries there are.

That is the whole reason this container is everywhere. Turning a list of records into a dictionary
keyed by id, once, converts every later lookup from a walk into a step; lesson 20 is where that
turns an O(n²) loop into an O(n) one.

## Counting, which you will do constantly

```python
counts = {}
for word in words:
    counts[word] = counts.get(word, 0) + 1
```

That is the pattern. `collections.Counter` in lesson 7 does it in one line, and it is worth
writing by hand once so the one-liner is not magic.
