---
title: From scores to a choice
version: 2
---

It is tempting to picture a model deciding on the next word. **What it produces is a score for
every token it could write next**, and a separate step, the sampler, turns those scores into one
choice. Temperature, top-k and top-p are settings of that step and of nothing else.
`prompt-engineering` introduced them in its lessons 13 and 14. This lesson takes them again on
purpose and measures them on the triage task, where a sampled answer is either right or wrong.

Ollama can return the scores. Ask for `logprobs`, and every token of the reply comes back with its
**log probability**, and with the log probabilities of the other tokens the model weighed at that
point. This program asks for one triage reply, finds the moment the model starts writing the
category, and prints the ten tokens it considered there. Then it does what a sampler does with
them, a thousand times, so you can watch the settings work. Save it as `next.py`:

```python
"""next: the model's own scores for the first token of the category, and what
temperature, top-k and top-p would make of them."""
import argparse
import json
import math
import random
import urllib.request

from pl import DEFAULTS, OLLAMA, read_jsonl, read_prompt, render


def candidates(prompt, n=10):
    """The n likeliest first tokens of the category, as (token, logprob)."""
    body = {"model": DEFAULTS["model"], "stream": False, "logprobs": True, "top_logprobs": n,
            "options": {"temperature": 0, "seed": 1, "num_predict": 12},
            "messages": [{"role": "user", "content": prompt}]}
    req = urllib.request.Request(OLLAMA + "/api/chat", json.dumps(body).encode(),
                                 {"Content-Type": "application/json"})
    reply = json.load(urllib.request.urlopen(req))
    text = ""
    for step in reply["logprobs"]:
        if text.endswith('"category": "'):
            return [(c["token"], c["logprob"]) for c in step["top_logprobs"]]
        text += step["token"]
    raise SystemExit("next: the reply has no category: " + text)


def distribution(scores, temperature=1.0, top_k=0, top_p=1.0):
    """Temperature, then top-k, then top-p, then the survivors share the total."""
    top = max(scores)
    weights = [math.exp((s - top) / temperature) for s in scores]
    probs = [w / sum(weights) for w in weights]
    order = sorted(range(len(probs)), key=lambda i: -probs[i])
    keep = order[:top_k] if top_k else order
    if top_p < 1.0:
        kept, total = [], 0.0
        for i in keep:
            kept.append(i)
            total += probs[i]
            if total >= top_p:
                break
        keep = kept
    total = sum(probs[i] for i in keep)
    return [probs[i] / total if i in keep else 0.0 for i in range(len(probs))]


p = argparse.ArgumentParser(prog="next")
p.add_argument("prompt")
p.add_argument("cases")
p.add_argument("id")
p.add_argument("--temperature", type=float, default=1.0)
p.add_argument("--top-k", type=int, default=0)
p.add_argument("--top-p", type=float, default=1.0)
p.add_argument("--draws", type=int, default=1000)
a = p.parse_args()

case = next(c for c in read_jsonl(a.cases) if c["id"] == a.id)
_, template = read_prompt(a.prompt)
cands = candidates(render(template, {"message": case["message"]}))
probs = distribution([lp for _, lp in cands], a.temperature, a.top_k, a.top_p)
rng = random.Random(1)
drawn = rng.choices(range(len(cands)), weights=probs, k=a.draws)
print("%s, temperature %g, top-k %s, top-p %g, %d draws"
      % (a.id, a.temperature, a.top_k or "off", a.top_p, a.draws))
for i, (token, logprob) in enumerate(cands):
    print("  %-10s %7.2f %6.1f%% %5d  %s" % (repr(token), logprob, 100 * probs[i],
                                            drawn.count(i), "#" * round(40 * probs[i])))
```

The scores are the model's; the drawing is done by `distribution()` and Python's `random`, so you
can see each step. Here is `t22`, the gift-card question lesson 5 argued about:

```
ana@lab:~/triage$ grep t22 cases/dev.jsonl
{"id": "t22", "message": "Can I pay with a gift card and a credit card on the same order?", "expect": {"category": "billing", "urgency": "low"}}
ana@lab:~/triage$ python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t22
t22, temperature 1, top-k off, top-p 1, 1000 draws
  'other'      -0.49   62.1%   604  #########################
  'billing'    -1.50   22.5%   226  #########
  'account'    -2.15   11.7%   122  #####
  ' billing'   -3.84    2.2%    32  #
  'delivery'   -5.18    0.6%     8  
  ' Billing'   -5.81    0.3%     3  
  'Billing'    -6.15    0.2%     2  
  'shipping'   -6.30    0.2%     1  
  'payment'    -6.65    0.1%     2  
  'accounts'   -6.68    0.1%     0  
```

Each line is a token the model considered, its log probability, its share once the program has
turned the scores into probabilities, how many of 1,000 draws picked it, and a bar. **Softmax is the
step that turns scores into probabilities**: raise *e* to each score, then divide each result by
their total, so that everything adds up to one. Only the differences between scores matter.
`other` scores about one point more than `billing`, and *e* to the 1.01 is about 2.75, which is the
ratio between 62.1% and 22.5%. The program keeps only the ten likeliest tokens, so the shares are
of those ten; the rest of the model's vocabulary held almost nothing here.

Three things in that list are worth a second look. **The model's favourite is wrong**: a person
labelled `t22` billing, and the model gives billing 22.5%. Temperature 0 takes the favourite every
time, which is why `t22` failed in lessons 5 and 7. The list also holds tokens that would break the
contract: `' billing'` with a space in front and `'Billing'` with a capital are different tokens from
`billing`, and either one would fail the `labels` check. And some messages are not close calls at
all:

```
ana@lab:~/triage$ python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t08
t08, temperature 1, top-k off, top-p 1, 1000 draws
  'returns'    -0.00   99.8%   998  ########################################
  'Returns'    -6.75    0.1%     2  
  '_returns'   -7.28    0.1%     0  
  ' returns'   -8.19    0.0%     0  
  'return'     -8.97    0.0%     0  
  ' Returns'   -9.44    0.0%     0  
  'orders'    -11.16    0.0%     0  
  'ret'       -11.77    0.0%     0  
  'other'     -11.80    0.0%     0  
  'returned'  -11.90    0.0%     0  
```

`t08`, an exchange of a hardback for a paperback, is `returns` with 99.8%. No setting of the
sampler will make much difference there. The rest of this lesson is about the messages like `t22`,
where it does.
