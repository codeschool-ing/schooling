---
title: An image in a LlamaIndex message
version: 1
---

LlamaIndex says the same thing with different nouns. A `ChatMessage` is made of **blocks**, and `ImageBlock` takes a path, a URL or bytes and does the base64 itself:

```python
"""The same cover through LlamaIndex: a ChatMessage made of blocks."""
import os
import sys

from llama_index.core.llms import ChatMessage, ImageBlock, TextBlock

message = ChatMessage(role="user", blocks=[TextBlock(text="Describe this cover."),
                                           ImageBlock(path="media/cover-b39.png")])
if sys.argv[1:] == ["openai"]:
    from llama_index.llms.openai import OpenAI
    llm = OpenAI(model="lab-vision-1")
else:
    from llama_index.llms.openai_like import OpenAILike
    print("default api_base:", OpenAILike(model="lab-vision-1").api_base)
    llm = OpenAILike(model="lab-vision-1", is_chat_model=True, api_base=os.environ["OPENAI_BASE_URL"])
reply = llm.chat([message])
print(reply.raw.usage.prompt_tokens, "tokens in:", reply.message.content[:60])
```

The program runs two ways. With `openai`, it uses the integration named after the provider; without, it uses `OpenAILike`, the integration for servers that speak OpenAI's format:

```
ana@lab:~/mm$ python li_cover.py openai 2>&1 | tail -n 1 | cut -c1-120
ValueError: Unknown model 'lab-vision-1'. Please provide a valid OpenAI model name in: o1, o1-2024-12-17, o1-pro, o1-pro
ana@lab:~/mm$ python li_cover.py
default api_base: https://api.openai.com/v1
772 tokens in: A book cover on a dark navy background. At the top right is 
ana@lab:~/mm$ tail -n 1 /var/log/labmm/requests.jsonl | python -c "import json, sys; r = json.loads(sys.stdin.read()); print(r[\"images\"][0][\"sha256\"], r[\"images\"][0][\"tokens\"], r[\"rule\"])"
88a80dab896d 765 l08-cover-describe
```

**The first run never sent anything.** LlamaIndex's `OpenAI` class keeps its own table of model names, to know each one's context window, and refuses a name it has not heard of, here `lab-vision-1`. A new model from the provider meets the same refusal until the package is updated, which is one of the ways a framework ages faster than the API under it.

**The second run printed the default address before it sent anything**: `https://api.openai.com/v1`. `OpenAILike` does not read `OPENAI_BASE_URL`, the variable the OpenAI SDK and LangChain both read in this lab. Left to its default, it would have sent the cover and the lab's key to OpenAI. The program passes `api_base` explicitly, and the request reached labmm with the same image, the same 765 tokens and the same rule as LangChain's two.

Both lessons are about configuration rather than images. **A framework reads its own settings**, from its own variables, with its own defaults, and two packages in one program can disagree about where requests go. The habit that catches it is cheap: print the address, or watch the first request arrive where you expected it.
