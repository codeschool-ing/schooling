---
title: A line for a person, a record for a machine
version: 2
---

Start this lesson from a lab started again from nothing, and set the simulated customers going
for twenty minutes before anything else: the shop's own logs are what the later sections read, and
the last one counts a minute of them.

```sh
docker compose run -d --rm loadgen python -m loadgen.load 5 1200
```

The first log lines anybody writes are sentences: *checkout finished for order 5001 in 11ms*. They
read well, and they are read by people for exactly as long as there are few enough to read. **After
that, logs are read by programs**, searching, counting and filtering, and a sentence is the hardest
possible input for a program. `two_ways.py` writes the same two thousand checkouts both ways, with
made-up durations:

```python
import json
import random

random.seed(3)
with open("plain.log", "w") as plain, open("json.log", "w") as structured:
    for n in range(1, 2001):
        took = round(random.expovariate(1 / 40))
        order = 5000 + n
        plain.write(f"INFO checkout finished for order {order} in {took}ms (kettle, paid)\n")
        structured.write(json.dumps({"level": "INFO", "message": "checkout finished", "order_id": order,
                                     "sku": "kettle", "outcome": "paid", "duration_ms": took}) + "\n")
```

```
ana@obs:~/shop$ docker compose run --rm sandbox python two_ways.py 2>/dev/null; head -2 scratch/plain.log scratch/json.log
==> scratch/plain.log <==
INFO checkout finished for order 5001 in 11ms (kettle, paid)
INFO checkout finished for order 5002 in 31ms (kettle, paid)

==> scratch/json.log <==
{"level": "INFO", "message": "checkout finished", "order_id": 5001, "sku": "kettle", "outcome": "paid", "duration_ms": 11}
{"level": "INFO", "message": "checkout finished", "order_id": 5002, "sku": "kettle", "outcome": "paid", "duration_ms": 31}
```

Now the question an investigation actually asks: *which checkouts took 150 milliseconds or more?*
Against the sentences, it is a regular expression. It has to know where the number sits, that it
is followed by `ms`, and how to say *a number at least 150* one digit at a time. Against the records,
it is a field and a comparison:

```
ana@obs:~/shop$ grep -cE 'in (1[5-9][0-9]|[2-9][0-9]{2}|[0-9]{4,})ms' scratch/plain.log
49
ana@obs:~/shop$ jq -c 'select(.duration_ms >= 150)' scratch/json.log | wc -l
49
```

**Forty-nine both ways**, so the regular expression is right, this time. It is also wrong the day
somebody changes the sentence to *in 0.217 s*, matches nothing if a line says *in 1200 ms* with a
space. And the next person cannot read it without a minute's thought. The field survives all of
that, and it composes: the next question, *the slow ones that were paid, with their order ids*,
is one more condition:

```
ana@obs:~/shop$ jq -c 'select(.duration_ms >= 150 and .outcome == "paid") | {order_id, duration_ms}' scratch/json.log | head -3
{"order_id":5011,"duration_ms":217}
{"order_id":5054,"duration_ms":188}
{"order_id":5068,"duration_ms":183}
```

That is the whole argument for structured logging. The rest of this lesson is about doing it
well: **a log line is a record with named fields, and the sentence is just one field of it**.
