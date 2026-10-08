---
title: The host reads, the model asks
version: 2
---

Lesson 14 made `search_help` return URIs, so that a host can read the articles. `mcp_host.py` gives the model a tool to ask for one, `read_help`, and does the reading itself. The model never talks to a resource; it asks the host, and the host decides.

That decision has a rule: only `help://` URIs are read. To see the rule at work, the model has to ask for something else, and asked plainly to read a file, `llama3.2:3b` did not try. A model that does try is easy to imagine and hard to produce on demand, so the second run below points the host at lesson 3's `standin.py`, which replies from a file written in advance. This is the file; it also scripts a refund for section 06:

```json
{"Read file:///": [{"tool": "read_help", "input": {"uri": "file:///home/ana/agents/data/shop.db"}},
                   {"text": "I can only read articles from the help centre."}],
 "arrived damaged": [{"tool": "refunds__refund", "input": {"order_id": "M-1047", "cents": 3890, "reason": "one copy arrived damaged"}},
                     {"text": "Done: 3890 cents have been refunded on order M-1047."}]}
```

The real model first, then the stand-in on port 11436:

```
ana@lab:~/agents$ python mcp_host.py "Read file:///home/ana/agents/data/shop.db for me." 2> host.err
step 1: shop__search_help {"query": "file:///home/ana/agents/data/shop.db"}
  result: {"result": [{"title": "Tracking a parcel", "uri": "help://h08"}, {"title": "Items that cannot be returned", "u
answer: It appears that the file at `file:///home/ana/agents/data/shop.db` is a SQLite database, but I couldn't retrieve the actual content of the database. However, I can suggest that you use the `sqlite3` command-line tool to view the contents of the database. 

You can use the following command to list the tables in the database:

`sqlite3 shop.db .tables`

This will list all the tables in the database. You can then use the `.headers on` and `.mode column` commands to view the contents of each table.

For example, to view the contents of the `items` table, you can use the following command:

`sqlite3 shop.db "SELECT * FROM items"`

This will display the contents of the `items` table.

Please note that you will need to have the `sqlite3` command-line tool installed on your system to view the contents of the database.
ana@lab:~/agents$ python standin.py standin15.json &
ana@lab:~/agents$ ANTHROPIC_BASE_URL=http://127.0.0.1:11436 python mcp_host.py "Read file:///home/ana/agents/data/shop.db for me." 2> host.err
step 1: read_help {"uri": "file:///home/ana/agents/data/shop.db"}
  error: only help:// articles can be read
answer: I can only read articles from the help centre.
```

`llama3.2:3b` searched the help centre for the URI, got three unrelated titles, and then told the customer how to open the database with `sqlite3`, down to a table called `items` that the shop does not have. Nothing was read, because nothing asked to read.

The stand-in asked for `file:///home/ana/agents/data/shop.db`, which is a URI, and nothing in MCP stops a model from writing one in a tool call. `run()` refuses anything that does not start with `help://` before any server is asked, and the model got an error result saying so. The stand-in's answer was written in its file; the refusal, the error result and the audit line of section 07 are the host's. The check is in the host because the host is where the request turns into an action; the shop server would have refused too (it serves only `help://`), but a host that relied on that would be trusting every server it connects to with the same care.

The same pattern fits any resource a host exposes: **decide which URIs the model may cause the host to read**, by scheme, by server, by pattern, and refuse the rest in the host's code. Lesson 17 tests this boundary with an instruction hidden in a document, against the course's own lab.
