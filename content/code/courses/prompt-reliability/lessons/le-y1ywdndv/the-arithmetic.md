---
title: The arithmetic
version: 2
---

The cache does not change how many tokens are read, only what reading them costs. On your own
machine the cost is time, and the first section gives the two numbers that matter: 5009 milliseconds
to read the prompt with nothing cached, and about 750 with the guide cached and only the message new.

## What the cache saved

Per call, the guide-first prompt saved about four and a quarter seconds of reading out of five. The
writing, about three and a half seconds a call, did not change at all. So the whole call went from
roughly eight and a half seconds to roughly four, and the forty-call runs of the last section say the
same in their own way:

| | guide first | message first |
|---|---|---|
| tokens in a call | 285.1 | 285.1 |
| median call | 3.8 s | 7.6 s |
| forty calls | 152.7 s | 286.0 s |

**Half of every message-first call was reading a guide the cache already had**, at a position where
it could not be found. The bigger the fixed part of a prompt, the larger that share: a prompt with a
few pages of reference text and a one-line message is almost entirely cacheable, or almost entirely
not.

## And the money

A hosted provider charges for tokens, not seconds, and the providers that cache price a token read
from the cache well below an ordinary input token. Some also charge extra to write a prefix into the
cache the first time. Their documentation gives the numbers, and `cost.py` from lesson 16 takes a
price per token; to account for a cache you would give it one price for cached tokens and another
for the rest, and the provider's reply says how many of each a call used.

Where writing costs extra, the arithmetic has a trap in it: **a prefix used once costs more cached
than not cached**. The message-first prompt would pay to write every call's prefix and never read
one back. The rule that makes a cache pay is the one the last section measured, a long fixed
beginning and a short varying end, and the check is the same as for anything else that costs money:
run it, read what the provider reports, and compare.
