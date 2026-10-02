---
title: From the model to a browser
version: 1
---

A page in a browser cannot call the model's API itself: **the request would need the API key, and
anything sent to a browser can be read by whoever is using it**. So a server of yours sits in
between. It holds the key, makes the streamed request, and passes the pieces on to the browser as
they arrive, in a stream of its own.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 160\" role=\"img\" aria-label=\"Three parties. The browser sends a question to your relay and reads the relay&#x27;s own events: text, done, error. The relay holds the API key, makes the streamed request to the model&#x27;s API and passes each piece on. The key never leaves the server.\"><defs><marker id=\"ry-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the browser</text><text x=\"95.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the page</text><rect x=\"285\" y=\"50\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">your relay</text><text x=\"360.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">holds the key</text><rect x=\"550\" y=\"50\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the model&#x27;s API</text><text x=\"625.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the provider</text><path d=\"M172 66 L283 66\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ry-ah)\"></path><text x=\"228\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">question</text><path d=\"M283 96 L172 96\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ry-ah)\"></path><text x=\"228\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">text, done, error</text><path d=\"M437 66 L548 66\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ry-ah)\"></path><text x=\"492\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">streamed request + key</text><path d=\"M548 96 L437 96\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ry-ah)\"></path><text x=\"492\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">server-sent events</text></svg>", "caption": "The key stays on your server. The page sees your events, not the provider's."}
```

## The relay

```schooling-example
{
  "language": "python",
  "file": "relay.py",
  "parts": [
    {
      "code": "\"\"\"A relay between a browser and the model: the key stays here, the words go through.\"\"\"\nimport json\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport anthropic\n\n"
    },
    {
      "code": "model = anthropic.Anthropic()\n\n\n",
      "note": "**The key is read here, on the server**, from the environment; it never reaches the page."
    },
    {
      "code": "class Relay(BaseHTTPRequestHandler):\n    def send_event(self, name, data):\n        self.wfile.write(f\"event: {name}\\ndata: {json.dumps(data)}\\n\\n\".encode())\n        self.wfile.flush()\n\n",
      "note": "**One event, written and flushed at once.** Without the flush, the pieces wait in a buffer and the page sees them in bursts."
    },
    {
      "code": "    def do_POST(self):\n        question = json.loads(self.rfile.read(int(self.headers[\"Content-Length\"])))[\"question\"]\n        self.send_response(200)\n        self.send_header(\"Content-Type\", \"text/event-stream\")\n        self.send_header(\"Cache-Control\", \"no-cache\")\n        self.end_headers()\n",
      "note": "**The response starts before the answer exists**: status, content type and headers go out first."
    },
    {
      "code": "        try:\n            with model.messages.stream(model=\"scripted-1\", max_tokens=300,\n                                       messages=[{\"role\": \"user\", \"content\": question}]) as stream:\n                for text in stream.text_stream:\n                    self.send_event(\"text\", {\"text\": text})\n            self.send_event(\"done\", {\"stop_reason\": stream.get_final_message().stop_reason})\n",
      "note": "**Each piece from the model becomes one event for the page**, and the end becomes `done`."
    },
    {
      "code": "        except anthropic.APIError as e:\n            self.send_event(\"error\", {\"message\": \"the answer stopped halfway; please ask again\"})\n            self.log_error(\"model stream failed: %s\", e)\n\n",
      "note": "**A failure halfway becomes an `error` event**, with a sentence for a person; the provider's detail goes to the server's log."
    },
    {
      "code": "    def log_message(self, *args):\n        pass\n\n\n"
    },
    {
      "code": "ThreadingHTTPServer((\"127.0.0.1\", 8500), Relay).serve_forever()",
      "note": "**One thread per request**, so two pages can stream at once."
    }
  ]
}
```

Started in the background, asked with `curl`, stopped with `kill`:

```
ana@dev:~/shop$ python relay.py & sleep 1; curl -sN -X POST localhost:8500/ask -d '{"question": "Say hello in five words."}'; kill $!
event: text
data: {"text": "Hello"}

event: text
data: {"text": " from"}

event: text
data: {"text": " the"}

event: text
data: {"text": " shop"}

event: text
data: {"text": "'s"}

event: text
data: {"text": " assistant"}

event: text
data: {"text": "."}

event: done
data: {"stop_reason": "end_turn"}

```

**The relay's events are its own**, smaller than the provider's: `text`, `done` and `error`. The
browser does not need to know which provider is behind the relay, or that one exists, and the
relay can change provider without changing the page.

## The page's side

A browser has two ways to read a stream. `EventSource` is built for server-sent events but sends
only `GET` requests, with no body. `fetch` can `POST` a question and read the response as it
arrives. This is the `fetch` version, run with Node, whose `fetch` is the same API a browser has:

```schooling-example
{
  "language": "javascript",
  "file": "client.mjs",
  "parts": [
    {
      "code": "// What a browser page does with the relay, run here with Node's fetch, which is the same API.\n"
    },
    {
      "code": "const response = await fetch(\"http://127.0.0.1:8500/ask\", {\n  method: \"POST\",\n  headers: { \"Content-Type\": \"application/json\" },\n  body: JSON.stringify({ question: process.argv[2] }),\n});\n",
      "note": "**`fetch` can send a question in the body**, which `EventSource` cannot."
    },
    {
      "code": "const reader = response.body.pipeThrough(new TextDecoderStream()).getReader();\nlet buffer = \"\";\nlet shown = \"\";\nfor (;;) {\n  const { value, done } = await reader.read();\n  if (done) break;\n",
      "note": "**The body is read as it arrives**, decoded from bytes to text on the way."
    },
    {
      "code": "  buffer += value;\n  const events = buffer.split(\"\\n\\n\");\n  buffer = events.pop();\n",
      "note": "**An event ends at a blank line.** Whatever follows the last one is half an event, kept for the next read."
    },
    {
      "code": "  for (const raw of events) {\n    const name = raw.match(/^event: (.*)$/m)[1];\n    const data = JSON.parse(raw.match(/^data: (.*)$/m)[1]);\n    if (name === \"text\") shown += data.text;\n    if (name === \"done\") console.log(`${shown}\\n[done: ${data.stop_reason}]`);\n    if (name === \"error\") console.log(`${shown}\\n[error: ${data.message}]`);\n  }\n}",
      "note": "**Each complete event is acted on**: text is appended, `done` and `error` end the reply."
    }
  ]
}
```

```
ana@dev:~/shop$ python relay.py & sleep 1; node client.mjs "Explain in a paragraph why the cart stores prices in cents."; kill $!
The cart stores prices as integer cents because a float cannot hold most decimal amounts exactly. In binary floating point, 0.1 plus 0.2 is not 0.3, and a total built from many such sums drifts by a cent here and there. Integers add exactly, so the cart adds cents and formats them only at the edge, when it prints a price for a person.
[done: end_turn]
```

In a page, `shown` would go into an element on every `text` event instead of being printed at the
end. **The buffer is the part people leave out.** A network read can end in the middle of an event,
so the code keeps whatever follows the last blank line and waits for the rest.

## What the relay must also do

- **Check who is asking.** The relay spends money on every question. One open to anyone on the
  internet is an API key with extra steps.
- **Limit the question.** Its length, and how often one user may ask. The key's limits from lesson
  2 apply to all users together, so one user can use up everyone's.
- **Turn off buffering on the way.** A proxy or a framework that collects the response before
  sending it gives the browser the whole reply at once, and the stream is gone without an error.
  `Cache-Control: no-cache` is the start; some proxies need their own header too.
