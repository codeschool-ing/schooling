---
title: A message with a picture in it
version: 1
---

In OpenAI's APIs a picture is **one part of a user message**, beside the text that asks about it. The model reads both together. In Chat Completions, the part has the type `image_url`:

```python
"""Send one picture and one question to a vision model, through Chat Completions."""
import base64
import sys

from openai import OpenAI

path, question = sys.argv[1], sys.argv[2]
detail = sys.argv[3] if len(sys.argv) > 3 else "auto"
kind = "png" if path.endswith(".png") else "jpeg"
data = base64.b64encode(open(path, "rb").read()).decode()

client = OpenAI()
reply = client.chat.completions.create(
    model="lab-vision-1",
    messages=[{"role": "user", "content": [
        {"type": "text", "text": question},
        {"type": "image_url", "image_url": {"url": f"data:image/{kind};base64,{data}", "detail": detail}},
    ]}],
)
print(reply.choices[0].message.content)
print(f"[{reply.usage.prompt_tokens} tokens in, {reply.usage.completion_tokens} out]")
```

```
ana@lab:~/mm$ python look.py media/cover-b39.png "Describe this cover for a blind customer."
A book cover on a dark navy background. At the top right is a pale yellow full moon. The title, DOM CASMURRO, is set in large cream serif capitals, with Machado de Assis in smaller letters below it. Under the text is a dark rectangular shape with two gold rectangles in it, like a building with two lit windows, standing on a thin cream line. At the bottom: Marginalia Classics.
[776 tokens in, 87 out]
```

**The reply above was written by the course.** labmm's `lab-vision-1` matched the cover's SHA-256 and the words *Describe this cover* against a rule in `lab/scripted/08-vision-api.json` and returned the description written there. Everything around it is real: the SDK built the request a real endpoint would receive, and labmm counted the input by the rule a real one publishes. The reply has the shape of a good answer for a blind customer, and lesson 14 asks what such a description owes them.

## Two ways to hand over the picture

**A data URL**, as above: the file's bytes encoded in base64, inside the request. Nothing has to be published anywhere, which is right for a customer's photo or a supplier's invoice. The cost is size:

```
ana@lab:~/mm$ python -c "import base64; raw = open(\"media/invoice-0931.png\", \"rb\").read(); print(len(raw), len(base64.b64encode(raw)), round(len(base64.b64encode(raw)) / len(raw), 3))"
87530 116708 1.333
```

The 87,530-byte invoice becomes 116,708 characters, **a third larger**, because base64 spends four characters on every three bytes.

**A URL the provider fetches.** The request stays small and the provider downloads the picture. That only works if the provider can reach the URL, which means the picture is public, or behind a signed link that expires. Here is the Responses API, OpenAI's newer interface, with the cover given as a URL that labmm serves:

```python
"""The same question through the Responses API, with the picture given as a URL."""
from openai import OpenAI

client = OpenAI()
response = client.responses.create(
    model="lab-vision-1",
    input=[{"role": "user", "content": [
        {"type": "input_text", "text": "List every piece of text on the cover, exactly as written."},
        {"type": "input_image", "image_url": "http://127.0.0.1:8700/files/cover-b39.png"},
    ]}],
)
print(response.output_text)
print(f"[{response.usage.input_tokens} tokens in, {response.usage.output_tokens} out]")
```

```
ana@lab:~/mm$ python look_url.py
DOM CASMURRO
Machado de Assis
Marginalia Classics
[781 tokens in, 16 out]
ana@lab:~/mm$ tail -n 2 /var/log/labmm/requests.jsonl | python -c "import json, sys; [print(r[\"path\"], r[\"images\"], r[\"rule\"]) for r in map(json.loads, sys.stdin)]"
/v1/chat/completions [{'bytes': 19605, 'width': 600, 'height': 900, 'detail': 'auto', 'tokens': 765, 'tiles': 4, 'sha256': '88a80dab896d'}] l08-cover-describe
/v1/responses [{'bytes': 19605, 'width': 600, 'height': 900, 'detail': 'auto', 'tokens': 765, 'tiles': 4, 'sha256': '88a80dab896d'}] l08-cover-text
```

In the Responses API the parts are `input_text` and `input_image`, and the image URL is a plain string. labmm's log shows the same picture arriving both ways: 600 by 900 pixels, 19,605 bytes, and **765 tokens** each time. How a picture is delivered changes the request's size, not what the model is charged for reading it.

The accepted formats are the common ones (PNG, JPEG, WEBP and non-animated GIF). Anything else is converted first, by Pillow or ffmpeg, which is also the moment to resize it (section 03).
