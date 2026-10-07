---
title: A class in, an object out
version: 1
---

Lesson 16 section 05 had OpenAI's library turn a class into a schema and the reply back into an
object. Google's library does the same, through the configuration. `gemini_extract.py` asks for
the order number in two of ana's cases, as an `Order`:

```python
import json

from google import genai
from google.genai import errors, types
from pydantic import BaseModel


class Order(BaseModel):
    order: str | None


client = genai.Client()
prompt = open("prompts/extract.txt").read()
cases = {c["id"]: c for c in map(json.loads, open("cases/triage.jsonl"))}

for cid in ("c01", "c05"):
    try:
        r = client.models.generate_content(
            model="gemini-3.5-flash", contents=cases[cid]["text"],
            config=types.GenerateContentConfig(system_instruction=prompt, temperature=0,
                                               response_mime_type="application/json", response_schema=Order))
        print(cid, repr(r.parsed), " expected:", cases[cid]["order"])
    except errors.APIError as e:
        print(cid, e.code, e.status)
```

Through the relay, as in section 02, Ollama answers both with its 404, and the request is the part
worth reading:

```
ana@desk:~/desk$ export GOOGLE_GEMINI_BASE_URL=http://127.0.0.1:8500 GOOGLE_API_KEY=ollama
ana@desk:~/desk$ python gemini_extract.py
Direct use of automatic function calling (AFC) in Models.generate_content is not recommended. Instead, we recommend to use AFC in Chat.send_message. Similarly, direct use of AFC in Models.generate_content_stream is not recommended. Instead, we recommend to use AFC in Chat.send_message_stream.
c01 404 Not Found
c05 404 Not Found
ana@desk:~/desk$ python relay.py show --body | python -c "import json, sys; print(json.dumps(json.load(sys.stdin)[\"generationConfig\"], indent=2))"
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
`"anyOf": [{"type": "string"}, {"type": "null"}]`. The library's description of the field says
where the dialect comes from, and what to do when it is not enough:

```
ana@desk:~/desk$ python field.py GenerateContentConfig.response_schema
The `Schema` object allows the definition of input and output data types.
These types can be objects, but also primitives and arrays.
Represents a select subset of an [OpenAPI 3.0 schema
object](https://spec.openapis.org/oas/v3.0.3#schema).
If set, a compatible response_mime_type must also be set.
Compatible mimetypes: `application/json`: Schema for JSON response.

If `response_schema` doesn't process your schema correctly, try using
`response_json_schema` instead.
```

A subset of OpenAPI 3.0, which is where `nullable` comes from. The library translated one Python
class into two providers' formats, which is the work a program would otherwise do by hand, and the
reason a schema copied from one provider's documentation into another's request can be refused.

`r.parsed` is the library's work again, done on ana's side from the text that comes back:

```
ana@desk:~/desk$ python field.py GenerateContentResponse.parsed
First candidate from the parsed response if response_schema is provided. Not available for streaming.
```

"The first candidate", so it has the same weakness as the text it is made from, which section 04
is about. And the same caveat as lesson 16 holds: a schema promises the shape, and only the
comparison with the expected order says whether the value is right. On this machine there was no
value at all to compare, which is a reminder of where that check has to live: in ana's harness,
run against whichever provider the desk pays for.
