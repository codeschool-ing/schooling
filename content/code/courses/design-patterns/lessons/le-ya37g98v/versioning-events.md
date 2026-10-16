---
title: "Versioning events: old facts, new code"
version: 1
---

**Events are written once and read for years, by code that keeps changing, so their shape has to
evolve without rewriting what is stored.** The usual tool is an *upcaster*: a function that turns
an event of an old version into the current one at the moment it is read. The stored row stays as
it was written; every reader above the upcaster sees one shape.

The tempting fix, and the wrong one, is a migration that rewrites old events into the new shape, the
way a table gets a new column. It breaks the one promise the store makes. The trigger of the
store's section would refuse it, and rightly: a history that has been edited cannot be trusted as
history, and a bug in the migration destroys the only record there was.

```schooling-example
{"language": "python", "file": "upcast.py", "parts": [
 {"code": "# upcast.py\nfrom collections import Counter\nfrom store import EventStore\n\nTITLE_OF = {\"C1\": \"Dom Casmurro\", \"C2\": \"Dom Casmurro\", \"C3\": \"Vidas Secas\"}  # in 2025", "note": "The copies the library had when the first events were written. The upcaster needs it to fill in what old events left out."},
 {"code": "\n\ndef lent_v1_to_v2(event: dict) -> dict:\n    return {**event, \"v\": 2, \"title\": TITLE_OF[event[\"copy\"]], \"days\": 14}", "note": "One step: a version 1 `CopyLent`, which named only the copy, becomes a version 2, which also names the title and the loan length. Old loans were all books, so 14 days is a fact about 2025, not a guess."},
 {"code": "\n\nUPCASTERS = {(\"CopyLent\", 1): lent_v1_to_v2}", "note": "Steps keyed by type and version. An event with no `v` is version 1, which is how the first events were written, before anybody thought about versions."},
 {"code": "\n\ndef upcast(event: dict) -> dict:\n    while (step := UPCASTERS.get((event[\"type\"], event.get(\"v\", 1)))) is not None:\n        event = step(event)\n    return event", "note": "Apply steps until none matches, so a version 1 event would pass through 2 to 3 the day a third version exists. Only the reading changes; the stored row is never touched."},
 {"code": "\n\nif __name__ == \"__main__\":\n    store = EventStore(\":memory:\")\n    store.append(\"member-bia\", 0, [{\"type\": \"CopyLent\", \"copy\": \"C1\"},\n                                   {\"type\": \"CopyLent\", \"copy\": \"C3\"}])\n    store.append(\"member-caio\", 0, [{\"type\": \"CopyLent\", \"v\": 2, \"copy\": \"F1\",\n                                     \"title\": \"Central do Brasil\", \"days\": 7}])\n    for position, raw in store.read_all():\n        print(position, \"stored: \", raw)\n        print(position, \"read as:\", upcast(raw))\n    events = [upcast(raw) for _, raw in store.read_all()]\n    print(Counter(e[\"title\"] for e in events if e[\"type\"] == \"CopyLent\").most_common())", "note": "Two old loans written the version 1 way and one new one, then each printed as stored and as read, and a count of loans per title that works across both."}
]}
```

```
ana@laptop:~/patterns/events$ python3 upcast.py
1 stored:  {'type': 'CopyLent', 'stream': 'member-bia', 'copy': 'C1'}
1 read as: {'type': 'CopyLent', 'stream': 'member-bia', 'copy': 'C1', 'v': 2, 'title': 'Dom Casmurro', 'days': 14}
2 stored:  {'type': 'CopyLent', 'stream': 'member-bia', 'copy': 'C3'}
2 read as: {'type': 'CopyLent', 'stream': 'member-bia', 'copy': 'C3', 'v': 2, 'title': 'Vidas Secas', 'days': 14}
3 stored:  {'type': 'CopyLent', 'stream': 'member-caio', 'v': 2, 'copy': 'F1', 'title': 'Central do Brasil', 'days': 7}
3 read as: {'type': 'CopyLent', 'stream': 'member-caio', 'v': 2, 'copy': 'F1', 'title': 'Central do Brasil', 'days': 7}
[('Dom Casmurro', 1), ('Vidas Secas', 1), ('Central do Brasil', 1)]
```

Positions 1 and 2 were stored the old way, with a copy and nothing else, and come out of `upcast`
with a version, a title and a 14-day loan. Position 3 was written as version 2 and passes through
unchanged. The count at the end treats all three alike: one loan each of *Dom Casmurro*, *Vidas
Secas* and *Central do Brasil*, which would have raised `KeyError` on `"title"` without the
upcaster.

## Which changes need what

Not every change needs an upcaster, and some changes are not changes to an event at all.

| change | what to do |
|---|---|
| a new field that old events can do without | give it a default when reading; no new version |
| a new field old events must have | a new version and an upcaster that derives it, as `title` here |
| a field renamed | a new version and an upcaster that renames; never reuse the old name for another meaning |
| a different fact altogether | a new event type, such as `LoanExtended`; the old type keeps its meaning |
| a field whose meaning changes, such as a fine now in reais | never in place; a new field or a new type, because old events meant cents |

The last row is the one that does damage quietly. If `fine` silently became reais in new events,
every projection summing fines would add cents to reais, and nothing would raise an error. **An
event's meaning is fixed when it is written**; only its shape may be adapted on the way out.

## What the upcaster may know

`lent_v1_to_v2` reads `TITLE_OF`, the copies as they were in 2025. That table is part of the
upcaster's code, frozen, and it must stay that way: if it read today's catalogue, a copy reassigned
to another title in 2027 would rewrite the history of every loan of it. Upcasters, like `evolve` and
projections, must be **deterministic in the event**, giving the same output for the same stored row
forever.

When an old event genuinely lacks a fact and nothing frozen can supply it, say so in the new shape:
a `title` of `None` that every reader handles is honest; a guessed title is a fabricated record.

## In your language

Every event-sourced stack has the same hook under a different name. Axon Framework in Java has
*upcasters* by that name, chained per type and revision. EventStoreDB clients and Marten for .NET
transform events on read. In TypeScript and Go the upcaster is usually a plain function in the
deserialisation step, as here, often switching on a `version` field that the first events forgot,
which is why `event.get("v", 1)` treats a missing version as 1. **Put the version in the first event
you ever write**, even if it is 1 and nothing reads it yet.
