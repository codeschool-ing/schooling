---
title: Caching the prefix
version: 2
---

Most of each request was text the model had just read. Hosted providers offer **prompt caching** for exactly that: mark the end of a prefix that does not change (`cache_control` in the Anthropic API), and the provider keeps it for a short time, so later requests that start with the same prefix read it from the cache. Cached reads are billed far below ordinary input and the first write somewhat above it; the exact multipliers, and how long a prefix is kept, are on the provider's page.

Ollama does something similar on its own. While a model stays loaded, it keeps what it computed for the last prompts it read, and a new request that starts with the same tokens skips them. That was the 847 in section 02. Run the same question again, then once more with `--cache`, which marks the end of the policy block the Anthropic way:

```
ana@lab:~/agents$ python cost_run.py llama3.2:3b
step   input  c.write  c.read  output     ms  stop
   1     162        0     847      18   3955  tool_use
       tool search_help {"query": "Order status M-1043"}: 155 ms
   2      73        0     847      35   4893  end_turn
total     235        0    1694      53   9003
ana@lab:~/agents$ python cost_run.py llama3.2:3b --cache
step   input  c.write  c.read  output     ms  stop
   1     162        0     847      17   3473  tool_use
       tool get_order {"order_id": "M-1043"}: 1 ms
   2     184        0     847      62   8801  end_turn
total     346        0    1694      79  12275
```

Both runs reused the 847 tokens on **every** request, the first included, because the previous run had left them there. `--cache` changed nothing: Ollama accepts `cache_control` and ignores it, since it reuses whatever matches anyway. Notice the model too: one run searched the help centre, the other looked the order up. Same question, same prompt, two different paths; lesson 1 said the wording would differ, and here the choice of tool did.

The reuse keys on the **exact prefix**, from the first token, for Ollama as for a provider's cache. Anything that changes near the front breaks it for everything after. `--stamp` puts the time of the request at the very top of the system prompt, which looks harmless:

```
ana@lab:~/agents$ python cost_run.py llama3.2:3b --cache --stamp
step   input  c.write  c.read  output     ms  stop
   1    1004        0      15      17  11039  tool_use
       tool search_help {"query": "order M-1043"}: 164 ms
   2     905        0      21     245  36714  end_turn
total    1909        0      36     262  47917
```

Reuse fell to 15 and 21 tokens, and both requests read the whole prompt again: **1,909 tokens read**, against 235 and 346 in the runs above, and 47,917 ms, the slowest run in this lesson. With a hosted provider the same mistake is paid in money as well: every request writes the prefix again and reads none of it, which costs more than not caching at all. A date, a request id, a user's name at the top of a system prompt: each one turns a cache into a cost. Put what changes **after** what does not, and keep the tool list in a fixed order (the 2026-07-28 revision of MCP asks servers to return tools in a deterministic order for this reason). Lesson 10's ADK warned about the same effect from the other side: every transfer between agents changes the system prompt and the tools, so the prefix starts over.
