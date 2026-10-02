---
title: Answers your code can read
version: 1
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
      "code": "def extract(email, attempts=2):\n    messages = [{\"role\": \"user\", \"content\": email}]\n    for attempt in range(1, attempts + 1):\n        r = model.messages.create(model=\"scripted-1\", max_tokens=300, system=SYSTEM, messages=messages)\n        text = r.content[0].text\n        ticket, found = problems(text)\n        if not found:\n            return ticket\n        print(f\"attempt {attempt}: {'; '.join(found)}\", file=sys.stderr)\n        messages += [\n            {\"role\": \"assistant\", \"content\": text},\n            {\"role\": \"user\", \"content\": \"That reply is not valid: \" + \"; \".join(found)\n                                        + \". Reply again with the corrected JSON only.\"},\n        ]\n    return None\n\n\n",
      "note": "**On a failure the reasons go back to the model**, after its own reply, and it gets one more try."
    },
    {
      "code": "ticket = extract(Path(sys.argv[1]).read_text())\nprint(json.dumps(ticket) if ticket else \"no valid ticket; this email goes to a person\")",
      "note": "**Out of tries is an answer too**: `None`, and the email goes to a person."
    }
  ]
}
```

```
ana@dev:~/shop$ python extract.py data/emails/1.txt
{"order_id": "1042", "category": "return", "summary": "Wants to return one of two mugs, unused.", "urgent": false}
```

**The reply parsed and passed**, so the program printed a ticket. The JSON was written by the
course as `scripted-1`'s reply; the parsing and the validation are what your code would run
against any model.

## Asking the provider to keep the shape

Providers offer a stronger version: **constrained decoding**, where the model can only produce
tokens that keep the output inside a schema. In the Anthropic SDK this course installs it is
`output_config` with a `format`, and a tool can say `strict`; OpenAI's is `response_format` with a
JSON schema. The SDK confirms the fields exist:

```
ana@dev:~/shop$ python -c 'import anthropic.types as t; print(sorted(t.OutputConfigParam.__annotations__)); print(sorted(t.JSONOutputFormatParam.__annotations__)); print("strict" in t.ToolParam.__annotations__)'
['effort', 'format']
['schema', 'type']
True
ana@dev:~/shop$ python -c 'import anthropic; anthropic.Anthropic().messages.create(model="scripted-1", max_tokens=50, messages=[{"role": "user", "content": "hi"}], output_config={"format": {"type": "json_schema", "schema": {"type": "object"}}})' 2>&1 | tail -n 1
anthropic.BadRequestError: Error code: 400 - {'type': 'error', 'error': {'type': 'invalid_request_error', 'message': 'output_config: labllm does not constrain its output; validate the reply yourself'}, 'request_id': 'req_lab_0011'}
```

**The lab refuses it, on purpose.** labllm has no decoder to constrain, so it says so instead of
accepting the field and ignoring it, which would let the lesson pretend.

Where a real provider supports it, use it, and **keep the check anyway**. Constrained decoding
fixes the shape: the field names, the types, the enum. It does not make `order_id` the right
order, and providers document which schema keywords they honour, which is not always all of them.
The validator is the line that holds whatever the provider did.
