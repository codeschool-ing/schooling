---
title: Top-k and top-p
version: 2
---

Temperature reshapes the whole distribution. **Top-k and top-p cut its tail off**, then share the
probability that is left among the candidates that remain. In `next.py`, as in most samplers, both
act after temperature:

```
ana@lab:~/triage$ python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t22 --top-k 3
t22, temperature 1, top-k 3, top-p 1, 1000 draws
  'other'      -0.49   64.5%   626  ##########################
  'billing'    -1.50   23.3%   241  #########
  'account'    -2.15   12.2%   133  #####
  ' billing'   -3.84    0.0%     0  
  'delivery'   -5.18    0.0%     0  
  ' Billing'   -5.81    0.0%     0  
  'Billing'    -6.15    0.0%     0  
  'shipping'   -6.30    0.0%     0  
  'payment'    -6.65    0.0%     0  
  'accounts'   -6.68    0.0%     0  
ana@lab:~/triage$ python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t22 --top-p 0.9
t22, temperature 1, top-k off, top-p 0.9, 1000 draws
  'other'      -0.49   64.5%   626  ##########################
  'billing'    -1.50   23.3%   241  #########
  'account'    -2.15   12.2%   133  #####
  ' billing'   -3.84    0.0%     0  
  'delivery'   -5.18    0.0%     0  
  ' Billing'   -5.81    0.0%     0  
  'Billing'    -6.15    0.0%     0  
  'shipping'   -6.30    0.0%     0  
  'payment'    -6.65    0.0%     0  
  'accounts'   -6.68    0.0%     0  
```

**Top-k keeps a fixed number of candidates**, here the three most probable. They had 96.3% of the
probability between them, and each one's share is now divided by that: `other` goes from 62.1% to
64.5%, and the seven below them get nothing, including all six that would fail the label check.

**Top-p keeps the smallest set of top candidates whose probabilities add up to at least p.** The
first three add up to 96.3%, which already reaches 90%, so top-p 0.9 keeps exactly the same three
words here and the two tables are identical. Top-k is a count and top-p is a share, and the
difference shows when the distribution changes shape: k keeps three words whether the top one has
99% or 40%, while p keeps fewer words when one dominates and more when the probability is spread out.

## The order of the steps

`distribution()` applies them in a fixed order: softmax with the temperature first, then top-k, then
top-p, then the survivors share the total. The order matters:

```
ana@lab:~/triage$ python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t22 --temperature 1.5 --top-p 0.9
t22, temperature 1.5, top-k off, top-p 0.9, 1000 draws
  'other'      -0.49   51.4%   493  #####################
  'billing'    -1.50   26.1%   259  ##########
  'account'    -2.15   16.9%   186  #######
  ' billing'   -3.84    5.5%    62  ##
  'delivery'   -5.18    0.0%     0  
  ' Billing'   -5.81    0.0%     0  
  'Billing'    -6.15    0.0%     0  
  'shipping'   -6.30    0.0%     0  
  'payment'    -6.65    0.0%     0  
  'accounts'   -6.68    0.0%     0  
```

At temperature 1.5 the distribution is flatter before top-p looks at it. The first three now add up
to only 87.8%, short of 90%, so top-p keeps a fourth token, and the fourth is `' billing'`, the one
with a space that fails the label check: 62 draws in a thousand. **A setting's effect depends on the
settings applied before it.**

Providers differ in which of these they expose and in the details of how they combine them.
Ollama's options include `temperature`, `top_k` and `top_p`. Anthropic's Messages API accepts
`temperature`, `top_k` and `top_p`; OpenAI's Chat Completions API accepts `temperature` and `top_p`
and has no `top_k`. Read the documentation of the one you call, and change one setting at a time,
for the reason lesson 7 gave.
