---
title: The shop's formatter, line by line
version: 1
---

Every service of the shop logs through the same forty-odd lines, a formatter for Python's standard
`logging` module. Python's logging, like most languages' logging libraries, separates **what is
logged**, the call `log.info(...)` in the code, from **how it is written**, a formatter attached to
a handler at start-up. That is the same split lesson 2 found in OpenTelemetry, and it means the
shop's services call the standard library and never mention JSON:

```schooling-example
{
  "language": "python",
  "file": "common/logs.py",
  "parts": [
    {
      "code": "\"\"\"One JSON object per line on stdout: how every service of the shop logs.\n\nThe platform collects stdout; nothing here knows where the lines end up.\n\"\"\"\nimport json\nimport logging\nimport os\nimport sys\nfrom datetime import datetime, timezone\n\nfrom opentelemetry import trace\n\nSERVICE = os.environ.get(\"OTEL_SERVICE_NAME\", \"unknown\")\n\n\n",
      "note": "**Standard output and nothing else.** The service does not know about files, rotation, Loki or the Collector; the platform collects what it prints. The service's name comes from the same variable its traces use."
    },
    {
      "code": "class JsonFormatter(logging.Formatter):\n    def format(self, record):\n        line = {\n            \"time\": datetime.fromtimestamp(record.created, timezone.utc)\n            .isoformat(timespec=\"milliseconds\")\n            .replace(\"+00:00\", \"Z\"),\n            \"level\": record.levelname,\n            \"service\": SERVICE,\n            \"logger\": record.name,\n            \"message\": record.getMessage(),\n        }\n",
      "note": "The fields every line has: a time in UTC with milliseconds, the level, the service, the logger, and a message that is **the same text for the same kind of event**, so it can be counted."
    },
    {
      "code": "        ctx = trace.get_current_span().get_span_context()\n        if ctx.is_valid:\n            line[\"trace_id\"] = format(ctx.trace_id, \"032x\")\n            line[\"span_id\"] = format(ctx.span_id, \"016x\")\n",
      "note": "**Correlation**: if a span is current, its ids go into the line. This is the join between logs and traces from lesson 1."
    },
    {
      "code": "        line.update(getattr(record, \"fields\", {}))\n        if record.exc_info:\n            line[\"exception\"] = self.formatException(record.exc_info)\n        return json.dumps(line)\n\n\n",
      "note": "The event's own values, passed as `extra={\"fields\": {...}}`, become fields of their own; an exception's traceback becomes one field, inside the same line."
    },
    {
      "code": "def setup(level=None):\n    handler = logging.StreamHandler(sys.stdout)\n    handler.setFormatter(JsonFormatter())\n    root = logging.getLogger()\n    root.handlers[:] = [handler]\n    root.setLevel(level or os.environ.get(\"LOG_LEVEL\", \"INFO\"))\n    logging.getLogger(\"waitress\").setLevel(logging.WARNING)\n    logging.getLogger(\"pika\").setLevel(logging.CRITICAL)\n    return logging.getLogger(SERVICE)",
      "note": "The level comes from the environment, `INFO` unless `LOG_LEVEL` says otherwise. Two chatty libraries are turned down here, once, rather than filtered later at a cost."
    }
  ]
}
```

A call in the storefront, then, looks like this:

```python
        log.info("checkout finished", extra={"fields": {
            "sku": sku, "order_id": order.get("id"), "outcome": order.get("status")}})
```

The message is a fixed phrase and the values are fields. **The message never interpolates a
value**: `"checkout finished"` is the same string for every checkout, which is what lets lesson 9
count them by message. The order number is in `order_id`, where it can be searched without
parsing a sentence.

Writing to standard output is a decision with a name, from the *twelve-factor app* principles: a
service treats its logs as a stream and leaves collecting them to whatever runs it. In this lab
Docker hands each line to the Collector; in Kubernetes the node's agent reads the container's
output; on a laptop it is the terminal. **The service's code is the same in all three**, and it
never fills a disk with a file nobody rotates.
