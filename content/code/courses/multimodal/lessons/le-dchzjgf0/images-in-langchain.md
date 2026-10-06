---
title: An image in a LangChain message
version: 1
---

`rag` lesson 10 met LangChain as a set of pieces for retrieval: loaders, splitters, a vector store, a chain. Its chat models also take **content blocks**: a message's `content` can be a list, and each item is text, an image, audio or a file. LangChain accepts two spellings of an image block, and this program sends the cover of lesson 8 once in each:

```python
"""The cover, sent through LangChain twice: once in OpenAI's own block, once in LangChain's."""
import base64

from langchain_core.messages import HumanMessage
from langchain_openai import ChatOpenAI

data = base64.b64encode(open("media/cover-b39.png", "rb").read()).decode()
openai_block = {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{data}"}}
standard_block = {"type": "image", "base64": data, "mime_type": "image/png"}

llm = ChatOpenAI(model="lab-vision-1")
for name, block in (("openai", openai_block), ("standard", standard_block)):
    message = HumanMessage(content=[{"type": "text", "text": "Describe this cover."}, block])
    sent = llm._get_request_payload([message])["messages"][0]["content"][1]   # what goes on the wire
    print(name, "->", sent["type"], sent["image_url"]["url"][:30])
    reply = llm.invoke([message])
    print("   ", reply.usage_metadata["input_tokens"], "tokens in:", reply.content[:60])
```

The first block is OpenAI's own format, the `image_url` with a data URL that lesson 8 built by hand. The second is **LangChain's standard block**: `type`, the base64 data and the `mime_type`, with no provider's name in it. `_get_request_payload` is a private method of `ChatOpenAI`, used here only to look at what would go on the wire:

```
ana@lab:~/mm$ python lc_cover.py
openai -> image_url data:image/png;base64,iVBORw0K
    772 tokens in: A book cover on a dark navy background. At the top right is 
standard -> image_url data:image/png;base64,iVBORw0K
    772 tokens in: A book cover on a dark navy background. At the top right is 
ana@lab:~/mm$ tail -n 2 /var/log/labmm/requests.jsonl | python -c "import json, sys; [print(r[\"images\"][0][\"sha256\"], r[\"images\"][0][\"tokens\"], r[\"rule\"]) for r in map(json.loads, sys.stdin)]"
88a80dab896d 765 l08-cover-describe
88a80dab896d 765 l08-cover-describe
```

**Both spellings left as the same request.** `ChatOpenAI` converted the standard block into an `image_url` with a data URL, and labmm's log shows the same image (`88a80dab896d`) costing the same 765 tokens both times, lesson 8's tile rule for a 600 by 900 picture. The 772 tokens in the reply's `usage_metadata` are those 765 plus the text and the message's overhead.

The reply is not a model's. labmm matched the image and the words "Describe this cover" to the rule `l08-cover-describe`, which the course wrote for lesson 8, and the log names that rule beside each request.

What the standard block buys is **one message for several providers**. The same `HumanMessage` given to `ChatGoogleGenerativeAI` or `ChatAnthropic` is converted into their formats by their integration packages, which is the job a framework does well. What it costs is a layer between you and the request: the conversion happens in a package with its own version, and the only way to know what was sent is to look, as this program did.
