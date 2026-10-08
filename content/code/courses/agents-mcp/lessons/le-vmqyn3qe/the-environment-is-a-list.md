---
title: The environment is a list
version: 2
---

Lesson 12 found that one host handed its servers the whole environment, API keys included. `mcp_host.py` hands each server exactly what `ENV` names, and the list is two entries long: `PATH`, with the virtual environment's `bin` first, and `HOME`. `PATH` is there for a reason that is easy to miss: the command is `python`, and the server's process looks that name up in the `PATH` it is given, not in yours. Without the virtual environment in it, `python` is whatever the system has, if anything, and that Python has no `mcp`. Nothing else is needed, because nothing in `shop.py` reads a variable: `search_help` reaches Ollama at a fixed address.

A question for the help centre, and then the servers' standard error:

```
{block("help")}
```

The search worked, and the model then answered from the titles alone: it sent the customer to a "Help" tab and to the article on damaged books, for a question about returns. It could have read `help://h14` with `read_help`; this model, as lesson 1 found, does not call a second tool after a tool result. The host is not what went wrong there, and the next section gives the host's half of reading an article.

`host.err` is empty. That is where the two servers' standard error goes, because `2> host.err` covers the host's children too, and when a server crashes its traceback lands there and nowhere else: the client gets *"Error executing tool …"*, as lesson 14 showed. Two rules follow. **A minimal environment has to be complete**: list what each server needs, and test the tools that need it. And **keep the servers' standard error**: a host that throws it away (lessons 11 and 12 did, with `2> /dev/null`) has thrown away the only place a crash explains itself.
