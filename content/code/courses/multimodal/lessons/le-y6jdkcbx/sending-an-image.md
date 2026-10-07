---
title: A message with a picture in it
version: 2
---

In OpenAI's APIs a picture is **one part of a user message**, beside the text that asks about it. The model reads both together. In Chat Completions, the part has the type `image_url`:

`vision.py`, the same request lesson 2's `ask.py` made, with the token counts printed:

```python
"""Send one picture and one question to a vision model, through Chat Completions."""
import base64
import sys

from openai import OpenAI

path, question = sys.argv[1], sys.argv[2]
kind = "png" if path.endswith(".png") else "jpeg"
data = base64.b64encode(open(path, "rb").read()).decode()
client = OpenAI()
reply = client.chat.completions.create(
    model="qwen2.5vl:3b", temperature=0, seed=1,
    messages=[{"role": "user", "content": [
        {"type": "text", "text": question},
        {"type": "image_url", "image_url": {"url": f"data:image/{kind};base64,{data}"}},
    ]}],
)
print(reply.choices[0].message.content)
print(f"[{reply.usage.prompt_tokens} tokens in, {reply.usage.completion_tokens} out]")
```

```
ana@lab:~/mm$ python vision.py media/cover-b39.png "Describe this cover for a blind customer."
The cover of the book "Dom Casmurro" by Machado de Assis features a minimalist design with a dark blue background. The title "DOM CASMURRO" is prominently displayed in large, white capital letters at the top of the cover. Below the title, the author's name, "Machado de Assis," is written in smaller white capital letters. The most striking element is the large, white circle located above the title, which adds a sense of balance and visual interest to the design. At the bottom of the cover, the publisher's name, "Marginalia Classics," is written in small white capital letters. The overall design is clean and modern, making it accessible to blind customers who rely on visual cues to identify books.
[1109 tokens in, 156 out]
```

**The reply is qwen2.5vl:3b's**, and it is worth reading the way a blind customer would hear it. The moon is there this time, as *a large, white circle*; the house with its two lit windows, the largest shape on the cover, is not mentioned at all. The colours are confidently wrong again, as in lesson 2, and the last sentence calls the design *accessible to blind customers who rely on visual cues*, which describes nobody. A description for a person who cannot see the picture has rules of its own, and lesson 14 is about them.

The last line is what the request cost: **1,109 tokens in**, nearly all of them the picture, and 156 out. Those are Ollama's counts for this model. How a provider turns a picture into tokens is one of its own rules, and the next section is about OpenAI's.

## Two ways to hand over the picture

**A data URL**, as above: the file's bytes encoded in base64, inside the request. Nothing has to be published anywhere, which is right for a customer's photo or a supplier's invoice. The cost is size:

```
ana@lab:~/mm$ python -c "import base64; raw = open(\"media/invoice-0931.png\", \"rb\").read(); print(len(raw), len(base64.b64encode(raw)), round(len(base64.b64encode(raw)) / len(raw), 3))"
87530 116708 1.333
```

The 87,530-byte invoice becomes 116,708 characters, **a third larger**, because base64 spends four characters on every three bytes.

**A URL the provider fetches.** The request stays small and the provider downloads the picture. That only works if the provider can reach the URL, which means the picture is public, or behind a signed link that expires. Here is the Responses API, OpenAI's newer interface, trying the cover first as a URL and then as data:

`respond.py`:

```python
"""The same question through the Responses API: the picture given as a URL, then as data."""
import base64

from openai import BadRequestError, OpenAI

client = OpenAI()
data = "data:image/png;base64," + base64.b64encode(open("media/cover-b39.png", "rb").read()).decode()
for image in ("http://localhost:8000/media/cover-b39.png", data):
    try:
        response = client.responses.create(model="qwen2.5vl:3b", temperature=0, input=[{"role": "user", "content": [
            {"type": "input_text", "text": "List every piece of text on the cover, exactly as written."},
            {"type": "input_image", "image_url": image},
        ]}])
        print(f"{image[:30]}... -> {response.output_text!r}")
        print(f"[{response.usage.input_tokens} tokens in, {response.usage.output_tokens} out]")
    except BadRequestError as e:
        print(f"{image} -> {e.status_code} {e.message}")
```

```
ana@lab:~/mm$ python respond.py
http://localhost:8000/media/cover-b39.png -> 400 Error code: 400 - {'error': {'message': 'image URLs are not currently supported, please use base64 encoded data instead', 'type': 'invalid_request_error', 'param': None, 'code': None}}
data:image/png;base64,iVBORw0K... -> 'DOM CASMURRO\nMachado de Assis\nMarginalia Classics'
[1114 tokens in, 18 out]
```

**Ollama refused the URL** before doing anything with it: *image URLs are not currently supported, please use base64 encoded data instead*. Nothing was listening at that address, and nothing had to be, which is the useful part: whether a provider fetches a URL at all is one of its rules, and OpenAI's does where Ollama's does not. The same picture as data came back as its three lines of text, exactly.

In the Responses API the parts are `input_text` and `input_image`, and the image is a plain string, either a URL or a data URL. The picture cost 1,114 tokens here against 1,109 through Chat Completions: the same picture, with a different question beside it. How a picture is delivered changes the request's size, not what the model is charged for reading it.

The accepted formats are the common ones (PNG, JPEG, WEBP and non-animated GIF). Anything else is converted first, by Pillow or ffmpeg, which is also the moment to resize it (section 03).
