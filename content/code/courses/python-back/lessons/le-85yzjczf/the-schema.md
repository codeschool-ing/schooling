---
title: The schema FastAPI writes from your code
version: 1
---

Lesson 1 noticed that the hello endpoint published `/openapi.json` without anybody writing it. That
document is an **OpenAPI** description of the API: a standard format, JSON or YAML, that lists every
path, method, parameter and body, with the shape of each request and response. FastAPI builds it from
the routes, the type hints and the Pydantic models, so it is exactly as current as the code.

This lesson changes `app/main.py` and adds `app/dependencies.py`; both are in the section on
dependencies, and with them saved, the schema starts like this:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/openapi.json | head -c 300; echo
{"openapi":"3.1.0","info":{"title":"agenda API","description":"Community events with a limited number of seats.","version":"0.2.0"},"paths":{"/events":{"get":{"tags":["events"],"summary":"List Events","description":"Events in date order, optionally only those at one venue.","operationId":"list_event
```

The `title`, `description` and `version` are the arguments of `FastAPI(...)`. Every path, with its
methods:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/openapi.json | python3 -c 'import json, sys; d = json.load(sys.stdin); [print(m.upper().ljust(5), p) for p, ops in d["paths"].items() for m in ops]'
GET   /events
POST  /events
GET   /events/{slug}
POST  /events/{slug}/registrations
GET   /events/{slug}/registrations
```

And every shape the API sends or accepts, under `components`:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/openapi.json | python3 -c 'import json, sys; print(list(json.load(sys.stdin)["components"]["schemas"]))'
['EventIn', 'EventOut', 'HTTPValidationError', 'RegistrationIn', 'RegistrationOut', 'RegistrationPublic', 'ValidationError']
```

Five are this API's models. **`HTTPValidationError` and `ValidationError` are FastAPI's**: the 422
body of lesson 7, documented for every route that validates something, so a client knows the shape of
the error before it ever gets one. One model, in full:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/openapi.json | python3 -c 'import json, sys; print(json.dumps(json.load(sys.stdin)["components"]["schemas"]["RegistrationIn"], indent=2))'
{
  "properties": {
    "name": {
      "type": "string",
      "maxLength": 100,
      "minLength": 1,
      "title": "Name"
    },
    "email": {
      "type": "string",
      "format": "email",
      "title": "Email"
    }
  },
  "type": "object",
  "required": [
    "name",
    "email"
  ],
  "title": "RegistrationIn"
}
```

The `Field` constraints of lesson 7 became **JSON Schema** keywords, `minLength` and `maxLength`, and
`EmailStr` became `"format": "email"`. JSON Schema is a standard of its own, and validators exist for
it in every language, which is what makes the document useful outside Python.

## What a schema is for

| who | what they do with it |
|---|---|
| people | read it through a documentation page, the next section |
| other teams | **generate a client** in TypeScript, Kotlin or Go instead of writing one by hand |
| tests and gateways | check that requests and responses match it |
| you | **review it in a pull request**: a change to the schema is a change to the contract |

The last row is the one teams forget. A renamed field in a model is a one-line diff in Python and a
breaking change for every client, and a diff of `/openapi.json` before and after is how it gets
noticed. Django's DRF does not write this document by itself; libraries such as `drf-spectacular`
generate it from the serializers.
