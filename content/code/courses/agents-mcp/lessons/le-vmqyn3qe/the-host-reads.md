---
title: The host reads, the model asks
version: 1
---

Lesson 14 made `search_help` return URIs, so that a host can read the articles. `mcp_host.py` gives the model a tool to ask for one, `read_help`, and does the reading itself: section 04's run went from a search, to `help://h14`, to an answer. The model never talked to a resource; it asked the host, and the host decided.

That decision has a rule, and here is the rule at work. The course's script for this question has the model ask for a file:

```
ana@lab:~/agents$ python mcp_host.py "Show me the settings file" 2> host.err
step 1: read_help {"uri": "file:///home/ana/agents/data/shop.db"}
  error: only help:// articles can be read
answer: I can only read articles from the help centre.
```

`file:///home/ana/agents/data/shop.db` is a URI, and nothing in MCP stops a model from writing one in a tool call. `run()` refuses anything that does not start with `help://` before any server is asked, and the model got an error result saying so. The check is in the host because the host is where the request turns into an action; the shop server would have refused too (it serves only `help://`), but a host that relied on that would be trusting every server it connects to with the same care.

The same pattern fits any resource a host exposes: **decide which URIs the model may cause the host to read**, by scheme, by server, by pattern, and refuse the rest in the host's code. Lesson 17 tests this boundary with an instruction hidden in a document, against the course's own lab.
