---
title: OpenAI's Images API
version: 1
---

OpenAI's **Images API** has three routes: `generations` (a picture from a prompt), `edits` (a picture changed, optionally inside a mask) and, for the oldest model, `variations`. Each takes a model name, a prompt and a handful of settings, and returns the picture in the response as base64. As in lesson 3, the requests here go to the course's stand-in, so start `python images_server.py` in a second terminal first; with a key of your own, the `base_url` line is the one to change. The banner from lesson 3, as code:

```python
"""Ask the Images API for one banner and keep it, with a record of what asked for it."""
import base64
import json
import sys
from datetime import datetime

from openai import OpenAI
from PIL import Image

PROMPT = ("a stack of second-hand books on a café table, watercolour illustration, loose brushwork, "
          "wide banner, books on the left third, empty space on the right")
size = sys.argv[1] if len(sys.argv) > 1 else "1536x1024"
client = OpenAI(base_url="http://localhost:8800/v1")   # lesson 3's images_server.py
try:
    result = client.images.generate(model="gpt-image-1", prompt=PROMPT, size=size, quality="medium",
                                    output_format="png", n=1)
except Exception as e:
    sys.exit(f"{type(e).__name__}: {e}")
raw = base64.b64decode(result.data[0].b64_json)
open("banner.png", "wb").write(raw)
json.dump({"model": "gpt-image-1", "prompt": PROMPT, "size": size, "quality": "medium",
           "made": datetime.now().isoformat(timespec="seconds"), "approved_by": None},
          open("banner.json", "w"), indent=1)
print(f"banner.png: {len(raw):,} bytes, {Image.open('banner.png').size[0]}x{Image.open('banner.png').size[1]}")
```

```
ana@lab:~/mm$ python banner.py
banner.png: 35,712 bytes, 1536x1024
ana@lab:~/mm$ python banner.py 1792x1024
BadRequestError: Error code: 400 - {'error': {'message': "Invalid value: '1792x1024'. Supported values are: 'auto', '1024x1024', '1024x1536', '1536x1024'", 'type': 'invalid_request_error', 'param': 'size', 'code': None}}
ana@lab:~/mm$ cat banner.json; echo
{
 "model": "gpt-image-1",
 "prompt": "a stack of second-hand books on a caf\u00e9 table, watercolour illustration, loose brushwork, wide banner, books on the left third, empty space on the right",
 "size": "1536x1024",
 "quality": "medium",
 "made": "2026-10-07T13:25:28",
 "approved_by": null
}
```

**The picture is a card that says no model drew it**: the request went to lesson 3's `images_server.py`, which has no image model behind it. The request, the settings, the validation and the file on disk are real.

The settings that matter:

- **`size`** is a choice from a list, not any width and height. The stand-in accepts the four values OpenAI documents for its GPT image models, `auto`, `1024x1024`, `1024x1536` and `1536x1024`, and refused `1792x1024` with a 400 that names the valid ones. (`1792x1024` was a DALL-E 3 size, which is how code written for one model breaks on the next.)
- **`quality`** (`low`, `medium`, `high`) is the setting that moves the price most: section 06 shows a factor of fifteen.
- **`n`** asks for several pictures in one call, which is how lesson 3 saw a prompt's spread.
- **`output_format`** (`png`, `jpeg`, `webp`) decides the file; PNG keeps transparency.

**The record beside the picture** is the line that makes this production code rather than a demo: `banner.json` holds the model, the prompt, the settings, the time it was made and who approved it (nobody yet: `null`). Lesson 3 argued for that log; here it is written by the same program that made the picture, so it cannot be forgotten.
