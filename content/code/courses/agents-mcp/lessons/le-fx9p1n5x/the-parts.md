---
title: What an agent is made of
version: 2
---

Take `agent.py` apart and there are five pieces. Every agent in this course, and every agent SDK in lessons 8 to 10, is the same five pieces with more code around them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"The parts of an agent. A host program holds the conversation so far and the stop rule. It sends the conversation and the tool definitions to the model. The model replies with either a tool call or an answer. A tool call is run by the host against a tool, and the result is appended to the conversation. An answer, or the stop rule firing, ends the loop.\"><defs><marker id=\"l1parts-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l1parts-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l1parts-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"380\" height=\"230\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"34\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the host program</text><rect x=\"40\" y=\"60\" width=\"160\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">conversation</text><text x=\"50\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">every message so far</text><rect x=\"40\" y=\"140\" width=\"160\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"50\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">stop rule</text><text x=\"50\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">steps, tokens, time</text><rect x=\"220\" y=\"100\" width=\"160\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"230\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the loop</text><text x=\"230\" y=\"136.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">send, read, run, append</text><rect x=\"520\" y=\"40\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">model</text><text x=\"530\" y=\"76.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">answer or tool call</text><rect x=\"520\" y=\"170\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tools</text><text x=\"530\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">get_order, search_help</text><path d=\"M380 115 L520 72\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l1parts-ah-amber)\"></path><path d=\"M520 84 L380 128\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l1parts-ah-amber)\"></path><path d=\"M380 140 L520 192\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l1parts-ah-wire)\"></path><path d=\"M520 206 L380 150\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" marker-end=\"url(#l1parts-ah-wire)\"></path><text x=\"450\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">request</text><text x=\"450\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">result</text><path d=\"M200 88 L220 120\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><path d=\"M200 168 L220 140\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path></svg>", "caption": "The model only ever returns words or a request for a tool. The host is what acts."}
```

- **A model** that can reply in one of two ways: with text, or with a structured request naming a tool and its arguments. Lesson 4 is about the second.
- **Tools**: functions the program is willing to run, each described to the model by a name, a sentence and a schema. In `agent.py` they are `get_order` and `search_help`, and their code is `shop.py`, which the model never sees.
- **The conversation**: the list `messages`, which starts with the user's message and gains one model reply and one batch of tool results per step. **It is the agent's whole state.** Nothing is remembered anywhere else.
- **The loop**: send, read, run, append, again.
- **A stop rule**: the model answering, or the program's own limit, whichever comes first. `agent.py` has both, and the limit is five steps.

## The model never acts

The picture to get rid of is a model reaching into a database. In the run for Bia, `llama3.2:3b` sent back a block that said, in effect, *"call get_order with order_id M-1042"*. `agent.py` read that block, looked `get_order` up in `RUN`, called `shop.get_order("M-1042")` on ana's machine and put the result in the conversation. **The model asked; the host acted.** Every permission an agent has is therefore a permission its host grants, which is why lesson 17 is about the host and not about the model.

## The conversation travels in full

A model API keeps nothing between requests. So each step sends everything again: the system prompt, the tool definitions, Bia's message, every earlier call and every earlier result. To see it, put a recorder between the program and Ollama. This one listens on port 11435, passes each request on to 11434 unchanged, and writes it down. Save it as `~/agents/recorder.py`; later lessons use it whenever they ask what a program actually sent.

```python
"""recorder.py: stands between your programs and Ollama, and writes down every request.

Point a program at http://127.0.0.1:11435 instead of 11434 and it works as
before, while each request lands in requests.jsonl as one JSON line: the path,
the body the program sent, the status, how long the reply took, and the tokens
the reply says it used.
"""
import http.client
import json
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

LOG = "requests.jsonl"


def usage_in(raw):
    """Tokens from a JSON reply, or from a stream's events: in (all of the prompt), of those cached, and out."""
    found = {}
    for line in raw.decode(errors="replace").splitlines():
        line = line.removeprefix("data:").strip()
        if not line.startswith("{"):
            continue
        event = json.loads(line)
        u = event.get("usage") or (event.get("message") or {}).get("usage")
        if not u:
            continue
        if "prompt_tokens" in u:   # OpenAI's shape: the cached tokens are part of prompt_tokens
            cached = (u.get("prompt_tokens_details") or {}).get("cached_tokens") or 0
            found.update(input_tokens=u["prompt_tokens"], cached_tokens=cached, output_tokens=u["completion_tokens"])
        else:                      # Anthropic's shape: input_tokens leaves the cached ones out
            if "input_tokens" in u:   # a stream's last event may carry the output count alone
                cached = u.get("cache_read_input_tokens") or 0
                found.update(input_tokens=u["input_tokens"] + cached, cached_tokens=cached)
            found["output_tokens"] = u.get("output_tokens", found.get("output_tokens"))
    return found


class Recorder(BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        started = time.monotonic()
        upstream = http.client.HTTPConnection("127.0.0.1", 11434, timeout=900)
        upstream.request(self.command, self.path, body, {"Content-Type": "application/json"})
        reply = upstream.getresponse()
        self.send_response(reply.status)
        self.send_header("Content-Type", reply.getheader("Content-Type", "application/json"))
        self.send_header("Connection", "close")
        self.end_headers()
        raw = b""
        while chunk := reply.read1(65536):
            raw += chunk
            self.wfile.write(chunk)
            self.wfile.flush()
        with open(LOG, "a") as log:
            log.write(json.dumps({"path": self.path, "request": json.loads(body or b"{}"),
                                  "status": reply.status, "ms": round(1000 * (time.monotonic() - started)),
                                  "usage": usage_in(raw)}) + "\n")

    do_GET = do_POST

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("127.0.0.1", 11435), Recorder).serve_forever()
```

Start it in the background, and run Bia's question again with `ANTHROPIC_BASE_URL` pointed at the recorder for that one command:

```
ana@lab:~/agents$ python recorder.py &
ana@lab:~/agents$ ANTHROPIC_BASE_URL=http://127.0.0.1:11435 python agent.py "Hi, I am Bia. My order M-1042 arrived on 24 September. Can I still send it back?"
[1] get_order({"order_id": "M-1042"})
[2] answer: Hi Bia, 

Unfortunately, since your order M-1042 was delivered on September 24th, you will not be able to return it. Our return policy typically applies to orders that have not been shipped or are still in the processing stage. 

However, I recommend contacting our customer service team to see if there are any exceptions or alternatives we can offer. We're here to help and would like to ensure you're satisfied with your purchase.
ana@lab:~/agents$ python -c 'import json; [print(n, r["usage"]["input_tokens"], r["usage"]["cached_tokens"], r["usage"]["output_tokens"], r["ms"]) for n, r in enumerate(map(json.loads, open("requests.jsonl")), 1)]'
1 270 239 18 2451
2 239 238 92 9552
```

The columns are the request number, its input tokens, how many of those Ollama already had in its cache from an earlier request, the output tokens and the milliseconds it took. The second request carried everything the first did plus the model's call and the order it got back, so it should be the larger of the two. **It is smaller: 239 tokens against 270.** Something the program sent did not reach the model.

The model never reads JSON. Ollama turns each request into one long text in the format the model was trained on, using a template that ships with the model, and the template decides what goes in:

```
ana@lab:~/agents$ ollama show llama3.2:3b --template | grep -n Tools
7:{{- if .Tools }}When you receive a tool call response, use the output to format an answer to the orginal user question.
14:{{- if and $.Tools $last }}
20:{{ range $.Tools }}
```

Line 14 is the whole story. The tool descriptions are written into the conversation only **inside the last message, when that message is the user's**. In the first request it was Bia's, so the model saw both tools and asked for one. In the second, the last message was a tool result, so the tools were left out, and a model that cannot see a tool cannot ask for it. That is why Bia's agent made one call and then had to answer from what it had, and it will happen to every agent in this course that runs on `llama3.2:3b`: **one tool call per turn of the user's, and never two in a row.**

Two lessons come out of it, and neither is about this model. A model only knows what the request carries after the provider has turned it into text, so "I sent the tools" and "the model saw the tools" are different claims, and only a measurement like the one above tells them apart. And the template is part of the model you chose: a paid API's model, or a bigger local one, takes several steps without blinking, and this one cannot. Where a lesson needs an agent to take several steps in a row to show a mechanism, it uses a stand-in model whose replies are written out in the lesson, and it says so where it does.

Neither the assistant nor the agent is cheaper as a rule: the assistant carried the whole help centre in one request, and the agent carries a little more in each step. Lesson 18 measures when each wins, and it starts from this growth.
