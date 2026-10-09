---
title: Four prices for one model
version: 1
---

Lesson 4 met two prices per model, standard and batch. Gemini Pro's entry carries more:

```
ana@desk:~/desk$ python sheet.py show gemini/gemini-pro-latest | grep -E "^(input|output)_cost_per_token"
input_cost_per_token                       2e-06
input_cost_per_token_above_200k_tokens     4e-06
input_cost_per_token_above_200k_tokens_priority 7.2e-06
input_cost_per_token_batches               1e-06
input_cost_per_token_flex                  1e-06
input_cost_per_token_priority              3.6e-06
output_cost_per_token                      1.2e-05
output_cost_per_token_above_200k_tokens    1.8e-05
output_cost_per_token_above_200k_tokens_priority 3.24e-05
output_cost_per_token_batches              6e-06
output_cost_per_token_flex                 6e-06
output_cost_per_token_priority             2.16e-05
```

Per million tokens, in and out:

| tier | input | output | what it buys |
|---|---|---|---|
| standard | $2 | $12 | an answer now |
| batch | $1 | $6 | an answer within hours, for a file of requests |
| flex | $1 | $6 | a lower price for weaker promises about speed |
| priority | $3.60 | $21.60 | a higher price for stronger ones |

The **flex** and **priority** lines are the sheet's record of Google selling the same model at
different levels of service. The sheet records prices and not promises, so what each level
guarantees is something to read on the provider's page before relying on it. Where they are a
choice per request rather than per account, they turn into a latency trade-off of exactly lesson 4
section 06's kind: background sorting could run on flex at
half price, a draft for a waiting agent could pay for priority at its p95.

## The price that changes with the prompt

Two lines above carry `above_200k_tokens`, and they change the arithmetic of long prompts. A naive
estimate of a 300,000-token request uses the standard rate:

```
ana@desk:~/desk$ python sheet.py cost gemini/gemini-pro-latest 300000 1000
# LiteLLM model sheet at 21881c57, 4472 entries
300,000 in  x $2/M = $0.6000
1,000 out x $12/M = $0.0120
total $0.6120
```

That is what `sheet.py cost` does, and it is wrong for this model. LiteLLM's own code, which uses these
same fields to bill its users, says how the threshold applies:

```
# BerriAI/litellm@21881c57 litellm/litellm_core_utils/llm_cost_calc/utils.py
 627: If input_tokens > threshold and `input_cost_per_token_above_[x]k_tokens` or
      `input_cost_per_token_above_[x]_tokens` is set,
 628: then we use the corresponding threshold cost for all token types.
```

**Once the prompt passes 200,000 tokens, every token in the request moves to the higher rate**, the
first 200,000 included, and the output with it. `tiered.py` applies that rule:

```python
import json
import sys

sheet = json.load(open("litellm-21881c57.json"))  # the copy sheet.py keeps
model, tokens_in, tokens_out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
e = sheet[model]
rate_in, rate_out = e["input_cost_per_token"], e["output_cost_per_token"]
if tokens_in > 200_000 and "input_cost_per_token_above_200k_tokens" in e:
    # the whole request moves to the higher rate, in and out
    rate_in = e["input_cost_per_token_above_200k_tokens"]
    rate_out = e["output_cost_per_token_above_200k_tokens"]
print(f"{tokens_in:,} in at ${rate_in * 1e6:g}/M, {tokens_out:,} out at ${rate_out * 1e6:g}/M: "
      f"${tokens_in * rate_in + tokens_out * rate_out:.4f}")
```

```
ana@desk:~/desk$ python tiered.py gemini/gemini-pro-latest 190000 1000; python tiered.py gemini/gemini-pro-latest 210000 1000
190,000 in at $2/M, 1,000 out at $12/M: $0.3920
210,000 in at $4/M, 1,000 out at $18/M: $0.8580
```

Twenty thousand more tokens of prompt, and the request costs **more than twice as much**: $0.3920
against $0.8580. A long-context workload that hovers near the line is a workload whose bill depends
on which side of it each request falls, and the fix is usually upstream: retrieve less (lesson 4
section 07), or split the document.

A reminder about the tool: the sheet records these tiers; `sheet.py cost` ignores them. **A cost
calculator that knows only the standard rate is right until the day it is badly wrong**, which is a
reason lesson 21 counts what each response reports rather than what a calculator predicts.
