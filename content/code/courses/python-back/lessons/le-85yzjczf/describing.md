---
title: Describing the API so the pages are worth reading
version: 1
---

A schema generated from code is accurate, and by default it is also terse: a summary derived from the
function's name, `List Events`, and nothing about why. The routes in this lesson's `app/main.py`
carry a little more, and each piece lands somewhere specific:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/openapi.json | python3 -c 'import json, sys; op = json.load(sys.stdin)["paths"]["/events/{slug}/registrations"]["post"]; print(op["tags"], op["summary"]); print(sorted(op["responses"])); print(op["responses"]["409"])'
['registrations'] Register for an event
['201', '409', '422']
{'description': 'The event is full, or the address is already registered'}
```

**`tags`** group operations on the documentation page, **`summary`** replaces the title derived from
the function's name, and **`responses`** documents the 409, which FastAPI could not have found by
reading the code: it only sees `status_code=201` and the 422 that validation can produce. The list
of events shows the docstring and the parameters, including the two that came from a dependency:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/openapi.json | python3 -c 'import json, sys; op = json.load(sys.stdin)["paths"]["/events"]["get"]; print(op["summary"], "|", op["description"]); [print(p["name"], p["in"], p["schema"]) for p in op["parameters"]]'
List Events | Events in date order, optionally only those at one venue.
venue query {'anyOf': [{'type': 'string'}, {'type': 'null'}], 'title': 'Venue'}
limit query {'type': 'integer', 'maximum': 100, 'minimum': 1, 'default': 20, 'title': 'Limit'}
offset query {'type': 'integer', 'minimum': 0, 'default': 0, 'title': 'Offset'}
```

`venue` is optional, `limit` has its range and default, `offset` its minimum, all from the
signatures. **A docstring is documentation that lives where the code changes**, which is the best
argument for writing one on every route.

## What not to put in it

Descriptions are published. Internal hostnames, the names of the database tables, the reason a field
exists in the business, a note about a bug: none of it belongs in a document every client and anyone
with the URL can read. Describe the contract, what to send and what comes back, and leave the
implementation in comments.
