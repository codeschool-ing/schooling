---
title: Contents, parts and a role called model
version: 1
---

Lesson 7 chose among Gemini models and read where they are sold. This lesson is the API they
answer through, called from Google's own library, `google-genai`. Google's API could not be reached
from the machine this course was recorded on; the lab's stand-in answers at the address the library
reads from `GOOGLE_GEMINI_BASE_URL`, and what the library sends is real.

`lab/gemini_sort.py` sorts one of ana's cases:

```python
import json

from google import genai
from google.genai import types

client = genai.Client()
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

r = client.models.generate_content(
    model="standin-small", contents=case["text"],
    config=types.GenerateContentConfig(system_instruction=prompt, max_output_tokens=16, temperature=0))
print(repr(r.text), r.candidates[0].finish_reason)
print(r.usage_metadata.prompt_token_count, "in,", r.usage_metadata.candidates_token_count, "out")
```

```
ana@desk:~/desk$ python lab/gemini_sort.py
Direct use of automatic function calling (AFC) in Models.generate_content is not recommended. Instead, we recommend to use AFC in Chat.send_message. Similarly, direct use of AFC in Models.generate_content_stream is not recommended. Instead, we recommend to use AFC in Chat.send_message_stream.
'other' FinishReason.STOP
51 in, 1 out
```

The first line is the library's own, about automatic function calling, which this program does not
use; it is printed on every `generate_content` call and can be ignored here. What went over the
wire:

```
ana@desk:~/desk$ wire --headers x-goog-api-key,user-agent
POST /v1beta/models/standin-small:generateContent
x-goog-api-key: lab-google-k…
user-agent: google-genai-sdk/2.28.0 gl-python/3.11.15

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

- **The model is in the path**, `/v1beta/models/standin-small:generateContent`, not in the body.
- **`contents` is a list of turns, and each turn a list of `parts`.** A part can be text, an image
  or a file, which is how one request carries the inputs the `multimodal` course works with. A
  reply comes back with the role `model`, where the other APIs say `assistant`.
- **The system prompt is `systemInstruction`**, beside the contents rather than among them, and
  the settings are in `generationConfig`.
- **The library writes camelCase.** The program says `max_output_tokens` and the wire says
  `maxOutputTokens`: the Python names are the library's, and a request written by hand, or read in
  a log, uses the API's.

The key travels in `x-goog-api-key`, the third header name this course has seen for the same job,
after Anthropic's `x-api-key` and everybody else's `Authorization: Bearer`.
