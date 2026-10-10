---
title: What one call costs, measured
version: 1
---

A model with a bill attached is a resource anybody who can send it text can spend. OWASP's list in
lesson 4 calls the failure **unbounded consumption**, `LLM10`: requests nobody limited, replies nobody
capped, loops nobody stopped, and a bill that arrives at the end of the month with the incident already
over. Lesson 7 limited how many requests one person sends a minute. This lesson is about **how much
each request costs and how much a person, and the whole assistant, may spend in a day.**

The unit is the token. A provider charges for the tokens it reads, the prompt, and for the tokens it
writes, the reply, usually at different prices, with the reply dearer. The prices in this lesson are
the course's, in reais, and a real provider publishes its own. Paste them:

```sh
cat > ~/guard/data/prices.json <<'EOF'
{
 "currency": "BRL",
 "cents_per_million_input": 1500,
 "cents_per_million_output": 6000
}
EOF
```

The program asks one question and reads back what the server counted, which every chat completions
server returns beside the reply. **Money is integer cents here, as everywhere money is handled**:
the sum is kept in millionths of a cent until it is printed, and never touches a float. It imports
`ask.py` from lesson 1 for the model's address. Save it as `~/guard/tools/cost.py`:

```python
# cost.py: what one question to the model costs, in tokens and in cents.
#
#   guard cost QUESTION [--max-tokens N]
#
# It asks the model once and prints what the server counted: the tokens of the
# prompt, the tokens of the reply, and why the reply stopped ("stop" when the
# model finished, "length" when it hit --max-tokens). The cost uses the prices
# in data/prices.json, which the course invented; a provider publishes its own.
# Money is integer cents, rounded half up, never a float.
import argparse
import json
import os
import sys
import urllib.error
import urllib.request

import ask

p = argparse.ArgumentParser(prog="guard cost")
p.add_argument("question")
p.add_argument("--max-tokens", type=int)
a = p.parse_args()

with open(os.path.expanduser("~/guard/data/prices.json"), encoding="utf-8") as f:
    prices = json.load(f)

body = {"model": ask.MODEL, "temperature": 0, "seed": 1,
        "messages": [{"role": "user", "content": a.question}]}
if a.max_tokens:
    body["max_tokens"] = a.max_tokens
req = urllib.request.Request(ask.URL + "/chat/completions", json.dumps(body).encode(),
                             {"Content-Type": "application/json"})
if ask.KEY:
    req.add_header("Authorization", "Bearer " + ask.KEY)
try:
    with urllib.request.urlopen(req, timeout=600) as r:
        reply = json.load(r)
except urllib.error.HTTPError as e:
    sys.exit("cost: %s answered %d: %s" % (ask.URL, e.code, e.read().decode().strip()))
except urllib.error.URLError as e:
    sys.exit("cost: cannot reach %s (%s). Is Ollama running?" % (ask.URL, e.reason))

used = reply["usage"]
millionths = (used["prompt_tokens"] * prices["cents_per_million_input"]
              + used["completion_tokens"] * prices["cents_per_million_output"])
cents, rest = divmod(millionths, 1_000_000)
cents += rest >= 500_000
text = reply["choices"][0]["message"]["content"]
print("prompt %d tokens, reply %d tokens, stopped: %s" % (
    used["prompt_tokens"], used["completion_tokens"], reply["choices"][0]["finish_reason"]))
print("cost %d cent(s) at the course's prices (%d millionths of a cent)" % (cents, millionths))
print("reply ends: ..." + text.replace("\n", " ")[-70:])
```

The same question twice, once without a limit on the reply and once with `--max-tokens 60`. The local
model costs nothing to run; the cents are what the same tokens would cost at the course's prices:

```
ana@lab:~/guard$ guard cost "Explain to a new client how payment works on a freelance marketplace that holds the money until the job is delivered."
prompt 48 tokens, reply 526 tokens, stopped: stop
cost 3 cent(s) at the course's prices (3228000 millionths of a cent)
reply ends: ...here to support you throughout your freelance journey on our platform.
ana@lab:~/guard$ guard cost "Explain to a new client how payment works on a freelance marketplace that holds the money until the job is delivered." --max-tokens 60
prompt 48 tokens, reply 60 tokens, stopped: length
cost 0 cent(s) at the course's prices (432000 millionths of a cent)
reply ends: ...or you.  Here's how it works:  1. **Client Places an Order**: A client
```

**The reply is where the money goes.** The prompt was 48 tokens both times. Unlimited, the model
wrote 526 tokens, eleven times the question, and at these prices the reply was most of the cost.
Capped at 60, it stopped with `length`, which is the server saying it cut the reply off rather than
the model finishing, and the last words show it: a numbered list that stops at its first item.

So `max_tokens` is two things at once, and both matter. It is **a ceiling on the cost of one call**,
the only one that does not depend on the model choosing to be brief. And it is **a way to break a
reply**: a cut-off answer is a worse answer, and a cut-off JSON object is not JSON at all. Lesson 9
set it near what the reply's schema allows, so that a reply that rambles fails quickly and the retry
loop handles it. Here the lesson is the same from the other side: **a reply that stops with `length`
is a failure to handle**, never a reply to show as it is.
