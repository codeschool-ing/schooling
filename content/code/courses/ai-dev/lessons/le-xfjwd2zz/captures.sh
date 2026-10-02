#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of ai-dev, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: the machine, the SDKs, labllm
#   sudo bash captures.sh
#
# A line that starts with ana@dev:~/shop$ is what ana typed, in her project,
# and what it printed. What is STAGED rather than typed, and not shown in the
# lesson: the lab itself (lab.sh reset), and the files ana wrote (put below),
# whose contents the lesson shows in full.
#
# THE MODEL'S REPLIES IN THIS LESSON WERE WRITTEN BY THE COURSE, as rules in
# lab/scripted.json. labllm sends them at its fixed pace of 40 ms per token,
# which is slower than a real model's and chosen so a person can watch it.
# The SDKs, the server-sent events, the relay, the cancel and the error in the
# middle of a stream are real; the error is made on purpose with labllm's
# /lab/config switch, which the lesson shows.
#
# TIMES ARE MEASURED, not written: they are rounded to a tenth of a second,
# and a rerun can move one of them by a tenth.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@dev:~/shop$ %s\n' "$*"; lab exec ana "$*" 2>&1 || true; }
put() { lab exec ana "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
lab reset >/dev/null

put timing.py <<'PY'
"""The same reply twice: once waited for, once streamed. When does the first word arrive?"""
import time

import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]

t0 = time.monotonic()
r = model.messages.create(model="scripted-1", max_tokens=300, messages=ASK)
done = time.monotonic() - t0
print(f"create: first word after {done:.1f} s, all {r.usage.output_tokens} tokens after {done:.1f} s")

t0 = time.monotonic()
first = None
with model.messages.stream(model="scripted-1", max_tokens=300, messages=ASK) as stream:
    for text in stream.text_stream:
        if first is None:
            first = time.monotonic() - t0
    final = stream.get_final_message()
done = time.monotonic() - t0
print(f"stream: first word after {first:.1f} s, all {final.usage.output_tokens} tokens after {done:.1f} s")
PY

block why-stream
on 'python timing.py'

block on-the-wire
on "curl -sN \$ANTHROPIC_BASE_URL/v1/messages -H \"x-api-key: \$ANTHROPIC_API_KEY\" -H 'anthropic-version: 2023-06-01' -H 'content-type: application/json' -d '{\"model\": \"scripted-1\", \"max_tokens\": 50, \"stream\": true, \"messages\": [{\"role\": \"user\", \"content\": \"Say hello in five words.\"}]}' | cut -c1-110"

put pieces.py <<'PY'
"""Print each piece of a streamed reply as it arrives, with a bar between pieces."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
with model.messages.stream(model="scripted-1", max_tokens=300, messages=ASK) as stream:
    for text in stream.text_stream:
        print(text, end="|", flush=True)
    final = stream.get_final_message()
print()
print(final.stop_reason, final.usage.input_tokens, "in,", final.usage.output_tokens, "out")
PY
put openai_pieces.py <<'PY'
"""The same, through OpenAI's chat completions: chunks with a delta, then a finish_reason."""
import openai

client = openai.OpenAI()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
for chunk in client.chat.completions.create(model="scripted-1", messages=ASK, stream=True):
    choice = chunk.choices[0]
    if choice.delta.content:
        print(choice.delta.content, end="|", flush=True)
    if choice.finish_reason:
        print("\nfinish_reason:", choice.finish_reason)
PY

block with-the-sdk
on 'python pieces.py'
on 'python openai_pieces.py'

put relay.py <<'PY'
"""A relay between a browser and the model: the key stays here, the words go through."""
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import anthropic

model = anthropic.Anthropic()


class Relay(BaseHTTPRequestHandler):
    def send_event(self, name, data):
        self.wfile.write(f"event: {name}\ndata: {json.dumps(data)}\n\n".encode())
        self.wfile.flush()

    def do_POST(self):
        question = json.loads(self.rfile.read(int(self.headers["Content-Length"])))["question"]
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()
        try:
            with model.messages.stream(model="scripted-1", max_tokens=300,
                                       messages=[{"role": "user", "content": question}]) as stream:
                for text in stream.text_stream:
                    self.send_event("text", {"text": text})
            self.send_event("done", {"stop_reason": stream.get_final_message().stop_reason})
        except anthropic.APIError as e:
            self.send_event("error", {"message": "the answer stopped halfway; please ask again"})
            self.log_error("model stream failed: %s", e)

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("127.0.0.1", 8500), Relay).serve_forever()
PY
put client.mjs <<'JS'
// What a browser page does with the relay, run here with Node's fetch, which is the same API.
const response = await fetch("http://127.0.0.1:8500/ask", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ question: process.argv[2] }),
});
const reader = response.body.pipeThrough(new TextDecoderStream()).getReader();
let buffer = "";
let shown = "";
for (;;) {
  const { value, done } = await reader.read();
  if (done) break;
  buffer += value;
  const events = buffer.split("\n\n");
  buffer = events.pop();
  for (const raw of events) {
    const name = raw.match(/^event: (.*)$/m)[1];
    const data = JSON.parse(raw.match(/^data: (.*)$/m)[1]);
    if (name === "text") shown += data.text;
    if (name === "done") console.log(`${shown}\n[done: ${data.stop_reason}]`);
    if (name === "error") console.log(`${shown}\n[error: ${data.message}]`);
  }
}
JS

block to-the-browser
on 'python relay.py & sleep 1; curl -sN -X POST localhost:8500/ask -d '"'"'{"question": "Say hello in five words."}'"'"'; kill $!'
on 'python relay.py & sleep 1; node client.mjs "Explain in a paragraph why the cart stores prices in cents."; kill $!'

put cancel.py <<'PY'
"""Stop reading after the first forty characters, as a page does when someone presses Stop."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
got = ""
with model.messages.stream(model="scripted-1", max_tokens=300, messages=ASK) as stream:
    for text in stream.text_stream:
        got += text
        if len(got) >= 40:
            break
print(repr(got))
PY

block cancel
on 'python cancel.py'
on "sleep 1; tail -n 1 /var/log/labllm/requests.jsonl | python -c 'import json, sys; r = json.loads(sys.stdin.read()); print(r[\"status\"], \"| planned:\", r[\"usage\"][\"output_tokens\"], \"tokens | sent before the close:\", r[\"sent\"])'"

put midstream.py <<'PY'
"""A stream that fails partway: what the reader had, and what to do with it."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
shown = ""
try:
    with model.messages.stream(model="scripted-1", max_tokens=300, messages=ASK) as stream:
        for text in stream.text_stream:
            shown += text
            print(text, end="", flush=True)
except anthropic.APIError as e:
    print(f"\n[{type(e).__name__}: {e.message}]")
    print(f"[{len(shown)} characters were on the screen and are not an answer]")
PY

block errors
on "curl -s localhost:8400/lab/config -d '{\"stream_error_after\": 12}'; echo"
on 'python midstream.py'
on "curl -s localhost:8400/lab/config -d '{\"stream_error_after\": 12}' >/dev/null; python relay.py & sleep 1; node client.mjs 'Explain in a paragraph why the cart stores prices in cents.'; kill \$!"

put tool_stream.py <<'PY'
"""A tool call, streamed: its arguments arrive as pieces of JSON that do not parse until the end."""
import json

import anthropic

TOOLS = [{"name": "get_stock", "description": "Units in stock and unit price in cents for one product, by its SKU.",
          "input_schema": {"type": "object", "properties": {"sku": {"type": "string"}}, "required": ["sku"]}}]
model = anthropic.Anthropic()
with model.messages.stream(model="scripted-1", max_tokens=300, tools=TOOLS,
                           messages=[{"role": "user", "content": "Is LAMP-02 in stock?"}]) as stream:
    sofar = ""
    for event in stream:
        if event.type == "content_block_delta" and event.delta.type == "input_json_delta":
            sofar += event.delta.partial_json
            try:
                json.loads(sofar)
                parses = "parses"
            except json.JSONDecodeError:
                parses = "does not parse yet"
            print(f"{event.delta.partial_json!r:16} {parses}")
    call = stream.get_final_message().content[-1]
print(call.name, call.input)
PY

block tool-calls
on 'python tool_stream.py'

put partial.py <<'PY'
"""What a page would have to render at each moment of a reply written in Markdown."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "The cents rule, as a short list."}]
sofar = ""
with model.messages.stream(model="scripted-1", max_tokens=300, messages=ASK) as stream:
    for n, text in enumerate(stream.text_stream, 1):
        sofar += text
        if n in (2, 5, 12):
            print(f"after {n:2} pieces: {sofar!r}")
print(f"at the end:      {sofar!r}")
PY

block on-screen
on 'python partial.py'
