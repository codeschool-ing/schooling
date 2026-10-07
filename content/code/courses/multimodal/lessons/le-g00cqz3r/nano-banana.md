---
title: Gemini's image model, called Nano Banana
version: 1
---

**Nano Banana** is the nickname that stuck to Google's Gemini 2.5 Flash Image, the image model it released in 2025, and later to its successors. It is not a separate API. It is a Gemini model called through the same `generate_content` as text, asked to answer with an image as well:

```python
"""Gemini's image model: words in, and a picture and words out, in one call."""
from google import genai
from google.genai import types
from PIL import Image

client = genai.Client(api_key="none", http_options={"base_url": "http://localhost:8800"})   # images_server.py
reply = client.models.generate_content(
    model="gemini-2.5-flash-image",
    contents=["A poster for a second-hand book fair in a library courtyard, warm afternoon light"],
    config=types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"]),
)
for part in reply.candidates[0].content.parts:
    if part.inline_data:
        open("poster.png", "wb").write(part.inline_data.data)
        print("image:", part.inline_data.mime_type, len(part.inline_data.data), "bytes", Image.open("poster.png").size)
    elif part.text:
        print("text: ", part.text)
u = reply.usage_metadata
print(f"tokens in {u.prompt_token_count}, out {u.candidates_token_count}")
```

```
@@nano@@
```

A reply comes back as a list of **parts**: here one part of text and one of image, the image as raw bytes with a MIME type. Both are labmm's: the picture is a card, and the text is labmm saying it has no rule for this prompt, which is true. A real Gemini reply often carries a sentence about what it drew beside the picture, and a program should expect either part, both, or a text part alone when the model declines to draw.

The token counts are labmm's, by Google's published rules: the prompt cost 16 tokens of text, and the reply 1,314, of which **1,290 are the picture**. Google prices image output per token, and 1,290 tokens at the sheet's 30 dollars per million is the same 0.039 dollars per picture the sheet also lists (lesson 3 read that price).

## Editing without a mask

The difference from OpenAI's API that matters most in practice is how an edit is described. Gemini takes **the picture and a sentence**, and the sentence says what to change:

```python
"""The same model with a picture in the request: an edit described in words, with no mask."""
from google import genai
from google.genai import types
from PIL import Image

client = genai.Client(api_key="none", http_options={"base_url": "http://localhost:8800"})   # images_server.py
reply = client.models.generate_content(
    model="gemini-2.5-flash-image",
    contents=[Image.open("media/cover-b39.png"), "Make the moon a thin crescent and keep everything else."],
    config=types.GenerateContentConfig(response_modalities=["TEXT", "IMAGE"]),
)
u = reply.usage_metadata
images = [p for p in reply.candidates[0].content.parts if p.inline_data]
print(f"{len(images)} image back; tokens in {u.prompt_token_count}, out {u.candidates_token_count}")
```

```
@@nano-edit@@
```

No mask, no alpha channel, no same-size rule: *make the moon a thin crescent and keep everything else*. The cover went in as 528 tokens, 516 of them for the picture by Gemini's rule of 258 per 768-pixel tile (the 600 by 900 cover takes two). That is easier to write and harder to control. A mask says exactly which pixels may change; a sentence says what a person wants and leaves the model to decide where that is. For a product banner that must keep its left two thirds identical, the mask is the safer tool; for "make it brighter" or "remove the cup", the sentence is far less work.

## Which model, and when it ends

```
@@sheet-gemini@@
```

**Gemini 2.5 Flash Image's entry carries a deprecation date of 2 October 2026**, five days before this lesson was recorded, and its successor, 3.1, is listed at 0.045 dollars a picture. The habits of section 03 apply here unchanged.
