---
title: Contents, parts and a role called model
version: 1
---

Lesson 7 chose among Gemini models and read where they are sold. This lesson is the API they
answer through, called from Google's own library, `google-genai`. Google's API answers from the
machine this course was recorded on, but only with a key, and a key is an account a course cannot
hand out. Ollama does not speak this API. So each program here runs twice: once through the relay
from lesson 9 section 03, to read what the library sends, and once straight to Google, to read
what Google answers without a key. If you have a key from Google AI Studio, put it in
`GOOGLE_API_KEY` and the second run answers with a label.

`gemini_sort.py` sorts one of ana's cases with `gemini-3.5-flash`, a model from lesson 7's table:

```python
import json

from google import genai
from google.genai import errors, types

client = genai.Client()
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

try:
    r = client.models.generate_content(
        model="gemini-3.5-flash", contents=case["text"],
        config=types.GenerateContentConfig(system_instruction=prompt, max_output_tokens=16, temperature=0))
    print(repr(r.text), r.candidates[0].finish_reason)
    print(r.usage_metadata.prompt_token_count, "in,", r.usage_metadata.candidates_token_count, "out")
except errors.APIError as e:
    print(e.code, e.status, e.message)
```

With the relay running in a second terminal, send the library to it. `GOOGLE_GEMINI_BASE_URL` is the
address it reads, and `genai.Client()` refuses to start without some key, so a placeholder goes in
`GOOGLE_API_KEY`:

```
ana@desk:~/desk$ export GOOGLE_GEMINI_BASE_URL=http://127.0.0.1:8500 GOOGLE_API_KEY=ollama
ana@desk:~/desk$ python gemini_sort.py
Direct use of automatic function calling (AFC) in Models.generate_content is not recommended. Instead, we recommend to use AFC in Chat.send_message. Similarly, direct use of AFC in Models.generate_content_stream is not recommended. Instead, we recommend to use AFC in Chat.send_message_stream.
404 Not Found 404 page not found
```

The first line is the library's own, about automatic function calling, which this program does not
use; it is printed on every `generate_content` call and can be ignored here. The second is Ollama
saying it has no such address. What went over the wire:

```
ana@desk:~/desk$ python relay.py show --headers x-goog-api-key,user-agent
POST /v1beta/models/gemini-3.5-flash:generateContent
x-goog-api-key: ollama…
user-agent: google-genai-sdk/2.28.0 gl-python/3.13.16

{
  "contents": [
    {
      "parts": [
        {
          "text": "Do you have a physical shop I can visit in Curitiba?"
        }
      ],
      "role": "user"
    }
  ],
  "systemInstruction": {
    "parts": [
      {
        "text": "You sort the e-mail of Lantern Books, an online bookshop.\nAnswer with exactly one label and nothing else:\norder-status, refund, address-change, product-question, other.\n"
      }
    ],
    "role": "user"
  },
  "generationConfig": {
    "temperature": 0.0,
    "maxOutputTokens": 16
  }
}
```

Four things to read in it:

- **The model is in the path**, `/v1beta/models/gemini-3.5-flash:generateContent`, not in the body.
- **`contents` is a list of turns, and each turn a list of `parts`.** A part can be text, an image
  or a file, which is how one request carries the inputs the `multimodal` course works with.
- **The system prompt is `systemInstruction`**, beside the contents rather than among them, and
  the settings are in `generationConfig`.
- **The library writes camelCase.** The program says `max_output_tokens` and the wire says
  `maxOutputTokens`: the Python names are the library's, and a request written by hand, or read in
  a log, uses the API's.

A reply comes back as one more turn, and its role is not the `assistant` of the other APIs. The
library's own description of the field says so, and `field.py` prints it for any field:

```python
import inspect
import sys

from google.genai import types

# what the installed library says about one of its own fields: field.py Class.field
cls, name = sys.argv[1].split(".")
print(inspect.cleandoc(getattr(types, cls).model_fields[name].description))
```

```
ana@desk:~/desk$ python field.py Content.role
Optional. The producer of the content. Must be either 'user' or 'model'. If not set, the service will default to 'user'.
```

Now the same program, straight to Google. Unset the address and the library goes to its default,
generativelanguage.googleapis.com:

```
ana@desk:~/desk$ unset GOOGLE_GEMINI_BASE_URL
ana@desk:~/desk$ python gemini_sort.py
Direct use of automatic function calling (AFC) in Models.generate_content is not recommended. Instead, we recommend to use AFC in Chat.send_message. Similarly, direct use of AFC in Models.generate_content_stream is not recommended. Instead, we recommend to use AFC in Chat.send_message_stream.
400 INVALID_ARGUMENT API key not valid. Please pass a valid API key.
```

**Google read the request and refused the key**, with a 400 and a status word of its own,
`INVALID_ARGUMENT`. The key travels in `x-goog-api-key`, the third header name this course has
seen for the same job, after Anthropic's `x-api-key` and everybody else's `Authorization: Bearer`.
