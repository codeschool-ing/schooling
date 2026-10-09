---
title: Temperature
version: 2
---

**Temperature divides every score before softmax.** Below 1 it stretches the gaps between scores,
so the top candidate takes more of the probability. Above 1 it shrinks them, so the tail gets more.
Here is `t22` at 0.2 and at 1.5:

```
ana@lab:~/triage$ python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t22 --temperature 0.2
t22, temperature 0.2, top-k off, top-p 1, 1000 draws
  'other'      -0.49   99.4%   995  ########################################
  'billing'    -1.50    0.6%     5  
  'account'    -2.15    0.0%     0  
  ' billing'   -3.84    0.0%     0  
  'delivery'   -5.18    0.0%     0  
  ' Billing'   -5.81    0.0%     0  
  'Billing'    -6.15    0.0%     0  
  'shipping'   -6.30    0.0%     0  
  'payment'    -6.65    0.0%     0  
  'accounts'   -6.68    0.0%     0  
ana@lab:~/triage$ python3 next.py prompts/v6-escaped.txt cases/dev.jsonl t22 --temperature 1.5
t22, temperature 1.5, top-k off, top-p 1, 1000 draws
  'other'      -0.49   47.8%   449  ###################
  'billing'    -1.50   24.3%   253  ##########
  'account'    -2.15   15.7%   165  ######
  ' billing'   -3.84    5.1%    61  ##
  'delivery'   -5.18    2.1%    14  #
  ' Billing'   -5.81    1.4%    11  #
  'Billing'    -6.15    1.1%    19  
  'shipping'   -6.30    1.0%    11  
  'payment'    -6.65    0.8%    10  
  'accounts'   -6.68    0.8%     7  
```

At 0.2 the one-point gap between `other` and `billing` becomes a gap of five points, and `other`
takes 99.4%: five draws in a thousand say billing. At 1.5 the same gap shrinks to two-thirds of a
point, and `other` falls to 47.8%. **Flattening gives the tail its chances too**: the capitalised
`'Billing'` and the spaced `' billing'`, which fail the label check, were drawn 19 and 61 times in a
thousand, and `'shipping'` and `'payment'`, which are not labels at all, 11 and 10.

Temperature 0 cannot be computed this way, since nothing can be divided by zero, so it is defined as
the limit: always take the top candidate, with no draw at all. That is what `pl run` asks for by
default, and why its runs repeat.

**The number is relative to the scores it divides.** For `t22` the top two scores sit a point apart,
so a temperature of 1 leaves billing more than one chance in five. For `t08`, where the gap is almost
seven points, the same temperature changes almost nothing. On another model the same setting does
not promise the same amount, and the way to know is to measure on your own task, as the last section
of this lesson does.
