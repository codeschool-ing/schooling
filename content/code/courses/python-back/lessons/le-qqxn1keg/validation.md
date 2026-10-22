---
title: Validation that knows about other rows
version: 1
---

A field's own checks see one value. `validate_capacity` in the serializer sees the event too, and
refuses a capacity below the number of people already registered. The Testing dojo has two:

```
ana@vm:~/agenda$ curl -s -u ana:x9-river-lantern-42 -X PATCH -H "Content-Type: application/json" -d "{\"capacity\": 1}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/
{"capacity":["2 people are already registered."]}
400
```

**400, with the message from `validate_capacity`**, under the field's name, so a client can put it
beside the input. And a value of the wrong type never reaches that method at all:

```
ana@vm:~/agenda$ curl -s -u ana:x9-river-lantern-42 -X PATCH -H "Content-Type: application/json" -d "{\"capacity\": \"forty\"}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/
{"capacity":["A valid integer is required."]}
400
```

## Where each check belongs

| check | where | example |
|---|---|---|
| one value, its type and range | the model field, which the serializer copies | `capacity` is a non-negative integer |
| one value against other rows | `validate_<field>` | capacity not below the registrations |
| several fields together | `validate(self, attrs)` | an end date after a start date |
| a rule that must hold under concurrent writes | the database, or a locked service | one registration per address; the capacity of an event |

The last row is the one to remember. A serializer's check runs in one request and can be raced by
another, exactly like lesson 3's count; **the registration endpoint therefore calls lesson 4's
service** rather than counting in the serializer, which is the next section.
