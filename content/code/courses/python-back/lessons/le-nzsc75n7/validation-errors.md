---
title: 422 and the shape of a validation error
version: 1
---

A body that fails validation gets a **422 Unprocessable Content**, where DRF answered 400. Both are
defensible: 400 says the request was bad, 422 says it was well-formed JSON whose contents could not
be processed. What matters more is that the body is the same shape every time, so a client handles
all of them with one piece of code:

```
ana@vm:~/agenda-api$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"\", \"email\": \"not-an-address\"}" http://127.0.0.1:8001/events/testing-dojo/registrations | python3 -m json.tool
{
    "detail": [
        {
            "type": "string_too_short",
            "loc": [
                "body",
                "name"
            ],
            "msg": "String should have at least 1 character",
            "input": "",
            "ctx": {
                "min_length": 1
            }
        },
        {
            "type": "value_error",
            "loc": [
                "body",
                "email"
            ],
            "msg": "value is not a valid email address: An email address must have an @-sign.",
            "input": "not-an-address",
            "ctx": {
                "reason": "An email address must have an @-sign."
            }
        }
    ]
}
```

Every error in the list has the same keys:

| key | what it holds |
|---|---|
| `type` | a stable code, `string_too_short`, `value_error`, for a program to test |
| `loc` | where: `"body"`, `"query"` or `"path"`, then the field |
| `msg` | a sentence for a person |
| `input` | the value that was refused |
| `ctx` | the rule's own numbers, such as `min_length` |

## Broken JSON, broken rules

Broken JSON is a 422 too, with the position where the parser gave up:

```
ana@vm:~/agenda-api$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Fábio\"" -w "\n%{http_code}\n" http://127.0.0.1:8001/events/testing-dojo/registrations
{"detail":[{"type":"json_invalid","loc":["body",16],"msg":"JSON decode error","input":{},"ctx":{"error":"Expecting ',' delimiter"}}]}
422
```

And creating an event with two bad fields lists both, here reduced to their types and messages:

```
ana@vm:~/agenda-api$ curl -s -H "Content-Type: application/json" -d "{\"slug\": \"Bad Slug\", \"title\": \"x\", \"starts_at\": \"2026-12-03T19:00:00-03:00\", \"venue\": \"x\", \"capacity\": 0}" http://127.0.0.1:8001/events | python3 -m json.tool | grep -E "\"(type|msg)\""
            "type": "string_pattern_mismatch",
            "msg": "String should match pattern '^[a-z0-9-]+$'",
            "type": "greater_than_equal",
            "msg": "Input should be greater than or equal to 1",
```

## When 422 is the wrong answer

Validation errors are about the **shape** of the data. A request whose data is fine but whose effect
the current state refuses, a slug that already exists, a full event, is not a 422: it is the 409 of
the next section. Keeping the two apart lets a client tell "fix your input" from "the world changed",
which need different screens.
