---
title: A schema says what a valid reply is
version: 2
---

Lesson 18 stopped at one question: does the reply parse? That is necessary and far from enough. A
reply can be perfectly good JSON with a category nobody listed, a boolean written as the word
`"no"`, and the field your program needs most left out. **A parser checks the syntax; a schema
checks the shape.**

A **JSON Schema** is a JSON document that describes the objects you will accept: which fields, of
which types, with which values, and which of them are required. It is a published standard, and
there are libraries that check data against it in every common language. `validate`, from lesson
15, uses Python's `jsonschema` library.

## A schema for triaging complaints

Café Aurora wants each complaint sorted before a person reads it: what kind it is, whether a refund
is due and how much, and a one-line summary short enough for the manager's list. This is the
schema:

```
ana@lab:~/pe$ cat schema.json
{
  "type": "object",
  "properties": {
    "category": {"enum": ["wrong_item", "cold_or_late", "allergen", "billing", "other"]},
    "refund": {"type": "boolean"},
    "refund_amount": {"type": "number", "minimum": 0},
    "summary": {"type": "string", "maxLength": 80}
  },
  "required": ["category", "refund", "summary"],
  "additionalProperties": false
}
```

Read it from the top. The whole reply is an `object`. Its `category` is one of five words, and the
list is the whole of what is allowed: `enum` means exactly these. `refund` is a boolean, `true` or
`false`. `refund_amount` is a number no lower than zero. `summary` is a string of at most 80
characters. Three fields are `required`, and **`additionalProperties: false` refuses any field the
schema did not name**.

Every one of those lines is a decision about the program that uses the reply. The categories are
the five queues the café actually has. The 80 characters are what fits on one line of the
manager's list. `refund_amount` is optional, because a complaint with no refund has no amount.

## A valid reply

The three replies in this section were written by the course, each to show one thing the
validator says. Save the schema as `~/pe/schema.json`; the next two sections use it too.

```
ana@lab:~/pe$ cat triage/good.json
{"category": "cold_or_late", "refund": false, "summary": "Waited fifteen minutes for a tea at noon; staff were kind."}
ana@lab:~/pe$ validate schema.json triage/good.json; echo "exit $?"
valid
exit 0
```

`valid`, and exit status `0`. The program can now read `category` and know it is one of five words,
and read `refund` and know it is a boolean.

## Two invalid ones, and what the validator says

```
ana@lab:~/pe$ cat triage/bad-1.json
{"category": "slow service", "refund": "no", "summary": "The customer waited fifteen minutes for a tea at noon, which is too long, although the staff were kind about it."}
ana@lab:~/pe$ validate schema.json triage/bad-1.json; echo "exit $?"
category: 'slow service' is not one of ['wrong_item', 'cold_or_late', 'allergen', 'billing', 'other']
refund: 'no' is not of type 'boolean'
summary: 'The customer waited fifteen minutes for a tea at noon, which is too long, although the staff were kind about it.' is too long
3 problems
exit 1
```

Three problems, each on its own line, **each starting with the path to the field it is about**.
Compare that with lesson 18, where a parser stopped at the first problem and named a line and a
column. A validator walks the whole object and reports everything, because it has already parsed
it. The messages are specific enough to act on: `'slow service'` is not in the list, `'no'` is a
string where a boolean belongs, and the summary is too long.

```
ana@lab:~/pe$ cat triage/bad-2.json
{"category": "cold_or_late", "refund": false, "mood": "annoyed"}
ana@lab:~/pe$ validate schema.json triage/bad-2.json; echo "exit $?"
(top level): 'summary' is a required property
(top level): Additional properties are not allowed ('mood' was unexpected)
2 problems
exit 1
```

`(top level)` is the path for a problem with the object itself rather than one field in it. The
reply left out `summary`, which is required, and added `mood`, which the schema never named. Without
`additionalProperties: false` the second line would not appear, and a program would carry an
unexpected field along without anybody deciding that it should.

## Where the schema goes

The schema is written once and used twice. **It goes in the prompt**, or beside it, so the model
knows the shape it is asked for; that replaces the prose field list of lesson 18 with something
exact. **And it goes in the program**, which checks every reply against the same document. A
change to the categories is then one edit, and the prompt and the check cannot drift apart.

A schema cannot say everything. It checks types, allowed values, lengths, ranges and presence. It
cannot check that the summary describes the complaint, or that the refund is the right amount for
it. Those are the subject of this lesson's last reading section.
