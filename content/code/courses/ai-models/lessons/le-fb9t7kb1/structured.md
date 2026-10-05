---
title: A class in, an object out
version: 1
---

Lesson 16 section 05 had OpenAI's library turn a class into a schema and the reply back into an
object. Google's library does the same, through the configuration. `lab/gemini_extract.py` also
counts each e-mail's tokens before sending it:

```python
import json

from google import genai
from google.genai import types
from pydantic import BaseModel


class Order(BaseModel):
    order: str | None


client = genai.Client()
prompt = open("prompts/extract.txt").read()
cases = {c["id"]: c for c in map(json.loads, open("cases/triage.jsonl"))}

for cid in ("c01", "c05"):
    text = cases[cid]["text"]
    n = client.models.count_tokens(model="standin-small", contents=text).total_tokens
    r = client.models.generate_content(
        model="standin-small", contents=text,
        config=types.GenerateContentConfig(system_instruction=prompt, temperature=0,
                                           response_mime_type="application/json", response_schema=Order))
    print(cid, f"{n} tokens counted first;", repr(r.parsed), " expected:", cases[cid]["order"])
```

```
ana@desk:~/desk$ python lab/gemini_extract.py
Direct use of automatic function calling (AFC) in Models.generate_content is not recommended. Instead, we recommend to use AFC in Chat.send_message. Similarly, direct use of AFC in Models.generate_content_stream is not recommended. Instead, we recommend to use AFC in Chat.send_message_stream.
c01 33 tokens counted first; Order(order='LB-20417')  expected: LB-20417
c05 15 tokens counted first; Order(order=None)  expected: None
```

```
ana@desk:~/desk$ wire --body | python -c "import json, sys; print(json.dumps(json.load(sys.stdin)[\"generationConfig\"], indent=2))"
{
  "temperature": 0.0,
  "responseMimeType": "application/json",
  "responseSchema": {
    "properties": {
      "order": {
        "nullable": true,
        "title": "Order",
        "type": "STRING"
      }
    },
    "required": [
      "order"
    ],
    "title": "Order",
    "type": "OBJECT"
  }
}
```

The schema on the wire is **Google's own dialect**, not the JSON Schema OpenAI received for the same
class: `"type": "STRING"` in capitals, and `"nullable": true` where lesson 16 had
`"anyOf": [{"type": "string"}, {"type": "null"}]`. The library translated one Python class into two
providers' formats, which is the work a program would otherwise do by hand, and the reason a schema
copied from one provider's documentation into another's request can be refused.

`count_tokens` asked the API, before the request, how many tokens the e-mail is. It is a separate
call, with its own round trip, and useful where the size decides something: which model to send a
long message to, or whether it fits at all. The number is the provider's own count, made with the
model's tokenizer, which no local library can promise for a closed model.

`r.parsed` is the library's work again, done on ana's side from the text that came back. The same
caveat as lesson 16 holds: the stand-in ignored the schema and answered from its table, and only
the comparison with the expected order says whether the value is right.
