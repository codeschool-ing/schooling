---
title: Validation
version: 1
---

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://shelf.example/schemas/book.schema.json",
  "title": "A book, as a client sends it to POST /v1/books",
  "type": "object",
  "additionalProperties": false,
  "required": ["isbn", "title", "author_id", "year", "price"],
  "properties": {
    "isbn": {"type": "string", "pattern": "^97[89][0-9]{10}$"},
    "title": {"type": "string", "minLength": 1, "maxLength": 200},
    "author_id": {"type": "integer", "minimum": 1},
    "year": {"type": "integer", "minimum": 1450},
    "price": {
      "type": "object",
      "additionalProperties": false,
      "required": ["amount_cents", "currency"],
      "properties": {
        "amount_cents": {"type": "integer", "minimum": 0},
        "currency": {"enum": ["BRL"]}
      }
    },
    "stock": {"type": "integer", "minimum": 0, "default": 0}
  }
}
```
