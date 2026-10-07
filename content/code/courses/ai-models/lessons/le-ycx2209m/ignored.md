---
title: Accepted is not obeyed
version: 1
---

Anthropic's documentation of its compatible endpoint is unusually frank about what the shape
promises, and it is worth reading as a description of every compatible API, not only this one:

```
# https://platform.claude.com/docs/en/cli-sdks-libraries/libraries/openai-sdk, read 2026-10-07
  62: This compatibility layer is primarily intended to test and compare model capabilities,
      and is not considered a long-term or production-ready solution for most use cases. While
      it is intended to remain fully functional and not have breaking changes, the priority is
      the reliability and effectiveness of the
 184: Most unsupported fields are silently ignored rather than producing errors. These are all
      documented in the following sections.
```

**Silently ignored.** The request is accepted, the answer comes back, and a field that would have
changed the answer elsewhere changed nothing. The documentation then lists the fields one by one.
Two of them matter to the work this course has done:

```
# https://platform.claude.com/docs/en/cli-sdks-libraries/libraries/openai-sdk, read 2026-10-07
 283| response_format
 284| Ignored. For JSON output, use
```

```
# https://platform.claude.com/docs/en/cli-sdks-libraries/libraries/openai-sdk, read 2026-10-07
 293| seed
 294| Ignored
```

`response_format` is how Chat Completions asks for JSON, the counterpart of lesson 16's
`text.format`. Sent here, it is dropped,
and the model writes whatever its prompt leads it to; a parser downstream finds out. `seed` is a
request for repeatable sampling, the property lesson 5 section 08 measured, and here it does
nothing. Two
more change values rather than dropping them, or take a feature away:

```
# https://platform.claude.com/docs/en/cli-sdks-libraries/libraries/openai-sdk, read 2026-10-07
 181: Prompt caching is not supported, but it is supported in the
 276: Between 0 and 1 (inclusive). Values greater than 1 are capped at 1.
```

A `temperature` of 1.5 tuned against OpenAI arrives as 1.0. Lesson 17's caching is not there at
all through this endpoint.

Anthropic writes its list down. A server that does not is not thereby a server that obeys
everything, and the only way to find out is to send a field and look at what changed. `limit.py`
asks Ollama for a one-sentence summary of an e-mail, limited to eight tokens, twice: once with the
limit under the name Chat Completions has always had, and once under the name OpenAI's library now
recommends:

```python
import json

from openai import OpenAI

client = OpenAI(base_url="http://127.0.0.1:11434/v1", api_key="ollama")
case = [json.loads(line) for line in open("cases/triage.jsonl")][0]

# the same limit, under the old name and under the name OpenAI's reference now uses
for field in ("max_tokens", "max_completion_tokens"):
    r = client.chat.completions.create(model="llama3.2:3b", temperature=0, messages=[
        {"role": "user", "content": "Summarise this e-mail in one sentence: " + case["text"]}], **{field: 8})
    print(f"{field:22} 8 -> {r.usage.completion_tokens:3} tokens, finish_reason {r.choices[0].finish_reason}")
```

```
ana@desk:~/desk$ python limit.py
max_tokens             8 ->   8 tokens, finish_reason length
max_completion_tokens  8 ->  37 tokens, finish_reason stop
```

The first limit held: eight tokens and `length`, the model cut off. The second was **accepted and
ignored**: no error, and the model wrote its whole sentence. The library's own documentation of the
older name says why a program would send the newer one. `chatdoc.py` prints it:

```python
import re
import sys

import openai.resources.chat.completions.completions as module

# the docstring of Completions.create, as the installed library carries it
source = open(module.__file__).read()
for name in sys.argv[1:]:
    m = re.search(rf"^ {{10}}{name}: .*?(?=\n\n {{10}}\w+: )", source, re.S | re.M)
    print(re.sub(r"(?m)^ {10}", "", m.group(0)) if m else f"{name}: not documented")
```

```
ana@desk:~/desk$ python chatdoc.py max_tokens
max_tokens: The maximum number of [tokens](https://platform.openai.com/tokenizer) that can
    be generated in the chat completion. This value can be used to control
    [costs](https://openai.com/api/pricing/) for text generated via API.

    This value is now deprecated in favor of `max_completion_tokens`, and is not
    compatible with
    [o-series models](https://developers.openai.com/api/docs/guides/reasoning).
```

So a program written to OpenAI's current reference, pointed at Ollama, has no output limit, and
nothing says so; lesson 21's caps on cost rest on exactly that field. And lesson 14 found the same
shape of gap at Ollama from the other direction, a setting its own API has and OpenAI's shape has
no room for:

```
# ollama/ollama@42e911bc docs/api/openai-compatibility.mdx
 386: The OpenAI API does not have a way of setting the context size for a model. If you need
      to change the context size, create a `Modelfile` which looks like:
```

So the rule for a program that talks to several providers through one shape:

- **The shape carries the common part.** Messages, the model's name, a limit, a temperature in the
  range everybody accepts, the text that comes back.
- **Everything else is per provider**, and is read in that provider's documentation, then checked
  by sending it: structured output, caching, seeds, output limits, context windows, rate-limit
  headers, how an error is worded.
- **The evaluation is per provider too**, run through the path the program will actually use.
  Lesson 5's numbers for a model through its own API say nothing certain about the same model
  through a compatible endpoint that ignores half the request.

The shape is the cheapest way to *compare* providers, which is what Anthropic says its endpoint is
for. Whether to *stay* on it is the trade lesson 16 put to OpenAI's own newer API: reach against
features, decided with the features you actually use written down.
