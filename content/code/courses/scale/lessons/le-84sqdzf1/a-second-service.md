---
title: A second service, and one setup for both
version: 1
---

A trace earns its keep when a request crosses services. The box office so far is one program and a
database, so this lesson gives it a second program: **payments**, a stand-in for the card company
that charges a buyer before the ticket is issued. It answers one route, takes about 20 to 40 ms to
do it, and does nothing else. Lessons 9 and 10 make it slow and make it fail.

Both services set up OpenTelemetry the same way, so that code lives in one file both import. Save it
as `telemetry.py`:

```schooling-example
{"language": "python", "file": "telemetry.py", "parts": [{"code": "# telemetry.py\n\"\"\"One place that sets up OpenTelemetry tracing for every service of the box office.\"\"\"\nimport os\n\nfrom opentelemetry import trace\nfrom opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter\nfrom opentelemetry.sdk.resources import Resource\nfrom opentelemetry.sdk.trace import TracerProvider\nfrom opentelemetry.sdk.trace.export import BatchSpanProcessor", "note": "Four pieces of the OpenTelemetry SDK: the API to get a tracer, the exporter that sends spans over OTLP, the resource that names the service, and the provider that ties them together."}, {"code": "\n\ndef setup(service):\n    provider = TracerProvider(resource=Resource.create({\"service.name\": service}))\n    endpoint = os.environ.get(\"OTLP_ENDPOINT\", \"http://collector:4318\") + \"/v1/traces\"\n    provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint=endpoint)))\n    trace.set_tracer_provider(provider)\n    return trace.get_tracer(service)", "note": "**Called once by each service at start.** Every span it creates carries `service.name`. Spans are collected in batches and sent in the background to the Collector at `OTLP_ENDPOINT`, so a slow Collector never slows a request. Which spans are kept is read from the standard environment variables, which section 10 uses."}]}
```

And the service itself, as `payments.py`:

```schooling-example
{"language": "python", "file": "payments.py", "parts": [{"code": "# payments.py\n\"\"\"payments: a stand-in for the card company, slow on purpose.\"\"\"\nimport json\nimport os\nimport time\nimport zlib\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nfrom opentelemetry import propagate, trace\n\nimport telemetry\n\ntracer = telemetry.setup(\"payments\")\nDELAY_MS = float(os.environ.get(\"PAYMENTS_DELAY_MS\", \"20\"))\n", "note": "The card company's stand-in. It uses the same `telemetry.py`, so its spans go to the same place under the name `payments`. `PAYMENTS_DELAY_MS` is how slow it is; lessons 9 and 10 turn it up."}, {"code": "\nclass Handler(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n    disable_nagle_algorithm = True\n"}, {"code": "    def do_POST(self):\n        body = self.rfile.read(int(self.headers.get(\"Content-Length\", 0)))\n        print(json.dumps({\"message\": \"charge\", \"traceparent\": self.headers.get(\"traceparent\")}),\n              flush=True)\n        context = propagate.extract(self.headers)\n        with tracer.start_as_current_span(\"POST /charges\", context=context,\n                                          kind=trace.SpanKind.SERVER) as span:\n            # the same charge always takes the same time: 1x to 2x the delay\n            jitter = zlib.crc32(body) % 100 / 100\n            time.sleep(DELAY_MS * (1 + jitter) / 1000)\n            span.set_attribute(\"http.response.status_code\", 200)\n            data = json.dumps({\"charged\": True}).encode()\n            self.send_response(200)\n            self.send_header(\"Content-Type\", \"application/json\")\n            self.send_header(\"Content-Length\", str(len(data)))\n            self.end_headers()\n            self.wfile.write(data)\n", "note": "**`propagate.extract` reads the `traceparent` header** the box office sent, and the server span is started inside that context, so it becomes a child of the box office's span, in another process. The line printed first shows the header as it arrived. The pause depends only on the request's body, between one and two times the delay."}, {"code": "    def log_message(self, *args):\n        pass\n\n\nif __name__ == \"__main__\":\n    ThreadingHTTPServer.request_queue_size = 128\n    ThreadingHTTPServer((\"0.0.0.0\", 8001), Handler).serve_forever()"}]}
```

It uses the same image as the box office, so it needs no Dockerfile of its own; `compose.yaml`
starts it with a different command, in section 06.

## What the context carries

The essential line of `payments.py` is `propagate.extract(self.headers)`. The box office, when it
calls payments, writes the identity of its current span into a header of the request; payments reads
it and starts its own span **as a child of that one**. Neither process knows anything about the
other's spans; they agree only on the header. Section 08 looks at it byte by byte.
