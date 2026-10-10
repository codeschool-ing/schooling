---
title: Quotas, costs and tiers
version: 1
---

**A rate limit and a quota answer different questions, and an API usually needs both.** The rate
limit is about the next few seconds: how fast may this client go. The quota is about the day or the
month: how much may it use in total. A client that keeps exactly to one request a second never
trips the bucket, and sends 86,400 requests a day.

| | rate limit | quota |
|---|---|---|
| period | seconds or minutes | a day, a month |
| protects | the service, right now | the budget, and the plan the client paid for |
| refilled | continuously | all at once, when the period starts again |
| in `limits.py` | the bucket, `burst` | a fixed window a day long, `daily` |

`limits.py` checks the quota before the bucket and spends from both only when both say yes, so a
refused request costs nothing from either. The daily window is fixed, and its edge is harmless:
two days' quota back to back, across midnight, is still two days' quota.

## Not every request costs the same

Reading one book is a lookup by primary key. A search with `LIKE '%…%'` reads every row of the
table, and with a million books instead of six it is the most expensive thing the API does. A limit
that counts requests charges both the same, so a client that only searches costs the server many
times what its count suggests.

**A cost per endpoint fixes that without a second limiter.** `limits.py` charges a search five
units from the same bucket and the same quota:

```
ana@api:~/shelf$ curl -s -H 'X-API-Key: demo-bia' 'localhost:8000/search?q=Cora'
[{"id": 4, "title": "Perto do Coração Selvagem"}]
ana@api:~/shelf$ python3 burst.py demo-bia '/search?q=a' 3
  0.00s  200  burst r=0  daily r=4990
  0.04s  429  burst r=0  daily r=4990  Retry-After: 5
  0.04s  429  burst r=0  daily r=4990  Retry-After: 5
```

The search for `Cora` took five tokens, and the first search of the burst took the other five.
Two requests had emptied a bucket of ten. The next two were refused with `Retry-After: 5`, because
five tokens at one a second take five seconds to come back, where a request costing one would have
been told `1`.

What a unit should weigh is a judgement made from measurement: the time each endpoint takes, the
rows it reads, the money it spends downstream. A GraphQL API takes the same idea further and
charges each query by what it asks for, which lesson 3 raises.

## Tiers

The numbers belong to a **tier**, and the key says which. That makes the limit part of the
product: the trial key has the same bucket as the free one and a quota of twenty units a day,
which is four searches. Searching once every five seconds keeps the trial key's bucket from ever
running dry, so only the quota can stop it:

```
ana@api:~/shelf$ python3 burst.py demo-ana '/search?q=a' 5 5
  0.00s  200  burst r=5  daily r=15
  5.00s  200  burst r=4  daily r=10
 10.00s  200  burst r=4  daily r=5
 15.00s  200  burst r=4  daily r=0
 20.00s  429  burst r=9  daily r=0  Retry-After: 70129
```

Four searches spent the twenty units, and the fifth was refused while the bucket had nine tokens to
spare. `Retry-After` is now the time to midnight UTC, in seconds. The refusal says which limit it
was, in the body:

```
ana@api:~/shelf$ curl -si -H 'X-API-Key: demo-ana' localhost:8000/books/1
HTTP/1.1 429 Too Many Requests
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:16 GMT
Content-Type: application/json
Content-Length: 51
RateLimit-Policy: "burst";q=10;w=10, "daily";q=20;w=86400
RateLimit: "burst";r=10;t=1, "daily";r=0;t=70124
Retry-After: 70124

{"error": "daily quota used up: retry in 70124 s"}
```

**The two refusals carry the same status and different advice.** "Too many requests: retry in 1 s"
tells a program to slow down. "Daily quota used up" with a wait of most of a day tells a person to
upgrade or come back tomorrow, and a client that backs off for hours on its own has to be built to
expect it. Some APIs answer a spent quota with `403` instead of `429`, and the draft that defines `RateLimit`
names a problem type for it, `quota-exceeded`. Whichever an API picks, the answer has to tell the
two apart, rather than leave the client to guess from the length of the wait.
