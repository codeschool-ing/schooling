---
title: The throttled request, and the partition that causes it
version: 1
---

**When the operations of one second need more request units than that second has, Cosmos DB refuses
the rest**: HTTP 429, *request rate is large*, with sub-status 3200 when the cause is the throughput
budget, and nothing is written. The answer carries a header, `x-ms-retry-after-ms`, saying how long to
wait before the request can succeed. The libraries wait that long and send it again, which is why a
program meets throttling first as slowness and only later, if at all, as an error. This section is
taught from Microsoft's documentation, with one program run on the emulator to show that the emulator
never says no.

## The budget is per second and per partition

A container's throughput is spread evenly over its physical partitions, and the documentation caps a
physical partition at 10,000 RU/s and 50 GB. A container provisioned at 30,000 RU/s on three physical
partitions therefore has 10,000 a second in each. **A request is throttled when its own partition
has run out, whatever the others have left.** One logical partition, every item with the same key,
lives in one physical partition, so 10,000 RU/s is also the most one key can ever get.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 296\" role=\"img\" aria-label=\"Two containers of 30,000 RU/s, each spread over three physical partitions with a budget of 10,000 RU/s apiece. Left, keyed by day: today's key 2026-10-30 asks its partition for 14,000 RU/s, fills it to the limit and gets 429 answers, while the other two partitions are nearly idle. Right, keyed by customer: the same load is spread at about 4,900 RU/s on each partition, under the limit.\" data-fig=\"l13-hot\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">one key a day</text><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/day</text><line x1=\"20\" y1=\"70\" x2=\"320\" y2=\"70\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"320\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">10,000 RU/s per physical partition</text><rect x=\"32\" y=\"70\" width=\"76\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"36\" y=\"70.0\" width=\"68\" height=\"150.0\" rx=\"2\" fill=\"var(--amber)\"/><text x=\"70\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partition 1</text><text x=\"70\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2026-10-30</text><text x=\"70\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--ink)\" font-weight=\"600\">429</text><rect x=\"132\" y=\"70\" width=\"76\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"136\" y=\"215.5\" width=\"68\" height=\"4.5\" rx=\"2\" fill=\"var(--phosphor)\"/><text x=\"170\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partition 2</text><text x=\"170\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">…</text><rect x=\"232\" y=\"70\" width=\"76\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"236\" y=\"215.5\" width=\"68\" height=\"4.5\" rx=\"2\" fill=\"var(--phosphor)\"/><text x=\"270\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partition 3</text><text x=\"270\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">…</text><text x=\"380\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">one key a customer</text><text x=\"380\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">/customerId</text><line x1=\"380\" y1=\"70\" x2=\"680\" y2=\"70\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"/><text x=\"680\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">10,000 RU/s per physical partition</text><rect x=\"392\" y=\"70\" width=\"76\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"396\" y=\"146.5\" width=\"68\" height=\"73.5\" rx=\"2\" fill=\"var(--phosphor)\"/><text x=\"430\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partition 1</text><text x=\"430\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">c-1 … c-7</text><rect x=\"492\" y=\"70\" width=\"76\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"496\" y=\"148.0\" width=\"68\" height=\"72.0\" rx=\"2\" fill=\"var(--phosphor)\"/><text x=\"530\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partition 2</text><text x=\"530\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">c-8 …</text><rect x=\"592\" y=\"70\" width=\"76\" height=\"150\" rx=\"3\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"/><rect x=\"596\" y=\"146.5\" width=\"68\" height=\"73.5\" rx=\"2\" fill=\"var(--phosphor)\"/><text x=\"630\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">partition 3</text><text x=\"630\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">…</text><text x=\"360\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">The same 14,600 RU/s, inside the same 30,000 RU/s container.</text></svg>", "caption": "A container's throughput is divided among its physical partitions, and a key that sends everything to one of them is throttled while the container is mostly idle."}
```

**A key that concentrates the load is a hot partition**, and lesson 11's choice of key is where it is
prevented. Keyed by day, every order of a promotion evening goes to today's key and its one partition,
and is throttled while two thirds of the paid capacity idles. Keyed by customer, the same orders spread
over every partition. No setting raises the ceiling on one key: more throughput adds partitions and
spreads the other keys more thinly, and the hot one stays on its own.

## Reading the symptoms

Microsoft's monitoring for Cosmos DB shows two numbers worth knowing by name. **Total requests split by
status code** counts the 429s. **Normalized RU Consumption**, spelt as the metric spells it, is the busiest partition's share of its
budget, minute by minute, and 100% means at least one partition spent everything it had in at least
one second of that minute. A container whose normalised consumption sits at 100% while its total
consumption is low has a hot partition, and the fix is the key, not the throughput. The documentation
also says that a small share of 429s, a few per cent, with acceptable latency is a container doing its
job: the retries absorb them, and the capacity is being used rather than left idle.

## What the emulator does instead

**The emulator never throttles.** `flood.py` creates a container at 400 RU/s and writes 2,000 orders
to it as fast as one program can, adding up the throttled attempts the library reports after each
write:

`flood.py`:

```python
import time

from azure.cosmos import CosmosClient, PartitionKey

KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="
client = CosmosClient("http://localhost:8081", KEY)
db = client.create_database_if_not_exists("quitanda")
orders = db.create_container_if_not_exists("promo", PartitionKey("/customerId"),
                                           offer_throughput=400)

retried, start = 0, time.time()
for i in range(2000):
    orders.upsert_item({"id": f"o-{i:05d}", "customerId": f"c-{i % 50}", "totalCents": 4890})
    headers = orders.client_connection.last_response_headers
    retried += int(headers.get("x-ms-throttle-retry-count", 0))
took = time.time() - start
print(f"2000 writes in {took:.1f} s, {2000 / took:.0f} a second, {retried} retried after a 429")
```

```
ana@laptop:~/azure$ python flood.py
2000 writes in 12.8 s, 156 a second, 0 retried after a 429
```

**2,000 writes in 12.8 seconds, 156 a second, against a container created at 400 RU/s, and not one
was retried.** Azure was not asked. At the illustrative 6 request units a write of the previous
section, 400 RU/s carries about 66 writes a second, so those 12.8 seconds would have carried about
850 of them. The rest would have been answered 429 and retried after the wait each answer named,
stretching the same program to about thirty seconds. **A load test against the emulator measures your
program and your laptop, never Cosmos DB.** The capacity of a design is checked with the arithmetic of
this lesson and with a real account and a budget, not here.
