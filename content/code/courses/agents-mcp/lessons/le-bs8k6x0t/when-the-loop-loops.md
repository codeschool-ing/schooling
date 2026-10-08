---
title: When the loop does not end
version: 2
---

The customer asks whether Marginalia sells signed first editions of *Dom Casmurro*. The help centre has nothing that answers it. Here is `llama3.2:3b`:

```
ana@lab:~/agents$ python react_native.py "Do you sell signed first editions of Dom Casmurro?"
We do sell signed first editions of Dom Casmurro. If you're interested in purchasing one, please provide the title and quantity you'd like to buy, and I'll be happy to assist you with the ordering process.
ana@lab:~/agents$ python show_trace.py
step 1  stop_reason=tool_use  input_tokens=267
  said:     
  called:   search_help({"query": "signed first editions Dom Casmurro"})
  returned: [{"title": "Orders for schools and libraries", "body": "Institutions buy
step 2  stop_reason=end_turn  input_tokens=317
  said:     We do sell signed first editions of Dom Casmurro. If you're interested in purchasing one, please
```

**It did not loop. It did something worse.** One search, three articles about other things (orders for schools, among them), and then a confident yes. Nothing returned says Marginalia sells signed copies; the articles it did return say signed copies cannot be returned, which is a different matter. The trace shows the gap in two lines: `returned` holds nothing about first editions, and `said` promises one.

That failure is lesson 1's again, an answer the model made up after one tool, and the guard in `react_native.py` was never reached. To see the guard work, the model has to repeat itself, and a small model that stops after one call will not do that on request. So this section uses a **stand-in**: a program that speaks Anthropic's Messages API and answers each step with a reply written in advance. It has no model in it at all. Save it as `~/agents/standin.py`; later lessons use it whenever they need a model to take an exact path.

```python
"""standin.py REPLIES.json: a stand-in model. It answers Anthropic's Messages API with replies written in advance.

It has no model in it. REPLIES.json maps a phrase to the list of replies a
conversation gets, one per step: the first user message that contains the
phrase picks the list, and the number of assistant turns so far picks the
reply. A reply is {"text": ...}, {"tool": NAME, "input": {...}}, or a list of
those, sent as one message. Point a program at http://127.0.0.1:11436.
"""
import json
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

REPLIES = json.load(open(sys.argv[1]))


def text_of(message):
    c = message["content"]
    return c if isinstance(c, str) else " ".join(b.get("text", "") for b in c)


class StandIn(BaseHTTPRequestHandler):
    def do_POST(self):
        req = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        first = text_of(req["messages"][0])
        step = sum(1 for m in req["messages"] if m["role"] == "assistant")
        script = next((r for phrase, r in REPLIES.items() if phrase in first), None)
        if script is None or step >= len(script):
            return self.reply(400, {"type": "error", "error": {
                "type": "invalid_request_error", "message": "standin.py has no reply written for this step"}})
        planned = script[step] if isinstance(script[step], list) else [script[step]]
        content = [{"type": "text", "text": p["text"]} if "text" in p else
                   {"type": "tool_use", "id": f"toolu_{step}_{n}", "name": p["tool"], "input": p["input"]}
                   for n, p in enumerate(planned)]
        uses_tool = any(b["type"] == "tool_use" for b in content)
        self.reply(200, {"id": f"msg_standin_{step}", "type": "message", "role": "assistant",
                         "model": req["model"], "content": content,
                         "stop_reason": "tool_use" if uses_tool else "end_turn", "stop_sequence": None,
                         "usage": {"input_tokens": 0, "output_tokens": 0}})   # it counts nothing

    def reply(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("127.0.0.1", 11436), StandIn).serve_forever()
```

The replies are a file. This one gives any conversation that mentions *signed first editions* two steps, each a sentence and a search, and the second search is the first one again: the shape of a common loop, written down. Save it as `~/agents/loop.json`:

```json
{"signed first editions": [
  [{"text": "The help centre should say whether signed copies are sold."},
   {"tool": "search_help", "input": {"query": "signed copies"}}],
  [{"text": "Those articles do not mention signed copies; I will search for signed copies."},
   {"tool": "search_help", "input": {"query": "signed copies"}}]
]}
```

Start the stand-in, and point `react_native.py` at it for one run. The program is unchanged; only the address it sends to is different.

```
ana@lab:~/agents$ python standin.py loop.json &
ana@lab:~/agents$ ANTHROPIC_BASE_URL=http://127.0.0.1:11436 python react_native.py "Do you sell signed first editions of Dom Casmurro?"
host: step 2 repeats search_help({"query": "signed copies"}); stopping
ana@lab:~/agents$ python show_trace.py
step 1  stop_reason=tool_use  input_tokens=0
  said:     The help centre should say whether signed copies are sold.
  called:   search_help({"query": "signed copies"})
  returned: [{"title": "Orders for schools and libraries", "body": "Institutions buy
step 2  stop_reason=tool_use  input_tokens=0
  said:     Those articles do not mention signed copies; I will search for signed copies.
  called:   search_help({"query": "signed copies"})
  returned: refused: repeat
```

Step 1 searched for `signed copies` and got three articles about other things. Step 2's sentence says so, and then asks for the same search with the same words. The guard in `react_native.py` keeps a set of calls already made, as a tool name and its arguments with sorted keys; the second call was already in it, so the host stopped the run and wrote why. **Without the guard, this run would have repeated the search until the step limit**, paying for a growing request each time. The stand-in counts no tokens, which is why the trace says 0; with a real model each of those requests carries everything before it.

## Why models loop

A model chooses the next step from the conversation so far. If nothing in it changed, the same choice is likely again: the search returned nothing useful, so searching is still the obvious move, and the query that seemed best before still seems best. Real loops are rarely this blunt. More often a model alternates between two queries, or reads the same order with different capitalisation, which an exact-match guard misses.

## What a host can do

| failure | what to do in the host |
|---|---|
| the same call, same arguments | refuse it, or stop the run (this section) |
| near-identical calls | normalise arguments before comparing: trim, lower-case, sort keys |
| a call the model has no tool for | return an error naming the tools that exist |
| no progress for several steps | stop after N steps without a new tool or a new result (lesson 5) |
| answering before looking anything up | require at least one tool call for questions about orders, and check the answer cites a result |

Stopping is not the same as failing politely. A stopped run still owes somebody an answer, and the useful one here is honest: *"the help centre does not say; I am passing this to a person."* Lesson 5 is about what an agent returns when a limit fires, and it is the other half of every guard in this table.
