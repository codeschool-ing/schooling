---
title: Turning a feature on for some customers
version: 1
---

The flags file is created with the feature at 10%. No deploy, no restart: `flags.load()` reads the
file on the next request.

```
ana@laptop:~/shipquote$ echo '{"delivery_estimate": 10}' > ~/envs/flags.json
ana@laptop:~/shipquote$ for c in c1 c2 c3 c4 c5 c6 c7 c8; do curl -s "http://127.0.0.1:8300/quote?cep=57020-050&weight=700&subtotal=8990&customer=$c"; echo; done
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40"}
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40"}
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40", "days": 4}
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40"}
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40", "days": 4}
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40"}
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40"}
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40"}
ana@laptop:~/shipquote$ for i in $(seq 1000); do curl -s "http://127.0.0.1:8300/quote?cep=01310-100&weight=800&customer=c$i"; echo; done | grep -c days
110
```

Of eight customers, two, `c3` and `c5`, now see `"days": 4`. Over a thousand customers, 110 see it:
close to 10%, and not exactly, because a hash spreads customers evenly over the buckets only on
average.

Then to 50%:

```
ana@laptop:~/shipquote$ echo '{"delivery_estimate": 50}' > ~/envs/flags.json
ana@laptop:~/shipquote$ for i in $(seq 1000); do curl -s "http://127.0.0.1:8300/quote?cep=01310-100&weight=800&customer=c$i"; echo; done | grep -c days
503
ana@laptop:~/shipquote$ for c in c3 c3 c3; do curl -s "http://127.0.0.1:8300/quote?cep=57020-050&weight=700&subtotal=8990&customer=$c"; echo; done
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40", "days": 4}
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40", "days": 4}
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40", "days": 4}
```

503 of a thousand. And `c3`, asked three times, gets the estimate every time.

## Two properties that matter

- **The same customer gets the same answer.** The bucket comes from a hash of the customer's id, not
  from a random draw on each request. A customer who saw delivery estimates a minute ago still sees
  them; a random draw would show the field and hide it on alternate refreshes.
- **Widening keeps everybody who was already in.** A customer is in when their bucket is below the
  percentage. Going from 10 to 50 adds buckets 10 to 49; buckets 0 to 9 are still below 50. So `c3`
  and `c5`, in at 10%, are still in at 50%, and nobody who had the feature loses it as it spreads.

The flag's name goes into the hash with the customer's id. Without it, every flag at 10% would pick
the same 10% of customers, and that unlucky tenth would be the test group for every experiment the
shop ever ran.

## A canary for a feature

This is a canary, moved from the router into the code. The difference is what it isolates: the
router's canary tests a whole release, everything that changed in it; the flag tests one feature,
whatever else the release contains. Both need the same thing to be useful, a measurement split by
which group a customer was in, compared between the groups.
