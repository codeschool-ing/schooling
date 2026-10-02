---
title: Top-k and top-p
version: 1
---

Temperature reshapes the whole distribution. **Top-k and top-p cut its tail off**, then share the
probability that is left among the candidates that remain. Both act after temperature:

```
ana@lab:~/triage$ pl sample --top-k 3
Your parcel is ___   temperature 1, top-k 3, top-p 1, 1000 draws
  on         52.4%    570  #####################
  delayed    31.8%    277  #############
  here       15.8%    153  ######
  lost        0.0%      0  
  ready       0.0%      0  
  wet         0.0%      0  
  singing     0.0%      0  
  purple      0.0%      0  
ana@lab:~/triage$ pl sample --top-p 0.9
Your parcel is ___   temperature 1, top-k off, top-p 0.9, 1000 draws
  on         48.6%    523  ###################
  delayed    29.5%    259  ############
  here       14.6%    139  ######
  lost        7.3%     79  ###
  ready       0.0%      0  
  wet         0.0%      0  
  singing     0.0%      0  
  purple      0.0%      0  
```

**Top-k keeps a fixed number of candidates**, here the three most probable. They had 86.1% of the
probability between them, and each one's share is now divided by that: `on` goes from 45.1% to
52.4%.

**Top-p keeps the smallest set of top candidates whose probabilities add up to at least p.** The
first three add up to 86.1%, which is short of 90%, so `lost` joins them and the total reaches
92.8%. Four words stay. Top-k is a count and top-p is a share, and the difference shows when the
distribution changes shape: k keeps three words whether the top one has 99% or 40%, while p keeps
fewer words when one dominates and more when the probability is spread out.

## The order of the steps

The lab's sampler applies them in a fixed order, and its source says so:

```
ana@lab:~/triage$ sed -n '/^def distribution/,/return \[/p' promptlab/sample.py
def distribution(scores, temperature=1.0, top_k=0, top_p=1.0):
    """The probability of each candidate after temperature, then top-k, then
    top-p. A candidate cut by k or p gets exactly zero."""
    probs = softmax(scores, temperature)
    order = sorted(range(len(probs)), key=lambda i: -probs[i])
    keep = set(order[:top_k] if top_k else order)
    if top_p < 1.0:
        kept, acc = set(), 0.0
        for i in order:
            if i not in keep:
                continue
            kept.add(i)
            acc += probs[i]
            if acc >= top_p:
                break
        keep = kept
    total = sum(probs[i] for i in keep)
    return [probs[i] / total if i in keep else 0.0 for i in range(len(probs))]
ana@lab:~/triage$ pl sample --temperature 1.5 --top-p 0.9
Your parcel is ___   temperature 1.5, top-k off, top-p 0.9, 1000 draws
  on         37.1%    405  ###############
  delayed    26.6%    255  ###########
  here       16.7%    140  #######
  lost       10.5%    101  ####
  ready       9.2%     99  ####
  wet         0.0%      0  
  singing     0.0%      0  
  purple      0.0%      0  
```

Softmax with the temperature first, then top-k, then top-p, then the survivors are renormalised. The
order matters: at temperature 1.5 the distribution is flatter before top-p looks at it, so 0.9 now
keeps five words where at temperature 1 it kept four. **A setting's effect depends on the settings
applied before it.**

Providers differ in which of these they expose and in the details of how they combine them.
Anthropic's Messages API accepts `temperature`, `top_k` and `top_p`; OpenAI's Chat Completions API
accepts `temperature` and `top_p` and has no `top_k`. Read the documentation of the one you call,
and change one setting at a time, for the reason lesson 7 gave.
