---
title: Removing it at the source
version: 2
---

The first defence is in the code, where the line is born, and it does not trust every call site to
remember. **A logging filter sits between every call and the formatter**, so it sees every record
every service writes. The shop's, in `services/common/redact.py`:

```schooling-example
{
  "language": "python",
  "file": "services/common/redact.py",
  "parts": [
    {
      "code": "\"\"\"A logging filter that keeps secrets and card numbers out of every line.\"\"\"\nimport logging\nimport re\n\n"
    },
    {
      "code": "CARD = re.compile(r\"\\b(?:\\d[ -]?){12,15}(\\d{4})\\b\")\nSECRET_KEYS = {\"authorization\", \"cookie\", \"password\", \"token\", \"card\"}\n\n\n",
      "note": "**Two lists, written once.** A card number is thirteen to nineteen digits with optional spaces or hyphens, and the last four are kept so a support person can still say *the card ending 1111*. A field whose name is a secret is removed whatever it holds."
    },
    {
      "code": "def clean(value):\n    if isinstance(value, dict):\n        return {k: \"[removed]\" if k.lower() in SECRET_KEYS else clean(v) for k, v in value.items()}\n    if isinstance(value, str):\n        return CARD.sub(r\"**** \\1\", value)\n    return value\n\n\n",
      "note": "Walks dictionaries, so a secret nested inside a header or a body is found, and masks card numbers inside any string, including free text."
    },
    {
      "code": "class Redact(logging.Filter):\n    def filter(self, record):\n        record.fields = clean(getattr(record, \"fields\", {}))\n        record.msg = clean(str(record.msg))\n        return True\n",
      "note": "A logging **filter** runs on every record before the formatter sees it, so every line of every service that sets it up passes through it, whoever wrote the call."
    }
  ]
}
```

Save it, and keep a copy of `logs.py` before the formatter's set-up gains one line and one import:

```sh
cp services/common/logs.py /tmp/logs.py
```

Two lines in the shared `logs.py` install it on the handler, so every service that calls
`logs.setup()` gets it without a change of its own. The storefront is restarted, with its leaky
debug line still in place and `DEBUG` still on, and a checkout carries a second card number hidden in
a free-text note:

```
ana@obs:~/shop$ sed -i 's/^    handler.setFormatter(JsonFormatter())$/&\n    handler.addFilter(redact.Redact())/; s/^from opentelemetry import trace$/&\n\nfrom common import redact/' services/common/logs.py && grep -n 'redact' services/common/logs.py
13:from common import redact
42:    handler.addFilter(redact.Redact())
ana@obs:~/shop$ docker compose restart storefront 2>&1 | tail -1
 Container shop-storefront-1 Started 
ana@obs:~/shop$ curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -H 'Authorization: Bearer sk_live_9f8e7d6c5b4a' -d '{"sku": "kettle", "qty": 1, "card": "4111 1111 1111 1111", "note": "paid with 5500 0000 0000 0004"}'
{"id":2702,"qty":1,"sku":"kettle","status":"paid"}
```

```
ana@obs:~/shop$ curl -sG localhost:3100/loki/api/v1/query_range --data-urlencode 'query={service_name="storefront"} | json | message="request"' --data-urlencode since=5m --data-urlencode limit=1 | jq -r '.data.result[].values[][1]' | jq -c '{auth: .headers.Authorization, body}'
{"auth":"[removed]","body":{"sku":"kettle","qty":1,"card":"[removed]","note":"paid with **** 0004"}}
```

The `Authorization` header and the `card` field are **`[removed]`**, because their names are secrets
whatever their values. The card number typed into the note was caught by its shape and masked to
its last four digits. And the debug line, the leak's cause, is still there: **the filter protects
against the next careless line, not just this one**.

Two limits are worth stating. A filter by field name only knows the names on its list, and a token
in a field called `x_api_credential` passes. A filter by pattern catches what has a shape, card
numbers, and misses what has none, a password. Neither replaces not logging the object in the first
place; both are what stops the day somebody does.
