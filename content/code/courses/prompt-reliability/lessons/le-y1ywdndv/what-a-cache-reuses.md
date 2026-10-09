---
title: What a cache reuses
version: 2
---

The word suggests the wrong thing. A prompt cache does not store answers, and it does not remember
an earlier conversation. **It stores the work of reading the beginning of a prompt**, so that the
next call starting with exactly the same tokens can skip that part. The answer is still written
fresh every time.

Most of a production prompt is the same on every call. The prompt this lesson uses is
`v8-guide.txt` from lesson 5: a long guide to the categories followed by one customer's message, and
only the message changes. A cache is a way of not reading the guide again on every call.

## Ollama's cache

Ollama keeps one. It holds on to the prompts it has read recently, and when a request arrives it
looks among them for the one that shares the longest beginning with the new prompt, token by token
from the start, and reuses the work for that stretch. Nothing has to be switched on, and nothing in
a reply says it happened, except the time. Ollama reports
that time with every reply, split in two: how long it took to read the prompt and how long to write
the answer. `pl` keeps only the total, so this program asks Ollama directly and prints both halves
for the first few messages of a test set. Save it as `timing.py`:

```python
"""timing: where each call's time went, as Ollama reports it: reading the
prompt, and writing the reply."""
import json
import sys
import urllib.request

from pl import DEFAULTS, OLLAMA, read_jsonl, read_prompt, render, values_of

prompt_path, cases_path = sys.argv[1], sys.argv[2]
count = int(sys.argv[3]) if len(sys.argv) > 3 else 5
params, template = read_prompt(prompt_path)
params = {**DEFAULTS, **params}
options = {k: float(v) if "." in v else int(v) for k, v in params.items() if k != "model"}
print("case  read tokens  read ms  wrote tokens  write ms")
for case in read_jsonl(cases_path)[:count]:
    body = {"model": params["model"], "stream": False, "options": options,
            "messages": [{"role": "user", "content": render(template, values_of(case, {}))}]}
    req = urllib.request.Request(OLLAMA + "/api/chat", json.dumps(body).encode(),
                                 {"Content-Type": "application/json"})
    r = json.load(urllib.request.urlopen(req, timeout=600))
    print("%-5s %11d %8.0f %13d %9.0f" % (case["id"], r["prompt_eval_count"],
                                         r["prompt_eval_duration"] / 1e6,
                                         r["eval_count"], r["eval_duration"] / 1e6))
```

`prompt_eval_duration` and `eval_duration` are Ollama's names for the two halves, in nanoseconds;
the program prints milliseconds. Here are the first five dev messages under `v8-guide.txt`, on an
Ollama that had just been started, so that nothing was in its cache yet:

```
ana@lab:~/triage$ python3 timing.py prompts/v8-guide.txt cases/dev.jsonl 5
case  read tokens  read ms  wrote tokens  write ms
t01           287     5009            28      3129
t02           288      813            29      3148
t03           288      780            32      3686
t04           284      669            32      3376
t05           285      746            27      2932
```

The first call read 287 tokens in 5009 milliseconds. The next four read the same number of tokens in
between 669 and 813: **the count is the same and the work is not**, because only the message at the
end was new. The 287 in the `read tokens` column is what a hosted provider would bill, and what `pl`
records as `tokens_in`; the time is where the cache shows.

The writing half did not move, about three seconds a call, because the cache only ever touches the
prompt. And it does not last: `ollama ps` in lesson 1 said `llama3.2:3b` would stay in memory *3
minutes from now*. After five idle minutes Ollama unloads it, cache and all, and the next call reads
the whole prompt again.

## Real caches

Hosted providers cache a prefix too, and **every detail that matters is theirs to set**: the
shortest prompt they will cache, how long an unused prefix is kept, and what reading and writing it
cost. Some apply the cache automatically to any prompt long enough; OpenAI's prompt caching
documentation describes it that way. Others cache only where you mark the end of the prefix:
Anthropic's documentation has you put a `cache_control` marker in the request. Before relying on a
cache, **read your provider's documentation for the model you call**, and measure what it reports.

What every version shares is the rule this lesson is about: the cache matches from the start of the
prompt, so what comes first decides what can be reused.
