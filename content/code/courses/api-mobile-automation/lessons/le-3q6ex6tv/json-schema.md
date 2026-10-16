---
title: JSON Schema, what an answer must look like
version: 1
---

**A JSON Schema is a JSON document that describes other JSON documents: which fields they have, what
type each is, which values are allowed.** A test that asserts `seats_left` equals 4 checks one field
of one answer. A schema checks every field of every answer it is given, including the fields nobody
thought to assert on, and the same file serves every tool that reads JSON Schema. Lesson 2's
`openapi.yaml` already holds schemas, in its `components`; OpenAPI 3.1 uses JSON Schema for them. This
lesson takes two of them out into files of their own, so that a test can load them directly.

JSON Schema has several published versions, called drafts. The current one is **2020-12**, and the
`$schema` field at the top of a schema says which one it is written in. That field matters more than
it looks: section 04 meets two tools that read it differently.

## A show

Make a directory with `mkdir ~/boxoffice/schemas` and save it as `schemas/show.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://boxoffice.example/schemas/show.json",
  "title": "Show",
  "description": "One show, as GET /v1/shows/{id} answers it.",
  "type": "object",
  "required": ["id", "title", "starts_at", "price_cents", "seats_left"],
  "additionalProperties": false,
  "properties": {
    "id": { "type": "string", "pattern": "^sh-[0-9]+$" },
    "title": { "type": "string", "minLength": 1 },
    "starts_at": { "type": "string", "format": "date-time" },
    "price_cents": { "type": "integer", "minimum": 0 },
    "seats_left": { "type": "integer", "minimum": 0 }
  }
}
```

## An order

Save it as `schemas/order.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://boxoffice.example/schemas/order.json",
  "title": "Order",
  "description": "One order, as POST /v1/orders and GET /v1/orders/{id} answer it.",
  "type": "object",
  "required": ["id", "show_id", "seats", "total_cents", "status"],
  "additionalProperties": false,
  "properties": {
    "id": { "type": "string", "pattern": "^ord-[0-9]+$" },
    "show_id": { "type": "string", "pattern": "^sh-[0-9]+$" },
    "seats": { "type": "integer", "minimum": 1, "maximum": 6 },
    "total_cents": { "type": "integer", "minimum": 0 },
    "status": { "enum": ["confirmed", "declined", "failed"] },
    "payment": { "type": "string" }
  },
  "if": { "properties": { "status": { "const": "confirmed" } } },
  "then": { "required": ["payment"] }
}
```

## Reading them

| keyword | in these files | says |
|---|---|---|
| `type` | `object`, `string`, `integer` | the JSON type; `integer` refuses `65.5`, which `number` would accept |
| `required` | the five or six fields | each must be present; a field missing is the commonest defect a schema finds |
| `properties` | one entry per field | the rules for that field, when it is present |
| `additionalProperties: false` | both files | no field beyond the ones listed |
| `pattern` | `^sh-[0-9]+$`, `^ord-[0-9]+$` | a regular expression the string must match |
| `format` | `date-time` | a named format, here RFC 3339's date and time with an offset |
| `minimum`, `maximum`, `minLength` | seats from 1 to 6, no negative price | numeric and length bounds |
| `enum` | the order's `status` | the value must be one of these |
| `if` / `then` | a `confirmed` order | when the `if` part matches, the `then` part applies: a confirmed order must carry its `payment` |

Two of those deserve a second look. **`additionalProperties: false` is a choice, not a default.** In a
schema that tests boxoffice's own answers it is right: boxoffice builds an order with a `client` field
and removes it before answering, with `const { client, ...body } = order`, and a strict schema is what
would catch the day somebody forgets that line and starts telling every caller which program placed
each order. In a schema a *client* uses to read boxoffice, the same keyword would make the client
break whenever boxoffice adds a harmless field. Who owns the schema decides which way it should lean,
and section 05 comes back to that.

**`format` is checked only if the validator is asked to.** The JSON Schema standard leaves format
checking optional, so `"format": "date-time"` on its own may be no more than a note. Section 03 turns
the check on.
