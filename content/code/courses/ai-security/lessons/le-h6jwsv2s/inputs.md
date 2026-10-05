---
title: Narrowing what goes in
version: 1
---

A common picture of input handling for a model is that there is nothing to handle: the model reads
text, so whatever the user typed is passed along, and the checking happens on the reply. **Every
field that reaches a prompt is something the model will try to act on**, and the less of it there is,
and the more of it has a known shape, the less there is to go wrong. Lesson 2 shows what free text in
a prompt can do in the hands of somebody trying; this lesson is about the cheaper half, which is
deciding what is allowed in at all.

Tarefa's job intake takes a client's request and asks a model to categorise it and suggest a price.
The request is not a text box. It has four fields, and each has a rule:

```
ana@lab:~/guard$ cat data/input-rules.json
{
 "fields": {
  "title": {
   "type": "string",
   "required": true,
   "maxLength": 80
  },
  "description": {
   "type": "string",
   "required": true,
   "maxLength": 2000
  },
  "category": {
   "type": "string",
   "required": true,
   "enum": [
    "design",
    "development",
    "writing",
    "translation",
    "marketing"
   ]
  },
  "budget_cents": {
   "type": "integer",
   "required": true,
   "minimum": 5000,
   "maximum": 5000000
  }
 }
}
ana@lab:~/guard$ head -1 data/inputs.jsonl
{"id": "in-1", "title": "Logo for a bakery", "description": "We are opening a bakery in Recife and need a logo that works on the shop sign, the packaging and Instagram.", "category": "design", "budget_cents": 120000}
```

Six requests, written by the course, each breaking a different rule except the first:

```
ana@lab:~/guard$ guard check-in data/inputs.jsonl; echo "exit $?"
in-1   ok
in-2   REJECT  description: 5145 characters, limit 2000
in-3   REJECT  field 'priority' is not accepted
in-4   REJECT  category: 'photography' is not one of design, development, writing, translation, marketing
in-5   REJECT  description: U+200B zero width space x3
               description: U+202C pop directional formatting x1
               description: U+202E right-to-left override x1
in-6   REJECT  budget_cents: expected integer, got str
exit 1
```

## What each rule buys

**An allowlist of fields.** `in-3` carries a `priority` field the form never offered. A request
builder that copies every field it receives into the prompt turns any extra field into an
instruction the developer never wrote; accepting only the fields that are named closes that path at
no cost. This is the same move as lesson 22's purpose list, applied to the other direction.

**Closed lists where the answer is closed.** `category` takes one of five values. *Photography* may be a perfectly good category for Tarefa to add one day. Until then it is a value the rest of the system has no handling for, so it is refused at the door, with a message that says which values exist.

**Types, and money as integer cents.** `in-6` sends the budget as the string `"1.200,00"`, which is
how a Brazilian writes it and which a parser can read as one point two, as twelve hundred, or not at
all. The rule demands an integer number of cents, which has one reading.

**A length.** `in-2` is 5,145 characters, most of them a company history pasted from a document. Two
thousand characters is the course's choice for a job description. The limit protects the bill, since
every character is paid for as input tokens on every call, and it also bounds how much material the
model has to be distracted by.

**No invisible characters.** `in-5` reads, on most screens, like an ordinary sentence about a bakery
in Recife. It contains three zero-width spaces and a right-to-left override, which reverses how the
text after it is displayed. The model reads the characters in the order they are stored, and a person
reviewing the request sees them in the order they are drawn. **Text that reads differently to the
person and to the model** has no legitimate place in a job description, so the rule lists those
characters by code point and refuses them.

## Refusing versus cleaning

Every rule here refuses the request and says why, and the alternative, quietly fixing it, is
tempting: trim the description to 2,000 characters, drop the unknown field, strip the invisible
characters. Cleaning is right where the fix is certain and harmless, such as trimming spaces at the
ends of a title. It is wrong where it changes what the person meant without telling them. A
description cut at 2,000 characters may lose the one sentence that mattered, and a client who is
told the limit can choose what to cut.
