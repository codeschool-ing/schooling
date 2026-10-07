---
title: Checking a webhook properly
version: 1
---

**A webhook is a request a service sends to your server when something happens, and your server
must treat it as hostile until its signature checks out.** The URL is public, or at least
guessable; anybody on the internet can post JSON to it. The HMAC is the only thing that separates
the gateway's messages from everybody else's.

## The header the gateway sends

Each delivery carries a header beside the body. The lab keeps it in a `.sig` file, as `vcrypt
deliveries` wrote it:

```
ana@lab:~/lab$ cat data/webhooks/evt-1.sig
t=1781535558,v1=6c7cdc5299209a4260988b908954ed6dcd8c3809dff59fa053eb98a6114ab61f
```

Two fields. `t` is when the gateway signed, in seconds since 1970, and `v1` is the HMAC-SHA256 tag.
What the gateway signs is not the body alone but **the timestamp, a full stop and the body**. The
tag can be recomputed by hand from those three pieces, and it matches:

```
ana@lab:~/lab$ printf '%s.' 1781535558 | cat - data/webhooks/evt-1.json | openssl dgst -sha256 -mac HMAC -macopt hexkey:$(cat keys/webhook.hex) -r
6c7cdc5299209a4260988b908954ed6dcd8c3809dff59fa053eb98a6114ab61f *stdin
```

That is the same scheme most payment gateways and many SaaS products use, with small differences
in the header's name. Their documentation always says exactly which bytes are signed, and getting
that wrong is the usual reason a correct implementation rejects every message.

## Four deliveries

The lab holds four deliveries, and `vcrypt webhook` checks each one the way the portal should, with
the receiver's clock passed as `--now`. Its `verify()` is the whole defence, four checks in order:

```py
# ~/lab/tools/webhook.py
"""vcrypt webhook --key KEYFILE --now EPOCH EVENT.json...: check each delivery
against the header kept beside it in EVENT.sig, as a receiver whose clock
says EPOCH would."""
import argparse
import hashlib
import hmac

TOLERANCE = 300  # seconds a delivery may be late before it is treated as a replay


def verify(key: bytes, header: str, body: bytes, now: int):
    """(accepted, why)"""
    try:
        fields = dict(part.split("=", 1) for part in header.strip().split(","))
        timestamp, received = int(fields["t"]), fields["v1"]
    except (ValueError, KeyError):
        return False, "no signature header in the expected form"
    expected = hmac.new(key, str(timestamp).encode() + b"." + body, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, received):
        return False, "signature does not match the body"
    if abs(now - timestamp) > TOLERANCE:
        return False, f"signed {now - timestamp} s ago, outside the {TOLERANCE} s window"
    return True, "signature valid, timestamp within the window"


p = argparse.ArgumentParser(prog="vcrypt webhook")
p.add_argument("--key", required=True)
p.add_argument("--now", type=int, required=True, help="the receiver's clock, in epoch seconds")
p.add_argument("events", nargs="+")
a = p.parse_args()
key = bytes.fromhex(open(a.key).read().strip())
for path in a.events:
    body = open(path, "rb").read()
    header = open(path[:-len(".json")] + ".sig").read()
    ok, why = verify(key, header, body, a.now)
    print(f"{path.split('/')[-1]:<12} {'ACCEPT' if ok else 'REJECT'}  {why}")
```

On the four deliveries:

```
ana@lab:~/lab$ vcrypt webhook --key keys/webhook.hex --now 1781535600 data/webhooks/*.json
evt-1.json   ACCEPT  signature valid, timestamp within the window
evt-2.json   REJECT  signature does not match the body
evt-3.json   REJECT  signed 86400 s ago, outside the 300 s window
evt-4.json   REJECT  signature does not match the body
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"The receiver&#x27;s checks on a webhook, in order. First, parse the header into t and v1; a missing or malformed header is rejected. Second, recompute HMAC-SHA256 with the shared key over t, a full stop and the raw body. Third, compare with v1 in constant time; a mismatch is rejected, which catches evt-2 and evt-4. Fourth, check that t is within 300 seconds of the receiver&#x27;s clock; outside it is a replay, which catches evt-3. Only then parse the JSON and act, as with evt-1.\"><defs><marker id=\"wh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"wh-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"360\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1  read t and v1 from the header</text><polyline points=\"220,56 220,72\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#wh-ah-wire)\"></polyline><polyline points=\"400,38 488,38\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#wh-ah-amber)\"></polyline><rect x=\"490\" y=\"20\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"506\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">REJECT: malformed</text><rect x=\"40\" y=\"74\" width=\"360\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2  HMAC-SHA256(key, t + &quot;.&quot; + raw body)</text><polyline points=\"220,110 220,126\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#wh-ah-wire)\"></polyline><rect x=\"40\" y=\"128\" width=\"360\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3  compare with v1, in constant time</text><polyline points=\"220,164 220,180\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#wh-ah-wire)\"></polyline><polyline points=\"400,146 488,146\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#wh-ah-amber)\"></polyline><rect x=\"490\" y=\"128\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"506\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">REJECT: evt-2, evt-4</text><rect x=\"40\" y=\"182\" width=\"360\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4  |now - t| at most 300 s</text><polyline points=\"220,218 220,234\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#wh-ah-wire)\"></polyline><polyline points=\"400,200 488,200\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#wh-ah-amber)\"></polyline><rect x=\"490\" y=\"182\" width=\"200\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"506\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">REJECT: evt-3, a replay</text><rect x=\"40\" y=\"236\" width=\"360\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">5  parse the JSON and act</text><text x=\"506\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">evt-1: ACCEPT</text></svg>", "caption": "Every check before the first one that reads the body's fields."}
```

- **evt-1** is genuine and arrived 42 seconds after it was signed. Accepted.
- **evt-2** had its amount changed after signing. The tag no longer matches the body. Rejected.
- **evt-3** is evt-1 again, byte for byte, with its original and perfectly valid tag, delivered a
  day later. The signature is fine; the timestamp is not. Rejected as a replay.
- **evt-4** was signed, but with a key that is not the gateway's. Rejected, with the same reason as
  evt-2: from the receiver's side, a wrong key and a changed body look the same.

## Why the timestamp is inside the signature

Without the timestamp, evt-3 would be accepted: a valid message stays valid forever, so whoever
recorded one "payment confirmed" could send it again whenever they liked. Putting `t` **inside** the
signed bytes means it cannot be changed without breaking the tag, and rejecting anything signed more
than five minutes ago closes the window. Five minutes allows for clocks that disagree a little and
for the gateway's retries. Stricter systems also remember the ids of the events they have processed
and refuse a repeat inside the window, which is the complete defence against replay.

## The comparison itself

The last step, comparing the computed tag with the received one, has to be **constant-time**. An
ordinary comparison returns at the first different character, so a request whose tag starts with
the right character takes slightly longer to refuse than one that does not. Over many requests,
that difference can be measured, and it would let somebody find a valid tag one character at a time
without the key. `hmac.compare_digest` in Python and `crypto/subtle.ConstantTimeCompare` in Go take
the same time whatever the inputs; `verify()` in `webhook.py` uses the first. Here, unlike with
password hashes, the attacker chooses the input, so this is not optional.

The order of the checks matters as well: verify the tag **before** parsing the JSON or acting on
any field in it. A parser fed by an unauthenticated stranger is attack surface, and a handler that
reads the amount before checking the tag has already trusted it.
