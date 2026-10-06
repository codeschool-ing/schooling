---
title: Two revisions, one server
version: 1
---

`said.py` reads the three files `tee` wrote and prints each message's method and, where the message names one, the protocol version:

```python
"""What each host's MCP client said to the server, one line per message."""
import json
import sys

for host in sys.argv[1:]:
    print(host)
    for line in open(f"{host}.in.jsonl"):
        m = json.loads(line)
        p = m.get("params", {})
        version = p.get("protocolVersion") or p.get("_meta", {}).get("io.modelcontextprotocol/protocolVersion", "")
        print(f"  {m['method']:28} {version}")
```

```
ana@lab:~/agents$ python said.py openai claude google
openai
  server/discover              2026-07-28
  tools/list                   2026-07-28
  tools/call                   2026-07-28
  tools/list                   2026-07-28
claude
  initialize                   2025-11-25
  notifications/initialized    
  tools/list                   
  prompts/list                 
  resources/list               
  tools/call                   
google
  initialize                   2025-11-25
  notifications/initialized    
  tools/list                   
  tools/call                   
```

**The three clients did not speak the same protocol.** The OpenAI SDK's client, which is the `mcp` SDK's own, began with `server/discover` and put the version `2026-07-28` on every request. The Claude Code CLI and the ADK began with `initialize`, version `2025-11-25`, followed by `notifications/initialized`. The server answered both, so all three hosts worked.

MCP's specification is published in **dated revisions**. The revision of 2026-07-28 made the protocol **stateless**: there is no handshake, and every request carries its protocol version and the client's capabilities in its `_meta`. A server must implement `server/discover`, which says what versions and capabilities it supports. The specification calls revisions with the handshake (2025-11-25 and earlier) **legacy**, the newer ones **modern**, and an implementation that speaks both **dual-era**; the `mcp` 2.3.0 server is dual-era, which is why the two older clients still worked. The session `ai-dev` lesson 7 typed by hand used an earlier legacy revision, 2025-06-18, with the same `initialize`.

The practical consequence is the one this course keeps returning to: **a protocol version is a fact about each pair, and you find it by looking.** A host built a year ago and a server built today may meet on the older revision, and some features exist only on one side of that line. Lesson 13 reads both kinds of exchange message by message.

One more line in the capture is worth noticing. The Claude Code client asked for `prompts/list` and `resources/list` as well as tools, although this server offers neither, while the other two asked only for tools. What a client asks for is the host's decision, which is the subject of section 06.
