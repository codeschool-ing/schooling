---
title: Two layers
version: 1
---

The specification splits MCP into two layers, and keeping them apart makes every exchange easier to read.

The **data layer** is the messages. They are **JSON-RPC 2.0**: a **request** has an `id`, a `method` and `params`; a **result** or an **error** answers it, carrying the same `id`; a **notification** has a method and no `id`, and nobody answers it. On top of that format MCP defines the methods (`server/discover`, `tools/list`, `tools/call` and the rest) and what their params and results contain.

The **transport layer** is how the messages travel. **stdio**: the host starts the server as a child process and they exchange one message per line on its standard input and output. **Streamable HTTP**: each request is an HTTP POST to the server's endpoint, and the reply comes back in the response. The same `tools/call` is the same JSON on either.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"MCP&#x27;s two layers. The data layer is the JSON-RPC messages: requests with an id and a method, results and errors that answer them, notifications that expect no answer. The transport layer carries them: stdio, one message per line on a local program&#x27;s standard input and output, or Streamable HTTP, one POST per request to a server elsewhere. The same messages travel on either.\"><defs></defs><text x=\"20\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">data layer</text><rect x=\"20\" y=\"40\" width=\"160\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">request</text><text x=\"30\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">id, method, params</text><rect x=\"200\" y=\"40\" width=\"160\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">result</text><text x=\"210\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">id, result</text><rect x=\"380\" y=\"40\" width=\"160\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"390\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">error</text><text x=\"390\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">id, error.code</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">notification</text><text x=\"570\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">method, no id</text><text x=\"20\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">transport layer</text><rect x=\"20\" y=\"130\" width=\"330\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">stdio</text><text x=\"30\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one message per line, local program</text><rect x=\"370\" y=\"130\" width=\"330\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Streamable HTTP</text><text x=\"380\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one POST per request, server elsewhere</text></svg>", "caption": "The messages do not change with the transport."}
```

The rest of this lesson works at the bottom of both layers, with no library on the client side. `raw.py` starts a server, sends it messages from a file one line at a time, and prints each reply, cut to a width given on the command line so it fits the page:

```python
"""Send JSON-RPC messages to a stdio MCP server, one per line, and print each reply."""
import json
import subprocess
import sys

server = subprocess.Popen(["python", sys.argv[1]], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                          stderr=open("server.err", "w"), text=True)  # the server's logs, kept apart
width = int(sys.argv[2]) if len(sys.argv) > 2 else 200
for line in sys.stdin:
    message = json.loads(line)
    print(">", json.dumps(message)[:width])
    server.stdin.write(json.dumps(message) + "\n")  # the framing: one message, one line
    server.stdin.flush()
    if "id" in message:                              # a request gets one reply; a notification none
        print("<", server.stdout.readline().strip()[:width])
server.stdin.close()
server.wait()
```

The server is lesson 11's `shop_mcp.py`, unchanged. No model takes part in this lesson: every request was written by hand, and every reply is the server's.
