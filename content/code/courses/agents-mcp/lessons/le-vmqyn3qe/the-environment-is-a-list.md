---
title: The environment is a list
version: 1
---

Lesson 12 found that one host handed its servers the whole environment, API keys included. `mcp_host.py` hands each server exactly what `ENV` names. The first version of that list had `PATH` and `HOME` only. Run again with that list, which is what `host_minimal.py` is:

```
ana@lab:~/agents$ grep -v MINILM_DIR mcp_host.py | sed 's/"HOME": "\/home\/ana",   # all/"HOME": "\/home\/ana"}   # all/' > host_minimal.py; python host_minimal.py 'How do I send a book back?' 2> host.err; tail -1 host.err
step 1: shop__search_help {"query": "send a book back"}
  error: Error executing tool search_help
step 2: read_help {"uri": "help://h14"}
  result: # How to return a book  You have 30 days from delivery to return a printed book in the condition you received 
answer: You have 30 days from delivery to return a printed book. Start the return from the order in your account, print the prepaid label and drop the parcel at any post office; returns are free.
mcp.server.mcpserver.exceptions.UnexpectedToolError: Error executing tool search_help
```

`search_help` failed with *"Error executing tool search_help"*. `host.err` is where the servers' standard error ended up, and its last line shows the server logged a crash, with the traceback above it. The cause was not in the message the model got: `search_help` embeds the query with the MiniLM model of `embeddings-vectors`, and the module that loads it finds the model's directory through `MINILM_DIR`. Without the variable it looked in a default directory that does not exist in this lab. The model then went on to read `help://h14` anyway, because the course's rules scripted that next step; a real model might not have.

With `MINILM_DIR` in the list:

```
ana@lab:~/agents$ python mcp_host.py "How do I send a book back?" 2> host.err
step 1: shop__search_help {"query": "send a book back"}
  result: {"result": [{"title": "How to return a book", "uri": "help://h14"}, {"title": "Damaged books on arrival", "uri
step 2: read_help {"uri": "help://h14"}
  result: # How to return a book  You have 30 days from delivery to return a printed book in the condition you received 
answer: You have 30 days from delivery to return a printed book. Start the return from the order in your account, print the prepaid label and drop the parcel at any post office; returns are free.
```

Two lessons from one failure. **A minimal environment has to be complete**: list what each server needs, and test the tools that need it. And **a server's crash is told to its log, not to the client**, as lesson 14 explained; a host that throws its servers' standard error away (lessons 11 and 12 did, with `2> /dev/null`) has thrown away the only place the reason was.
