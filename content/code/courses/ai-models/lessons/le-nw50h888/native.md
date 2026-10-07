---
title: Ollama's own API
version: 1
---

Ollama has an official Python library, `ollama`, and `local_chat.py` uses it to sort one of
ana's cases with the triage prompt from lesson 1:

```python
import json

import ollama

prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

r = ollama.chat(model="llama3.2:3b", options={"temperature": 0},
                messages=[{"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
print(f"{case['id']}: {r.message.content}   (a person said {case['label']})")
print(f"read {r.prompt_eval_count} tokens, wrote {r.eval_count}")
print(f"{r.eval_count / r.eval_duration * 1e9:.1f} tokens/s while writing, {r.total_duration / 1e9:.2f} s in all")
```

```
ana@desk:~/desk$ python local_chat.py
c05: other.   (a person said other)
read 75 tokens, wrote 3
17.1 tokens/s while writing, 7.73 s in all
```

The answer is llama3.2:3b's, and the durations are this machine's. **Every response carries its own
accounting**: how many tokens were read
(`prompt_eval_count`), how many written (`eval_count`), and how long each part took, in
nanoseconds. The tokens-per-second line is the formula Ollama's documentation gives, and it is
lesson 3 section 05's throughput measured on your own hardware instead of computed from a
bandwidth. Most of the 7.73 seconds in all was the server loading the model from disk, which the
first request after a quiet spell pays for, and which *Loaded, and for how long* below is about.

What went over the wire is plain JSON to `localhost`, with no key. The library reads the server's
address from `OLLAMA_HOST`, so one run through the relay from lesson 9 section 03 shows it:

```
ana@desk:~/desk$ OLLAMA_HOST=http://127.0.0.1:8500 python local_chat.py
c05: order-status   (a person said other)
read 75 tokens, wrote 3
13.8 tokens/s while writing, 0.42 s in all
ana@desk:~/desk$ python relay.py show --headers user-agent
POST /api/chat
user-agent: ollama-python/0.6.3 (x86_64 linux) Python/3.13.16

{
  "model": "llama3.2:3b",
  "stream": false,
  "options": {
    "temperature": 0
  },
  "messages": [
    {
      "role": "system",
      "content": "You sort the e-mail of Lantern Books, an online bookshop.\nAnswer with exactly one label and nothing else:\norder-status, refund, address-change, product-question, other.\n"
    },
    {
      "role": "user",
      "content": "Do you have a physical shop I can visit in Curitiba?"
    }
  ],
  "tools": []
}
```

The same request a moment later took 0.42 seconds, because the model was already loaded, and it
answered `order-status` where the first said `other.`: even at temperature 0 a model can answer the
same question two ways, as lesson 5 section 08 warned. The settings that an API puts at the top
level, Ollama puts in `options`: `temperature` here, and
`num_ctx` in section 04.

## Loaded, and for how long

A local model has to be in memory to answer, and loading gigabytes of weights from disk takes time,
which the first request pays. Ollama keeps a model loaded after a request, and says until when:

```
ana@desk:~/desk$ python -c "import ollama; [print(m.model, m.expires_at) for m in ollama.ps().models]"
llama3.2:3b 2026-10-07 17:24:23.909707+00:00
```

```
# ollama/ollama@42e911bc docs/faq.mdx
 291: By default models are kept in memory for 5 minutes before being unloaded. This allows
      for quicker response times if you're making numerous requests to the LLM. If you want to
      immediately unload a model from memory, use the `ollama stop` command:
```

Five minutes after the last request, the memory is given back. `keep_alive` on a request changes
that: a duration keeps it longer, a negative number such as `-1` keeps it loaded, and `0` unloads
it at once:

```
ana@desk:~/desk$ python -c "import ollama; print(ollama.generate(model=\"llama3.2:3b\", keep_alive=0).done_reason); print(len(ollama.ps().models), \"models loaded\")"
unload
0 models loaded
```

For ana's desk the trade is lesson 3's: a model kept loaded answers the first e-mail of the morning
as fast as the hundredth, and holds the memory all night to do it.

## Local is a property of where it runs

```
# ollama/ollama@42e911bc docs/faq.mdx
 161: Ollama runs locally. We don't see your prompts or data when you run locally. When using
      cloud-hosted models, we process your prompts and responses to provide the service but do
      not store or log that content and never train on it. We collect basic account info and
      limited usage metadata to provide the service that does not include prompt or response
      content. We don't sell your data. You can delete your account anytime.
```

**When it runs locally.** The same documentation describes cloud-hosted models, and an
OpenAI-compatible endpoint at ollama.com that needs no installation at all:

```
# ollama/ollama@42e911bc docs/api/openai-compatibility.mdx
   9: Set your [API key](https://ollama.com/settings/keys) in `OLLAMA_API_KEY`. Install the
      client with `pip install openai`. No Ollama installation required.
  16: base_url="https://ollama.com/v1",
```

So *we use Ollama* answers lesson 2 section 07's question only after a second one: which address
does the program send to? `localhost:11434` keeps the e-mail on the machine; `ollama.com` sends it
to a provider, under that provider's terms, like any API in lessons 6 to 9.
