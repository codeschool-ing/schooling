---
title: Answers your code can read
version: 2
---

Function calling gets JSON out of a model for a function. The same need appears without any
function: **a reply that a program, not a person, reads next**. This section turns a customer's
email into a ticket the support queue can sort, with a schema saying what a ticket is.

## The email and the ticket

```
Hello, I got order 1042 last week. I'd like to return one of the two mugs:
it's unused and still in its box. How do I do that? Thanks, Marta
```

The queue needs four fields, and the schema says which values each may take:

```python
TICKET = {
    "type": "object",
    "properties": {
        "order_id": {"type": ["string", "null"], "pattern": "^[0-9]{4}$"},
        "category": {"enum": ["return", "delivery", "payment", "warranty", "other"]},
        "summary": {"type": "string", "maxLength": 120},
        "urgent": {"type": "boolean"},
    },
    "required": ["order_id", "category", "summary", "urgent"],
    "additionalProperties": False,
}
```

**`order_id` may be `null`**, and that is a decision. An email without an order number is normal,
and a schema that demanded one would push the model to invent one.

## Asking, then checking

```schooling-example
{
  "language": "python",
  "file": "extract.py",
  "parts": [
    {
      "code": "\"\"\"Turn a customer's email into a ticket the support queue can sort, or say it could not.\"\"\"\nimport json\nimport sys\nfrom pathlib import Path\n\nimport anthropic\nfrom jsonschema import Draft202012Validator\n\n"
    },
    {
      "code": "TICKET = {\n    \"type\": \"object\",\n    \"properties\": {\n        \"order_id\": {\"type\": [\"string\", \"null\"], \"pattern\": \"^[0-9]{4}$\"},\n        \"category\": {\"enum\": [\"return\", \"delivery\", \"payment\", \"warranty\", \"other\"]},\n        \"summary\": {\"type\": \"string\", \"maxLength\": 120},\n        \"urgent\": {\"type\": \"boolean\"},\n    },\n    \"required\": [\"order_id\", \"category\", \"summary\", \"urgent\"],\n    \"additionalProperties\": False,\n}\nSYSTEM = (\"Extract the ticket from the customer's email. Reply with one JSON object and \"\n          \"nothing else, matching this JSON Schema:\\n\" + json.dumps(TICKET))\nmodel = anthropic.Anthropic()\n\n\n",
      "note": "**The schema is data, and the prompt quotes it**, so the model reads the same rules the validator applies."
    },
    {
      "code": "def problems(text):\n    try:\n        ticket = json.loads(text)\n    except json.JSONDecodeError as e:\n        return None, [f\"not JSON: {e.msg}\"]\n    found = [f\"{'.'.join(map(str, e.path)) or '(top)'}: {e.message}\"\n             for e in Draft202012Validator(TICKET).iter_errors(ticket)]\n    return ticket, found\n\n\n",
      "note": "**Two kinds of failure, one list.** Text that is not JSON and JSON that breaks the schema both come back as reasons a person, or a model, can read."
    },
    {
      "code": "def extract(email, attempts=2):\n    messages = [{\"role\": \"user\", \"content\": email}]\n    for attempt in range(1, attempts + 1):\n        r = model.messages.create(model=\"llama3.2:3b\", max_tokens=300, system=SYSTEM, messages=messages, extra_body={\"temperature\": 0})\n        text = r.content[0].text\n        ticket, found = problems(text)\n        if not found:\n            return ticket\n        print(f\"attempt {attempt}: {'; '.join(found)}\", file=sys.stderr)\n        messages += [\n            {\"role\": \"assistant\", \"content\": text},\n            {\"role\": \"user\", \"content\": \"That reply is not valid: \" + \"; \".join(found)\n                                        + \". Reply again with the corrected JSON only.\"},\n        ]\n    return None\n\n\n",
      "note": "**On a failure the reasons go back to the model**, after its own reply, and it gets one more try."
    },
    {
      "code": "if __name__ == \"__main__\":\n    ticket = extract(Path(sys.argv[1]).read_text())\n    print(json.dumps(ticket) if ticket else \"no valid ticket; this email goes to a person\")\n",
      "note": "**Out of tries is an answer too**: `None`, and the email goes to a person."
    }
  ]
}
```

```
ana@dev:~/shop$ python extract.py data/emails/1.txt
attempt 1: not JSON: Expecting ',' delimiter
{"order_id": "1042", "category": "return", "summary": "Return one of two mugs", "urgent": false}
```

**The first reply was not JSON**, and the line on `stderr` says where the parser gave up. The reason
went back to the model, the second reply parsed and passed, and the program printed a ticket. Lesson
8 section 07 looks at that loop on the second email.

## Asking the provider to keep the shape

Providers offer a stronger version: **constrained decoding**, where the model can only produce tokens
that keep the output inside a schema. In the Anthropic SDK it is `output_config` with a `format`;
OpenAI's is `response_format` with a JSON schema. Through Ollama's Anthropic endpoint, the first is
not there:

```
ana@dev:~/shop$ python -c 'import anthropic; r = anthropic.Anthropic().messages.create(model="llama3.2:3b", max_tokens=60, messages=[{"role": "user", "content": "Name a colour."}], output_config={"format": {"type": "json_schema", "schema": {"type": "object", "properties": {"colour": {"type": "string"}}, "required": ["colour"]}}}); print(repr(r.content[0].text))'
'Blue.'
```

**`Blue.`**, which is not an object with a `colour`. Ollama's Anthropic endpoint accepted the field
and did nothing with it, without an error, which is the worst way for a constraint to be missing:
code that relied on it would parse the reply and fail somewhere else. Its OpenAI endpoint does
honour `response_format`, so `strict.py` asks through that one, with the same schema and the same
check:

```schooling-example
{
  "language": "python",
  "file": "strict.py",
  "parts": [
    {
      "code": "\"\"\"The same ticket, with the schema enforced by Ollama while the model writes it.\"\"\"\nimport json\nimport sys\nfrom pathlib import Path\n\n"
    },
    {
      "code": "import openai\n\nfrom extract import TICKET, problems\n\n",
      "note": "**The schema and the check are `extract.py`'s**, imported rather than copied."
    },
    {
      "code": "client = openai.OpenAI()\nemail = Path(sys.argv[1]).read_text()\nr = client.chat.completions.create(\n    model=\"llama3.2:3b\", temperature=0,\n    messages=[{\"role\": \"user\", \"content\": \"Extract the ticket from the customer's email.\\n\\n\" + email}],\n    response_format={\"type\": \"json_schema\", \"json_schema\": {\"name\": \"ticket\", \"schema\": TICKET, \"strict\": True}},\n)\n",
      "note": "**`response_format` with a JSON schema**, through the OpenAI SDK, which Ollama's compatible endpoint reads: the model can only write tokens that keep the reply inside the schema."
    },
    {
      "code": "text = r.choices[0].message.content\nticket, found = problems(text)\nprint(text)\nprint(\"schema:\", \"; \".join(found) if found else \"every field valid\")\n",
      "note": "**And the same check runs anyway**, on a reply that cannot fail it, which is the point the next lines make."
    }
  ]
}
```

```
ana@dev:~/shop$ python strict.py data/emails/1.txt
{
  "order_id": "1042",
  "category": "return",
  "summary": "Return one of the two mugs",
  "urgent": false
}
schema: every field valid
ana@dev:~/shop$ python strict.py data/emails/2.txt
{"order_id": "1043", "category": "delivery", "summary": "Missing update on tracking", "urgent": true}
schema: every field valid
```

**Both valid, on the first try**, and the first one spread over several lines, which JSON allows and
the check does not mind. That is what the constraint buys: the field names, the types, the `enum`
and the pattern of `order_id` hold because the model could not write anything else.

What it does not buy is the right values. `"summary": "Missing update on tracking"` is a fair
reading of João's email; while this lesson was being prepared, the same model, asked the same way
with a slightly different instruction, filed the same email under `"return"`, a valid category and
the wrong one. **Keep the check anyway**, and keep it honest about what it checks: the validator
holds the shape whatever the provider did, and only a person or a rule in code can hold the
meaning.
