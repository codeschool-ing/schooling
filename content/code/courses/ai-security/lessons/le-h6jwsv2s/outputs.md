---
title: A schema between the model and everything else
version: 1
---

The intake asks the model for a JSON object, and the prompt says which fields to include. **A prompt
is a request, and the reply is whatever the model wrote**, which is usually what was asked for and
sometimes not. Code that reads the reply has to know which case it is in before it does anything with
it, and a schema is how it knows. Tarefa's is in `data/output-schema.json`:

```
ana@lab:~/guard$ cat data/output-schema.json
{
 "type": "object",
 "additionalProperties": false,
 "required": [
  "category",
  "title",
  "summary",
  "price_suggestion_cents",
  "skills"
 ],
 "properties": {
  "category": {
   "enum": [
    "design",
    "development",
    "writing",
    "translation",
    "marketing"
   ]
  },
  "title": {
   "type": "string",
   "maxLength": 80
  },
  "summary": {
   "type": "string",
   "maxLength": 400
  },
  "price_suggestion_cents": {
   "type": "integer",
   "minimum": 5000,
   "maximum": 5000000
  },
  "skills": {
   "type": "array",
   "maxItems": 5,
   "items": {
    "type": "string",
    "maxLength": 30
   }
  },
  "links": {
   "type": "array",
   "maxItems": 3,
   "items": {
    "type": "string",
    "pattern": "^https://"
   }
  }
 }
}
```

`additionalProperties: false` refuses a field the schema does not name, `enum` closes the category,
the lengths and the item counts bound how much text reaches the screen, and the price must be an
integer inside a range. `guardlab/shapes.py` checks exactly these keywords, written out in the
standard library so that each rule can be read; in a real application a maintained JSON Schema
library does the same job.

The replies in `data/outputs.jsonl` **were written by the course**, one to pass and six to be caught
by different rules. No model produced them. Here is the one that passes, and the first that does not:

```
ana@lab:~/guard$ guard check-out data/outputs.jsonl --id out-1 --show
{"category": "design", "title": "Logo for a bakery in Recife", "summary": "A logo for a new bakery that has to work on a shop sign, on packaging and on Instagram.", "price_suggestion_cents": 150000, "skills": ["logo design", "branding", "print"], "links": ["https://help.tarefa.example/pricing/logos"]}
out-1  ok
ana@lab:~/guard$ guard check-out data/outputs.jsonl --id out-2 --show
Sure! Here is the JSON you asked for:
{"category": "design", "title": "Logo for a bakery in Recife", "summary": "A logo for a new bakery that has to work on a shop sign, on packaging and on Instagram.", "price_suggestion_cents": 150000, "skills": ["logo design", "branding", "print"], "links": ["https://help.tarefa.example/pricing/logos"]}
out-2  REJECT  not JSON: Expecting value at character 0
```

`out-2` is the JSON of `out-1` with a friendly sentence in front. The tempting fix is to search the
reply for the first `{` and parse from there, and it is a bad fix: a parser that digs JSON out of
prose accepts anything that contains an object somewhere, including a reply that says something else
entirely around it. Refuse it and ask again. Many providers also offer a structured output mode that
constrains the reply to valid JSON, or to a given schema, while it is generated, and it is worth
switching on. It settles the format, and **the values inside a well-formed reply still have to be
checked**, which the other five replies are about:

```
ana@lab:~/guard$ guard check-out data/outputs.jsonl
out-1  ok
out-2  REJECT  not JSON: Expecting value at character 0
out-3  REJECT  $.category: 'illustration' is not one of design, development, writing, translation, marketing
out-4  REJECT  $: 'internal_notes' is not allowed
out-5  REJECT  $.price_suggestion_cents: 990000 is more than twice the budget of 120000
out-6  REJECT  $.links[1]: host pay-tarefa.example is not on the allowlist
out-7  REJECT  $.summary: 607 characters, limit 400
               $.skills: 7 items, limit 5
ana@lab:~/guard$ cat data/allowed-hosts.json
["tarefa.example", "help.tarefa.example"]
```

## What each rejection would have done if it got through

- `out-3` invented the category `illustration`. The code that routes a job by category has no branch
  for it, so the job lands in whatever the default branch does, or nowhere.
- `out-4` added `internal_notes` saying the client *seems wealthy*. Without
  `additionalProperties: false`, a template that renders every field would have shown that to the
  client.
- `out-5` suggests R$ 9.900,00 for a job with a budget of R$ 1.200,00. Every field is valid on its
  own, and the schema passes it. **A schema checks each value by itself**, so a rule that relates two
  values, here the price and the budget, is written in code after the schema.
- `out-6` links to `pay-tarefa.example`, a host that looks like Tarefa's and is not. The pattern
  `^https://` passes it, because the problem is the host and not the scheme; only an allowlist of
  hosts catches it. A model can produce a link like that because it read one in the material it was
  given, or because it made one up, and either way the client would see a payment page on somebody
  else's domain.
- `out-7` has a summary of 607 characters and seven skills. Nothing in it is harmful, and it would
  break the layout of every screen that shows it.

Every rejection names the path and the rule. That message is for the developer reading the log, and,
in the next section, for the model being asked again.
