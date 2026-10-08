---
title: What a server sees
version: 2
---

The other half of the principle is what a server receives. The `orders` server was started through `tee` (lesson 11's trick, `orders:tee` in `hosts.py`) while each host answered *"Where is my order M-1043?"*. `said.py` prints each message's method and what the client declared, and for the tool call, its arguments and any `_meta` beyond the protocol's own fields:

```python
"""What each server's client sent it: the method, and anything the client declared about itself."""
import json
import sys

for name in sys.argv[1:]:
    print(name)
    for line in open(f"{name}.in.jsonl"):
        m = json.loads(line)
        p = m.get("params", {})
        meta = p.get("_meta", {})
        extra = p.get("capabilities", meta.get("io.modelcontextprotocol/clientCapabilities", ""))
        if m["method"] == "tools/call":
            extra = {"arguments": p["arguments"], "_meta": {k: v for k, v in meta.items() if "/protocolVersion" not in k
                                                          and "/clientInfo" not in k and "/clientCapabilities" not in k}}
        print(f"  {m['method']:26} {json.dumps(extra) if extra != '' else ''}")
```

```
ana@lab:~/agents$ python said.py OpenAI Claude Google
OpenAI
  server/discover            {}
  tools/list                 {}
  tools/call                 {"arguments": {"order_id": "M-1043"}, "_meta": {}}
  tools/list                 {}
Claude
  initialize                 {"roots": {"listChanged": true}, "elicitation": {}}
  notifications/initialized  
  tools/list                 
  prompts/list               
  resources/list             
  tools/call                 {"arguments": {"order_id": "M-1043"}, "_meta": {"claudecode/toolUseId": "call_r5k7x8tt", "progressToken": 4}}
Google
  initialize                 {}
  notifications/initialized  
  tools/list                 
  tools/call                 {"arguments": {"order_id": "M-1043"}, "_meta": {}}
```

**The server never received the customer's message.** It received a list request and a call with `{"order_id": "M-1043"}`. Which words the customer used, what else was in the conversation, what the model said afterwards: none of it reached the server, with any of the three hosts. That is the principle holding, and it holds because the host only sends a server what the protocol asks for. A host could put more in the arguments; a server can only ask, through its input schema, for what it needs.

The Claude host added two fields to the call's `_meta`: `claudecode/toolUseId`, the id of the model's tool call, and a `progressToken`, which lets a server report progress on a long call. Neither carries conversation; both are the host saying a little about itself.

The first messages are the clients **declaring capabilities**. The Claude client declared `roots` and `elicitation`: that it can tell a server which directories it may use, and that it can ask the person a question on a server's behalf. The Google client declared nothing. The OpenAI client's list is empty on every request. A server reads these to know what it may ask for; a server that needs a person's confirmation cannot get one from a client that did not declare elicitation. (Roots is deprecated in the 2026-07-28 revision, as lesson 11 listed; this client spoke 2025-11-25.)
