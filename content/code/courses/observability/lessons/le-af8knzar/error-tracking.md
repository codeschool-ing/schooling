---
title: What an error tracker records
version: 1
---

An error tracker is the oldest of these products' ideas and the narrowest. **It records exceptions,
not requests**, and it records each one with far more around it than a log line or a span carries.
Sentry's SDK is the example here because it is open source and installs like any library. The script
reports one exception the way a service would, except that its transport writes the event to a file
instead of sending it:

```schooling-example
{
  "language": "python",
  "file": "scratch/tracked.py",
  "parts": [
    {
      "code": "\"\"\"An error reported the way an error tracker's SDK reports it.\n\nThe DSN names a project and points nowhere; the transport writes each event\nto event.json instead of sending it.\n\"\"\"\nimport json\nimport logging\n\nimport sentry_sdk\nfrom sentry_sdk.transport import Transport\n\n\n"
    },
    {
      "code": "class ToFile(Transport):\n    def capture_envelope(self, envelope):\n        for item in envelope.items:\n            if item.type == \"event\":\n                with open(\"event.json\", \"w\") as f:\n                    json.dump(item.payload.json, f, indent=1)\n\n\n",
      "note": "A **transport** is the part of the SDK that sends. This one writes each event to a file instead, so the lesson can read exactly what would have crossed the wire."
    },
    {
      "code": "sentry_sdk.init(\n    dsn=\"https://key@errors.example.invalid/1\",\n    transport=ToFile,\n    release=\"shop@1.4.0\",\n    environment=\"lab\",\n)\n",
      "note": "The **DSN** names the project an event belongs to and carries its key; this one points at a domain that cannot exist. `release` and `environment` travel with every event, which is what lets the product say *this error began in 1.4.0*."
    },
    {
      "code": "logging.basicConfig(level=logging.INFO)\nlog = logging.getLogger(\"checkout\")\n\n",
      "note": "The SDK hooks into `logging` on its own: every record at `INFO` and above becomes a **breadcrumb**, kept in memory and sent only if an error follows."
    },
    {
      "code": "COUPONS = {\"WELCOME10\": 10, \"FRIEND15\": 15}\n\n\ndef apply_coupon(total_cents, coupon):\n    return total_cents * (100 - COUPONS[coupon]) // 100\n\n\ndef checkout(sku, qty, card, coupon):\n    sentry_sdk.set_tag(\"sku\", sku)\n    log.info(\"pricing %s x %d\", sku, qty)\n    total_cents = 4900 * qty\n    log.info(\"applying coupon %s\", coupon)\n    return apply_coupon(total_cents, coupon)\n\n\n",
      "note": "An ordinary bug: a coupon nobody defined raises `KeyError`. `set_tag` adds an indexed field to the event, searchable in the product like a label."
    },
    {
      "code": "try:\n    checkout(\"kettle\", 2, \"4111 1111 1111 1111\", \"WELCOME20\")\nexcept KeyError:\n    sentry_sdk.capture_exception()\nsentry_sdk.flush()\n",
      "note": "`capture_exception` reports the exception being handled; an unhandled one is reported without it. `flush` waits for the transport before the script exits."
    }
  ]
}
```

```
ana@obs:~/shop$ docker compose run --rm sandbox python tracked.py
 Container shop-otel-collector-1 Running 
 Container shop-sandbox-run-19321cd586d2 Creating 
 Container shop-sandbox-run-19321cd586d2 Created 
INFO:checkout:pricing kettle x 2
INFO:checkout:applying coupon WELCOME20
```

The two `INFO` lines are the logging the script does. The event the SDK built is in `event.json`,
and the parts worth reading:

```
ana@obs:~/shop$ jq '{level, release, environment, tags, exception: [.exception.values[] | {type, value, frames: [.stacktrace.frames[] | select(.function != "<module>") | {function, lineno, vars}]}], breadcrumbs: [.breadcrumbs.values[] | .message]}' scratch/event.json
{
  "level": "error",
  "release": "shop@1.4.0",
  "environment": "lab",
  "tags": {
    "sku": "kettle"
  },
  "exception": [
    {
      "type": "KeyError",
      "value": "'WELCOME20'",
      "frames": [
        {
          "function": "checkout",
          "lineno": 42,
          "vars": {
            "sku": "'kettle'",
            "qty": "2",
            "card": "'4111 1111 1111 1111'",
            "coupon": "'WELCOME20'",
            "total_cents": "9800"
          }
        },
        {
          "function": "apply_coupon",
          "lineno": 34,
          "vars": {
            "total_cents": "9800",
            "coupon": "'WELCOME20'"
          }
        }
      ]
    }
  ],
  "breadcrumbs": [
    "pricing kettle x 2",
    "applying coupon WELCOME20"
  ]
}
```

Four things in it that no signal in this course has carried so far:

- **The stack, with every frame's local variables.** `apply_coupon` was called with `'WELCOME20'`,
  a coupon `COUPONS` does not have, and the frame above it says from where. A log line would have
  said `KeyError: 'WELCOME20'` and left the rest to be reproduced.
- **Breadcrumbs.** The log lines that came before the error, kept in memory and sent only now. They
  cost nothing on the thousands of requests that do not fail.
- **The release.** Every event names the version it came from, so the product can say when an error
  first appeared and whether the release that claimed to fix it did.
- **A level and tags**, which make it searchable as an issue rather than as text.

What the event does not show is the most useful thing the product does with it. **The server groups
events into issues** by their stack, so ten thousand of this error are one line on a screen, with a
count, a first and last time seen, and the releases it appeared in. Grouping by stack is why an
error tracker is quieter than a log search. It is also why it is wrong in a recognisable way: one
bug raised from two places is two issues, and two bugs raised from one helper are one.

And there is a line in the output that should not be there. The next section is about it.
