---
title: Two promises the API makes
version: 1
---

## Too long fails, unless you ask for the cut

Lesson 14 section 04 sent Ollama a conversation longer than its window and got an ordinary answer
from a model that had read part of it. The Responses API documents the opposite default:

```
ana@desk:~/desk$ python lab/doc.py truncation
truncation: The truncation strategy to use for the model response.

    - `auto`: If the input to this Response exceeds the model's context window size,
      the model will truncate the response to fit the context window by dropping
      items from the beginning of the conversation.
    - `disabled` (default): If the input size will exceed the context window size
      for a model, the request will fail with a 400 error.
```

`lab/long.py` sends thirty rounds of ana's worked examples, more than `standin-small`'s 32,768-token
window, first with the default and then with `truncation` set to `auto`:

```python
import json
import sys

from openai import OpenAI, BadRequestError

client = OpenAI()
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")]

# thirty rounds of every case as a worked example: far more than standin-small's window
items = []
for _ in range(30):
    for c in cases[:39]:
        items += [{"role": "user", "content": c["text"]}, {"role": "assistant", "content": c["label"]}]
items.append({"role": "user", "content": cases[39]["text"]})

extra = {"truncation": sys.argv[1]} if len(sys.argv) > 1 else {}
try:
    r = client.responses.create(model="standin-small", instructions=prompt, input=items, **extra)
    print(f"{len(items)} items sent, {r.usage.input_tokens} tokens read -> {r.output_text}")
except BadRequestError as e:
    print(f"{len(items)} items sent -> {e.status_code}: {e.body['message']}")
```

```
ana@desk:~/desk$ python lab/long.py
2341 items sent -> 400: prompt is too long: 31980 tokens + 1024 max tokens > 32768 maximum
```

```
ana@desk:~/desk$ python lab/long.py auto
2341 items sent, 31737 tokens read -> order-status
```

The wording of the 400 is the stand-in's; the behaviour is the one documented. **By default, too
long is an error ana sees**, and the cut happens only when she asks for it, by dropping the oldest
items. The window counts the room for the answer too, which is why `auto` stopped at 31,737 tokens:
the stand-in keeps 1,024 for output, its default when `max_output_tokens` is not set.

## A schema becomes an object

Lesson 5 section 09 checked extraction by parsing the model's JSON and comparing the order number.
The SDK can do the parsing, from a class:

```
ana@desk:~/desk$ python lab/doc.py text
text: Configuration options for a text response from the model. Can be plain text or
    structured JSON data. Learn more:

    - [Text inputs and outputs](https://developers.openai.com/api/docs/guides/text)
    - [Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs)
```

```python
import json

from openai import OpenAI
from pydantic import BaseModel


class Order(BaseModel):
    order: str | None


client = OpenAI()
prompt = open("prompts/extract.txt").read()
cases = {c["id"]: c for c in map(json.loads, open("cases/triage.jsonl"))}

for cid in ("c01", "c05"):
    r = client.responses.parse(model="standin-small", instructions=prompt, input=cases[cid]["text"],
                               text_format=Order)
    print(cid, repr(r.output_parsed), " expected:", cases[cid]["order"])
```

```
ana@desk:~/desk$ python lab/parse.py
c01 Order(order='LB-20417')  expected: LB-20417
c05 Order(order=None)  expected: None
```

What went over the wire was the class, turned into a JSON Schema with `strict` set:

```
ana@desk:~/desk$ wire --body | python -c "import json, sys; print(json.dumps(json.load(sys.stdin)[\"text\"], indent=2))"
{
  "format": {
    "type": "json_schema",
    "strict": true,
    "name": "Order",
    "schema": {
      "properties": {
        "order": {
          "anyOf": [
            {
              "type": "string"
            },
            {
              "type": "null"
            }
          ],
          "title": "Order"
        }
      },
      "required": [
        "order"
      ],
      "title": "Order",
      "type": "object",
      "additionalProperties": false
    }
  }
}
```

Two promises are in play here, and they are made by different parties. **The SDK promises the
parse**: `output_parsed` is an `Order` or the call raises. **The provider promises the schema**:
with `strict`, a model that supports structured output writes JSON that matches it, which is the
`S` in the sheet's flags. The stand-in makes no such promise; it answered from its table, which
happened to match. Neither promise covers the value: a well-formed `{"order": "LB-20471"}` for an
e-mail about `LB-20417` passes both, and only lesson 5's comparison with the expected answer
catches it.
