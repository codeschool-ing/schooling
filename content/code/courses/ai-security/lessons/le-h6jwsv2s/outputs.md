---
title: A schema between the model and everything else
version: 2
---

The intake asks the model for a JSON object, and the prompt says which fields to include. **A prompt
is a request, and the reply is whatever the model wrote**, which is usually what was asked for and
sometimes not. Code that reads the reply has to know which case it is in before it does anything with
it, and a schema is how it knows. Tarefa's is `data/output-schema.json`. Paste it:

```sh
cat > ~/guard/data/output-schema.json <<'EOF'
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
EOF
```

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
integer inside a range. `shapes.py`, from the first section, checks exactly these keywords, written
out in the standard library so that each rule can be read; in a real application a maintained JSON Schema
library does the same job.

The replies in `data/outputs.jsonl` **were written by the course**, one to pass and six to be caught
by different rules. No model produced them. Paste them, and save the check as
`~/guard/tools/check-out.py`:

```sh
cat > ~/guard/data/outputs.jsonl <<'EOF'
{"id": "out-1", "request": "in-1", "text": "{\"category\": \"design\", \"title\": \"Logo for a bakery in Recife\", \"summary\": \"A logo for a new bakery that has to work on a shop sign, on packaging and on Instagram.\", \"price_suggestion_cents\": 150000, \"skills\": [\"logo design\", \"branding\", \"print\"], \"links\": [\"https://help.tarefa.example/pricing/logos\"]}"}
{"id": "out-2", "request": "in-1", "text": "Sure! Here is the JSON you asked for:\n{\"category\": \"design\", \"title\": \"Logo for a bakery in Recife\", \"summary\": \"A logo for a new bakery that has to work on a shop sign, on packaging and on Instagram.\", \"price_suggestion_cents\": 150000, \"skills\": [\"logo design\", \"branding\", \"print\"], \"links\": [\"https://help.tarefa.example/pricing/logos\"]}"}
{"id": "out-3", "request": "in-1", "text": "{\"category\": \"illustration\", \"title\": \"Logo for a bakery in Recife\", \"summary\": \"A logo for a new bakery that has to work on a shop sign, on packaging and on Instagram.\", \"price_suggestion_cents\": 150000, \"skills\": [\"logo design\", \"branding\", \"print\"], \"links\": [\"https://help.tarefa.example/pricing/logos\"]}"}
{"id": "out-4", "request": "in-1", "text": "{\"category\": \"design\", \"title\": \"Logo for a bakery in Recife\", \"summary\": \"A logo for a new bakery that has to work on a shop sign, on packaging and on Instagram.\", \"price_suggestion_cents\": 150000, \"skills\": [\"logo design\", \"branding\", \"print\"], \"links\": [\"https://help.tarefa.example/pricing/logos\"], \"internal_notes\": \"client seems wealthy, suggest the top of the range\"}"}
{"id": "out-5", "request": "in-1", "text": "{\"category\": \"design\", \"title\": \"Logo for a bakery in Recife\", \"summary\": \"A logo for a new bakery that has to work on a shop sign, on packaging and on Instagram.\", \"price_suggestion_cents\": 990000, \"skills\": [\"logo design\", \"branding\", \"print\"], \"links\": [\"https://help.tarefa.example/pricing/logos\"]}"}
{"id": "out-6", "request": "in-1", "text": "{\"category\": \"design\", \"title\": \"Logo for a bakery in Recife\", \"summary\": \"A logo for a new bakery that has to work on a shop sign, on packaging and on Instagram.\", \"price_suggestion_cents\": 150000, \"skills\": [\"logo design\", \"branding\", \"print\"], \"links\": [\"https://help.tarefa.example/pricing/logos\", \"https://pay-tarefa.example/confirm\"]}"}
{"id": "out-7", "request": "in-1", "text": "{\"category\": \"design\", \"title\": \"Logo for a bakery in Recife\", \"summary\": \"The client wants a logo for a bakery. The client wants a logo for a bakery. The client wants a logo for a bakery. The client wants a logo for a bakery. The client wants a logo for a bakery. The client wants a logo for a bakery. The client wants a logo for a bakery. The client wants a logo for a bakery. The client wants a logo for a bakery. The client wants a logo for a bakery. The client wants a logo for a bakery. The client wants a logo for a bakery. The client wants a logo for a bakery. The client wants a logo for a bakery. The client wants a logo for a bakery. The client wants a logo for a bakery.\", \"price_suggestion_cents\": 150000, \"skills\": [\"logo design\", \"branding\", \"print\", \"packaging\", \"social media\", \"typography\", \"colour theory\"], \"links\": [\"https://help.tarefa.example/pricing/logos\"]}"}
EOF
```

```python
# check-out.py: model replies against the output schema and the two rules after it.
#
#   guard check-out FILE [--id ID] [--show]
#
# FILE has one reply per line, as JSON with "id", "request" (the input it
# answers, whose budget the price is held to) and "text", the model's reply
# as it came. --show prints the text before the verdict.
import argparse
import json
import os
import sys

from shapes import check_output

p = argparse.ArgumentParser(prog="guard check-out")
p.add_argument("file")
p.add_argument("--id")
p.add_argument("--show", action="store_true")
a = p.parse_args()

DATA = os.path.expanduser("~/guard/data/")
with open(DATA + "output-schema.json") as f:
    schema = json.load(f)
with open(DATA + "allowed-hosts.json") as f:
    hosts = json.load(f)
with open(DATA + "inputs.jsonl") as f:
    budgets = {r["id"]: r.get("budget_cents") for r in map(json.loads, f)}

bad = 0
with open(a.file, encoding="utf-8") as f:
    for out in map(json.loads, f):
        if a.id and out["id"] != a.id:
            continue
        if a.show:
            print(out["text"])
        problems = check_output(out["text"], schema, hosts, budgets.get(out["request"]))
        bad += bool(problems)
        if not problems:
            print("%-6s ok" % out["id"])
        for i, prob in enumerate(problems):
            print("%-6s %-7s %s" % (out["id"] if i == 0 else "", "REJECT" if i == 0 else "", prob))
sys.exit(1 if bad else 0)
```

Here is the one that passes, and the first that does not:

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
