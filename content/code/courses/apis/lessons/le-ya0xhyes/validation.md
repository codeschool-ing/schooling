---
title: Validation with JSON Schema
version: 1
---

**The rules for what a client may send belong in a file, not scattered through `if` statements.**
JSON Schema is a vocabulary for writing those rules as JSON: which fields an object has, which are
required, what type and range each one takes. A library then checks a body against the file, and
the same file can be handed to whoever writes a client.

Lesson 1's `rest.py` checked by hand, and the way it reported shows the cost. It looked for unknown
fields, then wrong types, then missing ones, and answered at the first kind it found. A client
sending a body with four mistakes learns about one kind, fixes it, sends again, and learns about the
next. **A validator should report every error in one answer.**

## The schema

This is the contract for a book that a client sends to the catalogue. Save it in `~/shelf` as
`book.schema.json`, with `nano` as before. JSON has no comments, so this is the one file in the
course that cannot begin with its own path.

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

Read from the top:

| keyword | what it says here |
|---|---|
| `$schema` | which version of JSON Schema this is written in: 2020-12, the current one |
| `$id` | a name for the schema, so other documents can refer to it; nothing is fetched from it |
| `type: object` | the body is an object, so an array or a string is refused before anything else |
| `required` | the five fields a book cannot be created without; `stock` may be left out |
| `additionalProperties: false` | **any field not listed is an error** |
| `pattern` | an ISBN-13 is 978 or 979 and ten more digits |
| `minLength`, `maxLength`, `minimum` | the ranges: a title is not empty, a year is not before printing |
| `enum` | the only currency accepted today, `BRL` |
| `default` | documents what an absent `stock` means; it does not fill it in |

The last row catches people. `default` is an annotation: the validator reads it and does nothing with
it, so `catalogue.py` writes `value.get("stock", 0)` itself.

`additionalProperties: false` is the one that changes behaviour most. Without it, a client that
types `pirce` instead of `price` gets a book created with no price problem reported, because `pirce`
is an extra field nobody looks at, and the client believes it set a price. **On input, an unknown
field is refused.** The section on compatibility explains why the same rule is wrong on the other
side, for what a client reads.

## Checking a body

`python3-jsonschema` brings a command, `jsonschema`, that checks a file against a schema. A book with
several mistakes at once:

```
ana@api:~/shelf$ echo '{"isbn": "978650000007", "title": "", "year": "1891", "price": {"amount_cents": 39.90}, "colour": "red"}' > bad.json
ana@api:~/shelf$ jsonschema -i bad.json book.schema.json; echo "exit $?"
{'isbn': '978650000007', 'title': '', 'year': '1891', 'price': {'amount_cents': 39.9}, 'colour': 'red'}: Additional properties are not allowed ('colour' was unexpected)
{'isbn': '978650000007', 'title': '', 'year': '1891', 'price': {'amount_cents': 39.9}, 'colour': 'red'}: 'author_id' is a required property
978650000007: '978650000007' does not match '^97[89][0-9]{10}$'
: '' is too short
1891: '1891' is not of type 'integer'
{'amount_cents': 39.9}: 'currency' is a required property
39.9: 39.9 is not of type 'integer'
exit 1
```

Seven errors, one per line, and an exit status of 1. Each line starts with the part of the body the
error is about, printed as Python prints it, and then says what is wrong. They are the unknown
`colour`, the missing `author_id`, a twelve-digit ISBN, an empty title, a year sent as text, a price with no currency and a
price that is not a whole number. A correct book prints nothing and exits 0:

```
ana@api:~/shelf$ echo '{"isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price": {"amount_cents": 3990, "currency": "BRL"}}' > good.json
ana@api:~/shelf$ jsonschema -i good.json book.schema.json; echo "exit $?"
exit 0
```

## What `integer` means

One more file, the same book with the price written as `3990.0`:

```
ana@api:~/shelf$ echo '{"isbn": "9786500000078", "title": "Quincas Borba", "author_id": 1, "year": 1891, "price": {"amount_cents": 3990.0, "currency": "BRL"}}' > float.json
ana@api:~/shelf$ jsonschema -i float.json book.schema.json; echo "exit $?"
exit 0
```

It passes. JSON has one kind of number, as the first section of this lesson showed, so JSON Schema
defines `integer` as **a number with no fractional part**, and `3990.0` has none. Whether that is
acceptable is a question for the code that reads it. Here it is: the value goes into an `INTEGER`
column, and SQLite stores `3990.0` there as the whole number `3990`. A reader that kept it as a
float would need a check of its own.

`catalogue.py`, in the next section, loads this schema when it starts and runs every POST body
through it. Lesson 6 puts the same schema language inside an OpenAPI document, where it describes
every body the API sends and receives.
