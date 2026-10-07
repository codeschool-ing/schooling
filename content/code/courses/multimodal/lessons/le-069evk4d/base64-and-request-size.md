---
title: A picture inside a request is a third bigger
version: 2
---

Lesson 8 sent pictures as data URLs: base64 inside the JSON. Base64 spends four characters on every three bytes, so the request is bigger than the file it carries:

```python
"""How much bigger a picture gets on its way into a JSON request."""
import base64
import json
import sys

for path in sys.argv[1:]:
    raw = open(path, "rb").read()
    body = json.dumps({"model": "qwen2.5vl:3b", "messages": [{"role": "user", "content": [
        {"type": "text", "text": "Read the total."},
        {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64," + base64.b64encode(raw).decode()}}]}]})
    print("%-22s file %9d   request %9d   x%.3f" % (path.split("/")[-1], len(raw), len(body), len(body) / len(raw)))
```

```
ana@lab:~/mm$ python base64_size.py media/invoice-0931-scan.jpg media/phone.jpg
invoice-0931-scan.jpg  file     95891   request    128043   x1.335
phone.jpg              file    883497   request   1178183   x1.334
```

**About 1.334**, the four-thirds of base64 plus a few dozen bytes of JSON. It matters in two places. Request size limits apply to the request, not to the file, so a picture just under a documented limit can still produce a request over it. And every byte is uploaded on every call: 1.18 MB for one phone photo is a noticeable wait on a shop's connection, and the same picture asked about five times is uploaded five times.

Two ways around it, where a provider offers them. **A URL** the provider fetches, which lesson 8 showed and which moves the upload to the provider's side. **An uploaded file**, sent once and then named by an id in each request, which OpenAI's and Google's file APIs both provide. Both have their own size limits and retention rules, and both send the picture to the provider's storage, which is a question for the data policy before it is one for the bill.

Resizing to the provider's size first, as the last section did, shrinks all of this together.
