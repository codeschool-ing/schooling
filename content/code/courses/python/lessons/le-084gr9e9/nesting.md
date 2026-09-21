---
title: A list of dictionaries, which is what every file looks like
version: 1
---

Containers hold anything, including other containers. One shape turns up more than all the others
put together:

```python
people = [
    {"name": "Ada", "city": "London", "langs": ["python", "c"]},
    {"name": "Bo",  "city": "Porto",  "langs": ["go"]},
]
```

**That is what a JSON file is** when lesson 9 reads one, and what a CSV becomes with `DictReader`,
and what an API returns in lesson 21. Getting comfortable with it now pays for the rest of the
course.

## Reaching in

```python
>>> people[0]["city"]
'London'
>>> people[0]["langs"][1]
'c'
```

Left to right: the first person, their city. Each `[...]` is one step down.

## The three questions you will ask of it

```python
# every city
cities = [p["city"] for p in people]

# the one with a given name
ada = next(p for p in people if p["name"] == "Ada")

# grouped by city
by_city = {}
for p in people:
    by_city.setdefault(p["city"], []).append(p)
```

The first is lesson 4's comprehension. The third is the `setdefault` idiom, and
`collections.defaultdict` in lesson 7 is the same thing with the default built in.

## Where it goes wrong

**A missing key deep in the structure.** `p["address"]["city"]` raises `KeyError` on the first
half, and the traceback says `'address'` — which is the information you need, so read it rather
than guessing.

For data you did not produce, `p.get("address", {}).get("city")` answers `None` rather than
raising. Lesson 9 has the section on JSON that is not yours, and lesson 14 has `TypedDict`, which
lets a checker know the shape in advance.

**And do not go more than about three deep.** At that point the nesting is holding structure that
a class or a `dataclass` should be holding, and lesson 6 is where that lives.
