---
title: Cost is a workload, not a price
version: 1
---

Lesson 3 multiplied a price by a volume. For choosing between models that is the right idea and
the wrong level of detail, because three things move the bill more than the headline price does:
**how much of the prompt repeats**, **how much the model writes**, and **whether the answer is
needed now**.

Ana's drafting task is where they show. Its workload, the course's assumption: **400 requests a
day**, each carrying the shop's **5,000-token policy** (the same on every request), **60 tokens**
of fresh e-mail, and a reply of **200 tokens**. `monthly.py` prices it three ways from the
sheet's fields, for six candidates:

```python
import json

sheet = json.load(open("litellm-21881c57.json"))  # the copy sheet.py keeps
CANDIDATES = ["claude-haiku-4-5", "claude-sonnet-5-5", "gemini/gemini-3.5-flash-lite",
              "gpt-5.4-mini", "mistral/mistral-small-latest", "deepseek/deepseek-v3.2"]
# The drafting task, as the course assumes it: the shop's policy is the same
# 5,000 tokens on every request, the e-mail is 60 more, the reply is 200.
PER_DAY, POLICY, FRESH, OUT = 400, 5000, 60, 200
n = PER_DAY * 30


def money(x):
    return f"${x:8.2f}" if x is not None else "       -"


print(f"{'model':30} {'list':>9} {'cached':>9} {'batch':>9}   output share")
for m in CANDIDATES:
    e = sheet[m]
    i, o = e["input_cost_per_token"], e["output_cost_per_token"]
    plain = n * ((POLICY + FRESH) * i + OUT * o)
    read = e.get("cache_read_input_token_cost")
    cached = n * (POLICY * read + FRESH * i + OUT * o) if read else None
    bi, bo = e.get("input_cost_per_token_batches"), e.get("output_cost_per_token_batches")
    batch = n * ((POLICY + FRESH) * bi + OUT * bo) if bi and bo else None
    print(f"{m:30} {money(plain)} {money(cached)} {money(batch)}   {n * OUT * o / plain:6.0%}")
```

```
ana@desk:~/desk$ python monthly.py
model                               list    cached     batch   output share
claude-haiku-4-5               $   72.72 $   18.72 $   36.36      17%
claude-sonnet-5-5              $  145.44 $   37.44 $   72.72      17%
gemini/gemini-3.5-flash-lite   $   24.22 $    8.02 $   12.11      25%
gpt-5.4-mini                   $   56.34 $   15.84 $   28.17      19%
mistral/mistral-small-latest   $   10.55 $    2.45        -      14%
deepseek/deepseek-v3.2         $   17.96 $    2.84        -       5%
```

**List** is every token at the standard price. **Cached** charges the 5,000 repeated tokens at the
sheet's cache-read price, which assumes every request finds the policy still cached: a floor, since
the first request after the cache expires pays the full price and some providers charge extra to
write the cache. **Batch** is the price for requests sent in bulk and answered within hours, where
the provider offers it.

Three readings:

- **Caching changes the order more than the list does.** Claude Haiku goes from $72.72 to $18.72,
  DeepSeek from $17.96 to $2.84. A workload that repeats a long prefix should be priced at the
  cached rate, or the comparison is between bills nobody will pay.
- **Batch halves the bill**, at every provider in the sheet that lists it, and is useless for a
  draft an agent is waiting for. It fits the overnight work: re-sorting a backlog, evaluating
  candidates (lesson 5).
- **Output is a small share here**, 5% to 25%. That is a property of this workload, long prompt
  and short reply. Reverse it, a short question and a long answer, and the output price dominates;
  it is four to eight times the input price at five of the six providers above.

None of these numbers says which model to choose. They say what each would cost **for this
workload**, which is the only cost that means anything. Note that `batch` is blank for two rows: the
sheet has no batch price for them, which is not the same as the provider not offering
them. A blank is a question to check, not an answer.
