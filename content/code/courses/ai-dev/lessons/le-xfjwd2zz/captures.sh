#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of ai-dev, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: Ollama, the models, ~/shop
#   sudo bash captures.sh
#
# A line that starts with ana@dev:~/shop$ is what ana typed, in her project,
# and what it printed. What is STAGED rather than typed, and not shown: the
# lab's own reset, the files ana wrote (put below), each of which a lesson
# shows whole (put refuses one that no lesson shows byte for byte), and the
# restart of Ollama after errors stops it, which the lesson tells the student
# to do and does not show.
#
# THE REPLIES COME FROM llama3.2:3b, at the speed the recording machine gives
# it: about ten tokens a second, on 4 cores with no GPU. A rerun gives other
# words and other times. The error in the middle of a stream is real: errors
# stops Ollama itself while a reply is arriving, with `sudo pkill -x ollama`,
# as closing the terminal that runs `ollama serve` would.
#
# The server's own log is quoted once, in cancel, as the lines the terminal
# running `ollama serve` prints; on the recording machine they go to a file
# the lab keeps, so this script prints its last lines under a marker of its
# own rather than as something ana typed.
#
#   model    llama3.2:3b (a80c4f17acd5), Ollama 0.40.0
#   taken    2026-10-07, on 4 cores and 15 GB with no GPU
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

quiet lab reset
quiet lab exec ana 'sudo apt-get remove -y -qq nodejs'  # the student has no Node before this lesson

put timing.py <<'PY'
"""The same reply twice: once waited for, once streamed. When does the first word arrive?"""
import time

import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]

t0 = time.monotonic()
r = model.messages.create(model="llama3.2:3b", max_tokens=300, messages=ASK)
done = time.monotonic() - t0
print(f"create: first word after {done:.1f} s, all {r.usage.output_tokens} tokens after {done:.1f} s")

t0 = time.monotonic()
first = None
with model.messages.stream(model="llama3.2:3b", max_tokens=300, messages=ASK) as stream:
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
on "curl -sN \$ANTHROPIC_BASE_URL/v1/messages -H \"x-api-key: \$ANTHROPIC_API_KEY\" -H 'anthropic-version: 2023-06-01' -H 'content-type: application/json' -d '{\"model\": \"llama3.2:3b\", \"max_tokens\": 50, \"stream\": true, \"messages\": [{\"role\": \"user\", \"content\": \"Say hello in five words.\"}]}' | cut -c1-110"

put pieces.py <<'PY'
"""Print each piece of a streamed reply as it arrives, with a bar between pieces."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
with model.messages.stream(model="llama3.2:3b", max_tokens=300, messages=ASK) as stream:
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
for chunk in client.chat.completions.create(model="llama3.2:3b", messages=ASK, stream=True):
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
            with model.messages.stream(model="llama3.2:3b", max_tokens=300,
                                       messages=[{"role": "user", "content": question}]) as stream:
                for text in stream.text_stream:
                    self.send_event("text", {"text": text})
            self.send_event("done", {"stop_reason": stream.get_final_message().stop_reason})
        except Exception as e:  # whatever ended it, the page has half an answer
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
on 'sudo apt install -y nodejs 2>&1 | tail -n 1; node --version'
on 'python relay.py & sleep 3; curl -sN -X POST localhost:8500/ask -d '"'"'{"question": "Say hello in five words."}'"'"'; kill $!'
on 'python relay.py & sleep 3; node client.mjs "Explain in a paragraph why the cart stores prices in cents."; kill $!'

put cancel.py <<'PY'
"""Stop reading after the first forty characters, as a page does when someone presses Stop."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
got = ""
with model.messages.stream(model="llama3.2:3b", max_tokens=300, messages=ASK) as stream:
    for text in stream.text_stream:
        got += text
        if len(got) >= 40:
            break
print(repr(got))
PY

block cancel
on 'python cancel.py'
sleep 1
block cancel-log
tail -n 3 /var/log/ollama-capture.log

put midstream.py <<'PY'
"""A stream that fails partway: what the reader had, and what to do with it."""
import anthropic

model = anthropic.Anthropic()
ASK = [{"role": "user", "content": "Explain in a paragraph why the cart stores prices in cents."}]
shown = ""
try:
    with model.messages.stream(model="llama3.2:3b", max_tokens=300, messages=ASK) as stream:
        for text in stream.text_stream:
            shown += text
            print(text, end="", flush=True)
except Exception as e:  # an API error, or the connection itself, as below
    print(f"\n[{type(e).__module__}.{type(e).__name__}: {e}]")
    print(f"[{len(shown)} characters were on the screen and are not an answer]")
PY

block errors
quiet lab exec ana 'ollama run llama3.2:3b "Say ready." < /dev/null'  # loaded, so the stop lands mid-reply
on 'python midstream.py & sleep 5; sudo pkill -x ollama; wait'
quiet lab serve
quiet lab exec ana 'ollama run llama3.2:3b "Say ready." < /dev/null'
on 'python relay.py & sleep 3; node client.mjs "Explain in a paragraph why the cart stores prices in cents." & sleep 5; sudo pkill -x ollama; wait %2; kill %1'
quiet lab serve

put tool_stream.py <<'PY'
"""A tool call, streamed: its arguments arrive as pieces of JSON that do not parse until the end."""
import json

import anthropic

TOOLS = [{"name": "get_stock", "description": "Units in stock and unit price in cents for one product, by its SKU.",
          "input_schema": {"type": "object", "properties": {"sku": {"type": "string"}}, "required": ["sku"]}}]
model = anthropic.Anthropic()
with model.messages.stream(model="llama3.2:3b", max_tokens=300, tools=TOOLS,
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
ASK = [{"role": "user", "content": "Why does a shop keep prices as whole cents? "
                                   "A short Markdown list, with the key word of each item in bold."}]
sofar = ""
was_open = False
with model.messages.stream(model="llama3.2:3b", max_tokens=300, messages=ASK) as stream:
    for n, text in enumerate(stream.text_stream, 1):
        sofar += text
        is_open = sofar.count("**") % 2 == 1
        if is_open != was_open:
            print(f"after {n:3} pieces, bold {'opened' if is_open else 'closed'}: {sofar[-36:]!r}")
            was_open = is_open
print(f"at the end, {n} pieces and {len(sofar)} characters")
PY

block on-screen
on 'python partial.py'
