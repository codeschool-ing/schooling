---
title: Deploying is not releasing
version: 2
---

Everything so far tied two things together: putting new code in production and showing it to
customers. A **feature flag** separates them. The code for a feature is deployed, but a switch read
at run time decides who sees it, and the switch starts off.

Version 1.6.1 fixed the error, and Ana took one more precaution: the delivery estimate, the new
field in the quote, is now behind a flag.

```schooling-example
{
  "language": "python",
  "file": "shipquote/flags.py",
  "parts": [
    {
      "code": "def load():\n    path = os.environ.get(\"SHIPQUOTE_FLAGS\")\n    if not path or not os.path.exists(path):\n        return {}\n    with open(path) as f:\n        return json.load(f)",
      "note": "The flags live in a file named by `SHIPQUOTE_FLAGS`, read on every request. No file means no flags, and every feature behind one stays off."
    },
    {
      "code": "def enabled(flags, name, customer):\n    \"\"\"On for the flag's percentage of customers, the same ones every time.\"\"\"\n    bucket = int(hashlib.sha256(f\"{name}:{customer}\".encode()).hexdigest(), 16) % 100\n    return bucket < flags.get(name, 0)",
      "note": "A customer gets a bucket from 0 to 99, from a hash of the flag's name and the customer's id. The feature is on for buckets below the flag's percentage. The same customer always lands in the same bucket, so they see the same thing on every request."
    }
  ]
}
```

The quote handler adds the estimate only when the flag says so:

```python
        customer = args.get("customer", [""])[0]
        try:
            body = self.quote_body(cep, cents)
            if flags.enabled(flags.load(), "delivery_estimate", customer):
                body["days"] = quote.delivery_days(cep)
```

Green gets 1.6.1, and this time takes all the traffic at once. There is no flags file yet:

```
ana@laptop:~/shipquote$ ops/deploy.sh production-green dist/shipquote-1.6.1.tar.gz
smoke: http://127.0.0.1:8302 is up and running 1.6.1
ana@laptop:~/shipquote$ sed -i 's/"blue": 100, "green": 0/"blue": 0, "green": 100/' ~/envs/routes.json
ana@laptop:~/shipquote$ python3 ops/load.py http://127.0.0.1:8300 2000
backend    requests errors    rate
green          2000      0    0.0%
ana@laptop:~/shipquote$ ls ~/envs/flags.json
ls: cannot access '/home/ana/envs/flags.json': No such file or directory
ana@laptop:~/shipquote$ curl -s "http://127.0.0.1:8300/quote?cep=57020-050&weight=700&subtotal=8990&customer=c7"; echo
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40"}
```

Two thousand requests, no errors, and a quote that looks exactly like 1.5.0's: no `days`. The new
code is in production and running, and **no customer has seen it**. This is sometimes called a
**dark launch**.

## Why bother

- **The deploy becomes boring.** It changes nothing a customer sees, so it can happen at any hour,
  as often as the pipeline produces releases. The risky moment moves to the flag, which is a small,
  separate change.
- **Releasing becomes somebody else's decision.** A product manager can turn a feature on for a
  launch date without a deploy, and turn it off without a rollback.
- **Unfinished work can be merged.** A feature that needs three weeks can go to the main branch every
  day, off, instead of living on a branch that drifts away from everything else. That is how a team
  that merges the day a change is written, as lesson 5 asked, copes with a change that takes weeks.

The price is that the code now contains both paths, the old behaviour and the new, until somebody
removes one. Section 13 is about that price.
