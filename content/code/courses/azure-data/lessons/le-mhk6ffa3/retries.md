---
title: What the library retries, and when it gives up
version: 1
---

**A throttled request is retried by the library before your code hears about it.** The Python
library's policy for a 429 is short enough to read in its own source, in
`azure/cosmos/_resource_throttle_retry_policy.py`: wait what `x-ms-retry-after-ms` asked for, try
again, and stop after a number of attempts or once the waiting adds up to a limit, whichever comes
first. The defaults are in the library itself, and asking it is the honest way to know them:

```
ana@laptop:~/azure$ python -c 'from azure.cosmos.documents import RetryOptions; r = RetryOptions(); print(r.MaxRetryAttemptCount, r.MaxWaitTimeInSeconds, r.FixedRetryIntervalInMilliseconds)'
9 30 None
```

**Nine attempts and thirty seconds, and no fixed interval**, so the wait is the one the service asked
for each time. Both can be changed when the client is created. An interactive request, a customer
waiting for the page, should give up sooner than thirty seconds, and a bulk load at three in the
morning can afford to wait longer. Whatever the numbers, the request that outlasts them arrives as an
exception with status 429, and the program has to decide what that means.

The program below writes one order with a client that retries three times and waits at most five
seconds, and shows the two places a program learns about throttling. Save it as `writer.py`:

```schooling-example
{"language": "python", "file": "writer.py", "parts": [
{"code": "from azure.cosmos import CosmosClient, exceptions\n\nKEY = \"C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw==\"\nclient = CosmosClient(\"http://localhost:8081\", KEY,\n                      retry_throttle_total=3,\n                      retry_throttle_backoff_max=5)\norders = client.get_database_client(\"quitanda\").get_container_client(\"promo\")\n", "note": "The two settings that matter for a 429. `retry_throttle_total` is how many times the library retries a throttled request, and `retry_throttle_backoff_max` how many seconds of waiting it will add up before giving up. Leave them out and they are 9 and 30."},
{"code": "\n\ndef save(order):\n    try:\n        orders.upsert_item(order)\n    except exceptions.CosmosHttpResponseError as e:\n        if e.status_code != 429:\n            raise\n        wait = int(e.headers.get(\"x-ms-retry-after-ms\", 1000))\n        print(f\"{order['id']} still throttled after the retries; told to wait {wait} ms\")\n        return False\n", "note": "A 429 that outlasts the retries arrives as `CosmosHttpResponseError`. Anything else is re-raised, because a 409 or a 412 is a different problem. The wait the service asked for is in `x-ms-retry-after-ms`, and the function reports it rather than sleeping, so the caller decides: put the order on a queue, slow down, or tell the person."},
{"code": "    answer = orders.client_connection.last_response_headers\n    print(order[\"id\"], \"saved;\", answer.get(\"x-ms-throttle-retry-count\", \"0\"), \"throttled attempts,\",\n          answer.get(\"x-ms-throttle-retry-wait-time-ms\", \"0\"), \"ms waited\")\n    return True\n", "note": "After a success, the library adds two headers of its own to the answer: how many throttled attempts it made and how long it waited in total. A program that logs them sees throttling as it starts, as slowness, long before the first exception."},
{"code": "\n\nsave({\"id\": \"o-90001\", \"customerId\": \"c-7\", \"totalCents\": 4890})\n", "note": "One order, written to the container `flood.py` made."}
]}
```

```
ana@laptop:~/azure$ python writer.py
o-90001 saved; 0 throttled attempts, 0 ms waited
```

**Zero throttled attempts and zero milliseconds**, which on the emulator is every answer there will
ever be, so the `except` branch did not run here: the 429 it handles was never produced, and no 429
from Azure appears anywhere in this course. The code is written against the shape Microsoft documents
and the library's own source, and the first time it runs for real will be against an account.

## Retrying is not a plan for capacity

**The retries hide throttling until they cannot.** A container that is throttled 1% of the time
answers a little slower and nobody notices; at 30% the retries themselves are a third more requests,
each one spending request units the container did not have, and the latency climbs until requests
time out. Three things change that, and none of them is a bigger retry count:

- **more throughput, or autoscale with a higher maximum**, when the whole container is busy;
- **a better partition key**, when one partition is busy and the rest are not, as the section before
  this one showed;
- **less work per request**: a point read instead of a query, a query that names its partition key,
  fewer indexed properties on a container that is mostly written.

Lesson 24 comes back to retries from the other side: a retried write that had in fact succeeded is a
duplicate, and only a write keyed by an id the writer chose itself makes the second one harmless.
