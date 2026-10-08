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
