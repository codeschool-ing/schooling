---
title: Names and shapes
version: 1
---

**A JSON contract carries decisions that no language makes for you**: how names are spelled, how a
moment in time is written, what a missing value looks like, and how a list is wrapped. None of them
has one right answer. What is wrong is making each one twice, differently, so that a client has to
remember which endpoint does what.

## One spelling for every name

The usual reasoning is that each field can be named the way that reads best in the moment. Then one
response has `author_id` and the next has `authorId`, and every client carries a list of
exceptions. Pick one casing for the whole API. GitHub's and Stripe's APIs use snake_case, as shelf
does; Google's JSON style guide asks for camelCase. Both work; a mix of the two never does.

The same goes for meaning. If `price` is an object with `amount_cents` and `currency` in one place,
it is that object everywhere, including in the body a client sends.

## Time with its offset

**A timestamp is a string in RFC 3339**, the profile of ISO 8601 written for the internet: date,
`T`, time, and an offset from UTC. The same instant, written by `date` in São Paulo and in UTC:

```
ana@api:~$ date -Iseconds; TZ=UTC date -Iseconds
2026-10-10T01:29:39-03:00
2026-10-10T04:29:39+00:00
```

Both strings are correct and name the same moment; any reader can turn one into the other. The
string that causes trouble is the one with no offset, and it is easy to produce:

```
ana@api:~$ python3 -c 'from datetime import datetime; print(datetime.now().isoformat(timespec="seconds"))'
2026-10-10T01:29:39
```

That is São Paulo's local time with nothing saying so. A reader that assumes UTC places it three
hours away from when it happened. Send timestamps with an offset, ideally `Z` or `+00:00`, and send a
calendar date that has no time, such as a book's publication date, as a date alone: `"1899-01-01"`.

## Absent, null and empty are three answers

A field can be missing, present with `null`, or present with an empty value, and many readers cannot
tell the first two apart. `jq` is one of them unless asked directly:

```
ana@api:~$ echo '{"subtitle": null}' | jq -c '[.subtitle, has("subtitle")]'
[null,true]
ana@api:~$ echo '{}' | jq -c '[.subtitle, has("subtitle")]'
[null,false]
```

`.subtitle` is `null` both times; only `has` sees the difference. So the contract gives each its own
meaning and keeps it. **Absent** means "not part of this message", and in a partial update, "leave it
as it is". **`null`** means "known to have no value": JSON Merge Patch, RFC 7396, uses exactly this
to remove a field, because absent already means "unchanged". **An empty list is `[]`**, never `null`
and never absent, so that a client can loop over it without checking first.

## Booleans are booleans

A flag sent as a string reads correctly to a person and wrongly to a program. In `jq`, as in Python
and JavaScript, any non-empty string counts as true:

```
ana@api:~$ echo '{"in_stock": "false"}' | jq 'if .in_stock then "in stock" else "sold out" end'
"in stock"
```

The book is sold out and the client says it is in stock. shelf's catalogue sends `"in_stock": false`,
a real boolean, and the same rule runs the other way: its schema refuses `"1891"` where it asks for
a year.

## Enums are strings that may grow

A value from a fixed set, such as a currency or an order's state, goes as a readable string,
`"BRL"` or `"shipped"`, never as a number whose meaning lives in a document. And the set grows: the
day the shop sells in euros, `"EUR"` appears. **A client must treat a value it does not know as
"something else" rather than as an error**, and the contract should say, next to the enum, that it
may grow.

## An envelope for lists, none for items

One book is sent as the book itself, with no wrapper. A list of books is the other way round: a bare
array has nowhere to put anything except the books, so the day it needs a link to the next page,
adding one changes its type and breaks every client. shelf's catalogue wraps lists from the start:

```json
{"items": [ ... ], "next": "/v1/books?limit=2&after=WyJpZCIsIDIsIDJd"}
```

`next` is always present, and `null` on the last page, which is the second meaning above put to
work: there is a next page, or there is known to be none.

| decision | shelf's choice |
|---|---|
| casing | snake_case everywhere, in and out |
| timestamps | RFC 3339 strings with an offset |
| a value with no value | `null`, present; absent only means "not sent" |
| an empty list | `[]` |
| flags | `true` and `false` |
| enums | strings, documented as open to new values |
| one item | the object itself |
| a list | `{"items": [...], "next": ...}` |
