#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of agents-mcp, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset) and the files ana wrote (put below), which the lesson shows
# in full, each checked against it by lab/shown.py.
#
# THE MODEL IS REAL: llama3.2:3b (a80c4f17acd5) in Ollama 0.40.0, with an
# 8192-token context, captured on 2026-10-08. Its thoughts, its actions and
# the observations it invents are what it wrote that day.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
cd "$(dirname "$0")"
. ../../lab/capture.sh
lab exec 'python -c "import shop; shop.search_help(\"warm up\")"' >/dev/null
lab exec 'ollama run llama3.2:3b hello' < /dev/null >/dev/null 2>&1

put react_text.py <<'PY'
"""ReAct in plain text: the model writes Thought and Action lines, and the program parses them."""
import json
import re
import sys

import anthropic

import shop

PROMPT = """Answer the customer's question about Marginalia. You can use two tools:
  get_order[order id]    the order, its lines, and its amounts in cents
  search_help[words]     the three help-centre articles closest in meaning
Use this format, one Action at a time:
Thought: what you know and what you need next
Action: tool[argument]
Observation: (the program writes the tool's result here)
... and when you know enough:
Answer: the reply to the customer"""
TOOLS = {
    "get_order": lambda arg: shop.get_order(arg),
    "search_help": lambda arg: [a["title"] + ": " + a["body"] for a in shop.search_help(arg)],
}
STOP = ["Observation:"] if "--stop" in sys.argv else []

client = anthropic.Anthropic()
transcript = "Question: " + sys.argv[1] + "\n"
for step in range(1, 6):
    reply = client.messages.create(model="llama3.2:3b", max_tokens=400, system=PROMPT,
                                   messages=[{"role": "user", "content": transcript}],
                                   stop_sequences=STOP)
    text = reply.content[0].text.rstrip()
    print(f"--- step {step} (stop_reason: {reply.stop_reason})")
    print(text)
    answer = re.search(r"^Answer: (.*)", text, re.M)
    if answer:
        break
    action = re.search(r"^Action: (\w+)\[(.*)\]", text, re.M)
    if not action:   # neither an Action nor an Answer line: the reply is all there is
        break
    observation = json.dumps(TOOLS[action.group(1)](action.group(2)))
    print(f"Observation: {observation[:100]}")
    transcript += text + f"\nObservation: {observation}\n"
PY

block text-no-stop
on 'python react_text.py "Can I still return the books in order M-1047, and how would the refund work?"'
block text-stop
on 'python react_text.py "Can I still return the books in order M-1047, and how would the refund work?" --stop'

put react_native.py <<'PY'
"""ReAct with native tool calls: the thought is a text block, the action a tool_use block."""
import json
import sys

import anthropic

import shop

TOOLS = [
    {"name": "get_order",
     "description": "Look up one Marginalia order by its id, such as M-1042: status, dates, lines and amounts in cents.",
     "input_schema": {"type": "object", "properties": {"order_id": {"type": "string"}}, "required": ["order_id"]}},
    {"name": "search_help",
     "description": "Search Marginalia's help centre by meaning and return the three closest articles.",
     "input_schema": {"type": "object", "properties": {"query": {"type": "string"}}, "required": ["query"]}},
]
RUN = {
    "get_order": lambda args: shop.get_order(args["order_id"]),
    "search_help": lambda args: [{"title": a["title"], "body": a["body"]} for a in shop.search_help(args["query"])],
}
SYSTEM = ("You answer Marginalia's customers. Before each tool call, say in one sentence what you know "
          "and what you need next. Never guess an order's details.")

client = anthropic.Anthropic()
messages = [{"role": "user", "content": sys.argv[1]}]
seen = set()
with open("trace.jsonl", "w") as trace:
    for step in range(1, 7):
        reply = client.messages.create(model="llama3.2:3b", max_tokens=1024, system=SYSTEM,
                                       tools=TOOLS, messages=messages)
        messages.append({"role": "assistant", "content": reply.content})
        record = {"step": step, "stop_reason": reply.stop_reason, "input_tokens": reply.usage.input_tokens + (reply.usage.cache_read_input_tokens or 0),
                  "text": " ".join(b.text for b in reply.content if b.type == "text"), "calls": []}
        results = []
        for block in reply.content:
            if block.type != "tool_use":
                continue
            call = (block.name, json.dumps(block.input, sort_keys=True))
            if call in seen:
                record["calls"].append({"tool": block.name, "input": block.input, "refused": "repeat"})
                trace.write(json.dumps(record) + "\n")
                print(f"host: step {step} repeats {block.name}({json.dumps(block.input)}); stopping")
                sys.exit(1)
            seen.add(call)
            output = json.dumps(RUN[block.name](block.input))
            record["calls"].append({"tool": block.name, "input": block.input, "output": output[:80]})
            results.append({"type": "tool_result", "tool_use_id": block.id, "content": output})
        trace.write(json.dumps(record) + "\n")
        if reply.stop_reason != "tool_use":
            print(record["text"])
            break
        messages.append({"role": "user", "content": results})
PY

put show_trace.py <<'PY'
"""Print trace.jsonl as one block per step: what the model said, what it called, what came back."""
import json

for line in open("trace.jsonl"):
    r = json.loads(line)
    print(f"step {r['step']}  stop_reason={r['stop_reason']}  input_tokens={r['input_tokens']}")
    print(f"  said:     {r['text'][:96]}")
    for c in r["calls"]:
        print(f"  called:   {c['tool']}({json.dumps(c['input'])})")
        print(f"  returned: {c.get('output', 'refused: ' + c.get('refused', ''))[:72]}")
PY

block native
on 'python react_native.py "Can I still return the books in order M-1047, and how would the refund work?"'
block native-trace
on 'python show_trace.py'

put tokens.py <<'PY'
"""tokens.py: how many tokens llama3.2:3b reads in the text on standard input, counted by Ollama."""
import json
import sys
import urllib.request


def count(text, model="llama3.2:3b"):
    body = {"model": model, "prompt": text, "raw": True, "stream": False, "options": {"num_predict": 1}}
    req = urllib.request.Request("http://127.0.0.1:11434/api/generate", json.dumps(body).encode(),
                                 {"Content-Type": "application/json"})
    with urllib.request.urlopen(req) as r:
        return json.load(r)["prompt_eval_count"]


if __name__ == "__main__":
    print(count(sys.stdin.read()))
PY

block observation-size
on 'python -c "import json, shop; print(json.dumps(shop.get_order(\"M-1047\")))" | python tokens.py'
on 'python -c "import json, shop; o = shop.get_order(\"M-1047\"); print(json.dumps({k: o[k] for k in (\"status\", \"delivered_on\", \"total\")}))" | python tokens.py'
on 'python -c "import json, shop; print(json.dumps(shop.search_help(\"refund after a return\")))" | python tokens.py'

block loop
on 'python react_native.py "Do you sell signed first editions of Dom Casmurro?"'
on 'python show_trace.py'

put standin.py <<'PY'
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
PY

put loop.json <<'JSON'
{"signed first editions": [
  [{"text": "The help centre should say whether signed copies are sold."},
   {"tool": "search_help", "input": {"query": "signed copies"}}],
  [{"text": "Those articles do not mention signed copies; I will search for signed copies."},
   {"tool": "search_help", "input": {"query": "signed copies"}}]
]}
JSON

block standin-loop
on 'python standin.py loop.json &'
sleep 1
on 'ANTHROPIC_BASE_URL=http://127.0.0.1:11436 python react_native.py "Do you sell signed first editions of Dom Casmurro?"'
on 'python show_trace.py'
