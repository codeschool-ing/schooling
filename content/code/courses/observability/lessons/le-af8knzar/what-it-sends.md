---
title: What the SDK sends without asking
version: 2
---

Look again at the frame of `checkout` above: **`"card": "'4111 1111 1111 1111'"`**. Nobody wrote the
card number into the event. The SDK collects every local variable of every frame by default,
because that is what makes the event useful, and the card number was a local variable.

This is lesson 10's leak by another road. There the card number reached the logs because a debug
line logged a whole object. Here it reaches a third party's servers because an exception happened in
a function that had it in scope. **An error tracker's default is to send more than you would think
to write.** The SDK does scrub some names by default, `password`, `token`, `authorization`, `cookie`
and about thirty others in all, and replaces their values with `[Filtered]`. `card` is not on the
list, and nor is any name your own code invented.

The fix is the same shape as lesson 10's: a list of names whose values are secrets, applied before
anything leaves. Here it is one argument to `init`, and the import it needs. The whole
file again, with those two lines added:

`~/shop/scratch/tracked.py`

```python
"""An error reported the way an error tracker's SDK reports it.

The DSN names a project and points nowhere; the transport writes each event
to event.json instead of sending it.
"""
import json
import logging

import sentry_sdk
from sentry_sdk.scrubber import DEFAULT_DENYLIST, EventScrubber
from sentry_sdk.transport import Transport


class ToFile(Transport):
    def capture_envelope(self, envelope):
        for item in envelope.items:
            if item.type == "event":
                with open("event.json", "w") as f:
                    json.dump(item.payload.json, f, indent=1)


sentry_sdk.init(
    dsn="https://key@errors.example.invalid/1",
    transport=ToFile,
    release="shop@1.4.0",
    environment="lab",
    event_scrubber=EventScrubber(denylist=DEFAULT_DENYLIST + ["card"]),
)
logging.basicConfig(level=logging.INFO)
log = logging.getLogger("checkout")

COUPONS = {"WELCOME10": 10, "FRIEND15": 15}


def apply_coupon(total_cents, coupon):
    return total_cents * (100 - COUPONS[coupon]) // 100


def checkout(sku, qty, card, coupon):
    sentry_sdk.set_tag("sku", sku)
    log.info("pricing %s x %d", sku, qty)
    total_cents = 4900 * qty
    log.info("applying coupon %s", coupon)
    return apply_coupon(total_cents, coupon)


try:
    checkout("kettle", 2, "4111 1111 1111 1111", "WELCOME20")
except KeyError:
    sentry_sdk.capture_exception()
sentry_sdk.flush()
```

The `init` call, as the file now has it:

```
ana@obs:~/shop$ sed -n '/^sentry_sdk.init/,/^)/p' scratch/tracked.py
sentry_sdk.init(
    dsn="https://key@errors.example.invalid/1",
    transport=ToFile,
    release="shop@1.4.0",
    environment="lab",
    event_scrubber=EventScrubber(denylist=DEFAULT_DENYLIST + ["card"]),
)
```

```
ana@obs:~/shop$ docker compose run --rm sandbox python tracked.py 2>&1 | tail -2
INFO:checkout:pricing kettle x 2
INFO:checkout:applying coupon WELCOME20
ana@obs:~/shop$ jq '.exception.values[0].stacktrace.frames[] | select(.function == "checkout") | .vars' scratch/event.json
{
  "sku": "'kettle'",
  "qty": "2",
  "card": "[Filtered]",
  "coupon": "'WELCOME20'",
  "total_cents": "9800"
}
```

Three habits keep this from being a list somebody remembers to extend:

- **Scrub on the way out, and again on arrival.** The products also scrub on the server, by
  pattern, and have options to drop local variables entirely. Use both; the SDK's list protects the
  network and the vendor's copy, and the server's list catches what the SDK's missed.
- **Keep `send_default_pii` off**, as it is by default. Turned on, it adds the user's IP address,
  cookies and request headers to every event, and session cookies are on lesson 10's list of things
  never to write down.
- **Treat the vendor as a place the data goes.** An event stored in a vendor's region abroad is a
  transfer of personal data under the LGPD, with the obligations that come with one. Most products
  offer a European or local region and a contract for it, and the choice belongs in the evaluation,
  not in the incident.
