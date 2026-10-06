---
title: The seam where a double goes in
version: 1
---

Lesson 1 tested code that only did arithmetic. Most code also talks to things a test should not
touch: a carrier's API that charges per call, an SMTP server that sends real e-mail, a clock that
moves. A **test double** is an object that stands in for one of those collaborators during a test,
the way a stunt double stands in for an actor. The five kinds this lesson names, dummy, stub, spy,
mock and fake, differ in what the stand-in does.

None of them can be used unless the code has a **seam**: a place where the collaborator is handed
in rather than reached for. Compare two ways `price` could get its carrier:

```python
def price(cep, weight_g, subtotal_cents):            # reaches for it
    carrier = CarrierClient("https://api.carrier.example", TOKEN)
    ...

def price(carrier, cep, weight_g, subtotal_cents):   # is handed it
    ...
```

The first builds its own client inside the function, so every call goes to the network, and a
test has no way to say "pretend the carrier answered 1999". The second takes the carrier as an
argument, and the test can pass anything with a `rate` method. That is the whole trick, and it has
a grand name, **dependency injection**, for something as plain as an extra parameter.

## shipquote's seams

`shipquote/carrier.py` has three, and each one is there for a test:

```schooling-example
{
  "language": "python",
  "file": "shipquote/carrier.py",
  "parts": [
    {
      "code": "class CarrierClient:\n    def __init__(self, base_url, token, timeout=2.0,\n                 opener=urllib.request.urlopen):\n        self.base_url = base_url.rstrip(\"/\")\n        self.token = token\n        self.timeout = timeout\n        self.opener = opener",
      "note": "`opener` is how the client sends a request. In production it is `urllib.request.urlopen`; a test can pass a function that returns a canned answer without opening a socket."
    },
    {
      "code": "def price(carrier, cep, weight_g, subtotal_cents, log=print):\n    \"\"\"The carrier's price when it answers, the table's when it does not.\"\"\"\n    if subtotal_cents >= quote.FREE_FROM:\n        return 0\n    try:\n        return carrier.rate(quote.normalise_cep(cep), weight_g)\n    except CarrierError as e:\n        log(f\"carrier unavailable, using the table: {e}\")\n        return quote.freight(cep, weight_g, subtotal_cents)",
      "note": "`price` takes the `carrier` as its first argument, so a test chooses what the carrier says. `log` defaults to `print`, and a test can pass something that collects the lines instead."
    }
  ]
}
```

`orders.place` is built the same way: it receives `orders`, where the order is stored, and
`mailer`, which sends the confirmation. Neither is created inside it.

## The cost of a seam

A parameter that only tests use is a small price, and it buys more than tests. **A seam is also
where production swaps an implementation**: the same `price` works with a real carrier, a second
carrier, or a cached one, without being edited. Code that is hard to test because it reaches for
its collaborators is usually hard to change for the same reason.

The alternative, when a seam is missing and cannot be added, is **patching**: replacing a name
inside a module while the test runs. It works and it has a trap, which section 09 springs on
purpose. Prefer the seam; patch when you cannot change the code.
