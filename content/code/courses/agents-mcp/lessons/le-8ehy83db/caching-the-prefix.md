---
title: Caching the prefix
version: 1
---

Most of each request was text the provider had just read. Providers offer **prompt caching** for exactly that: mark the end of a prefix that does not change (`cache_control` in the Anthropic API), and the provider keeps it for a short time, so later requests that start with the same prefix read it from the cache. Cached reads are billed far below ordinary input and the first write somewhat above it; the exact multipliers are on the provider's page. labllm follows the same rule: a marked prefix of 1,024 tokens or more is written once and read for 300 seconds.

`--cache` marks the end of the policy block. Two runs, one after the other:

```
ana@lab:~/agents$ python cost_run.py scripted-1 --cache
step   input  c.write  c.read  output     ms  stop
   1      12     2347       0      10    632  tool_use
       tool get_order: 1 ms
   2     173        0    2347       8    570  tool_use
       tool search_help: 314 ms
   3     214        0    2347      75   3209  end_turn
total     399     2347    4694      93   4726
ana@lab:~/agents$ python cost_run.py scripted-1 --cache
step   input  c.write  c.read  output     ms  stop
   1      12        0    2347      10    634  tool_use
       tool get_order: 1 ms
   2     173        0    2347       8    570  tool_use
       tool search_help: 332 ms
   3     214        0    2347      75   3209  end_turn
total     399        0    7041      93   4747
```

In the first run, request 1 **wrote** 2,347 tokens to the cache and requests 2 and 3 **read** them, so only 399 tokens across the run were ordinary input. The second run, inside the 300 seconds, read the prefix on its first request too: **no write at all**, 7,041 tokens read. The total is the same 7,440 tokens either way; what changes is how they are billed.

The cache keys on the **exact prefix**, from the first byte. The order is tools, then system prompt, then messages, so anything that changes near the front breaks it for everything after. `--stamp` puts the time of the request at the very top of the system prompt, which looks harmless:

```
ana@lab:~/agents$ python cost_run.py scripted-1 --cache --stamp
step   input  c.write  c.read  output     ms  stop
   1      12     2358       0      10    637  tool_use
       tool get_order: 1 ms
   2     173     2358       0       8    577  tool_use
       tool search_help: 381 ms
   3     214     2358       0      75   3210  end_turn
total     399     7074       0      93   4806
```

Every request wrote the prefix again, **7,074 tokens written and none read**: more expensive than not caching at all, since writes cost more than ordinary input. A date, a request id, a user's name at the top of a system prompt: each one turns a cache into a cost. Put what changes **after** what does not, and keep the tool list in a fixed order (the 2026-07-28 revision of MCP asks servers to return tools in a deterministic order for this reason). Lesson 10's ADK warned about the same effect from the other side: every transfer between agents changes the system prompt and the tools, so the prefix starts over.
