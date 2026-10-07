---
title: Two promises the API makes
version: 1
---

## Too long fails, unless you ask for the cut

Lesson 14 section 04 sent Ollama a conversation longer than its window and got an ordinary answer
from a model that had read part of it. The Responses API documents the opposite default:

```
ana@desk:~/desk$ python doc.py truncation
truncation: The truncation strategy to use for the model response.

    - `auto`: If the input to this Response exceeds the model's context window size,
      the model will truncate the response to fit the context window by dropping
      items from the beginning of the conversation.
    - `disabled` (default): If the input size will exceed the context window size
      for a model, the request will fail with a 400 error.
```

`long.py` sends four rounds of ana's worked examples, more than the 4,096 tokens Ollama gives
llama3.2:3b by default, first with OpenAI's default and then with `truncation` set to `auto`:

```python
import json
import sys

from openai import OpenAI, BadRequestError

client = OpenAI()
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")]

# four rounds of every case as a worked example: more than the 4,096 tokens Ollama gives the model
items = []
for _ in range(4):
    for c in cases[:39]:
        items += [{"role": "user", "content": c["text"]}, {"role": "assistant", "content": c["label"]}]
items.append({"role": "user", "content": cases[39]["text"]})

extra = {"truncation": sys.argv[1]} if len(sys.argv) > 1 else {}
try:
    r = client.responses.create(model="llama3.2:3b", instructions=prompt, input=items, **extra)
    print(f"{len(items)} items sent, {r.usage.input_tokens} tokens read -> {r.output_text}")
except BadRequestError as e:
    print(f"{len(items)} items sent -> {e.status_code}: {e.body['message']}")
```

```
ana@desk:~/desk$ python long.py
313 items sent, 4093 tokens read -> order-status
```

```
ana@desk:~/desk$ python long.py auto
313 items sent, 4093 tokens read -> order-status
```

**No 400.** Ollama read 4,093 tokens both times, cut the rest, and answered as if nothing had
happened, which is what it did in lesson 14 section 04 too. OpenAI's documented default is the
opposite: **too long is an error ana sees**, and the cut happens only when she asks for it with
`auto`, by dropping the oldest items. A program written against that default trusts the error to
arrive, and pointed at a server that cuts silently, it never does. The one defence that works on
both is lesson 14's: compare `input_tokens` with what was sent.

## A schema becomes an object

Lesson 5 section 09 checked extraction by parsing the model's JSON and comparing the order number.
The SDK can do the parsing, from a class:

```
ana@desk:~/desk$ python doc.py text
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
    r = client.responses.parse(model="llama3.2:3b", instructions=prompt, input=cases[cid]["text"],
                               text_format=Order)
    print(cid, repr(r.output_parsed), " expected:", cases[cid]["order"])
```

```
ana@desk:~/desk$ python parse.py
c01 Order(order='LB-20417')  expected: LB-20417
c05 Order(order=None)  expected: None
```

What went over the wire was the class, turned into a JSON Schema with `strict` set:

```
ana@desk:~/desk$ python relay.py show --body | python -c "import json, sys; print(json.dumps(json.load(sys.stdin)[\"text\"], indent=2))"
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
`S` in the sheet's flags. Ollama accepted the schema and both replies parsed;
whether it constrained the model or the model simply complied, two replies cannot tell. Neither
promise covers the value: a well-formed `{"order": "LB-20471"}` for an
e-mail about `LB-20417` passes both, and only lesson 5's comparison with the expected answer
catches it.
