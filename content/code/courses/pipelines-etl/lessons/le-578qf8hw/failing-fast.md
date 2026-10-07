---
title: Failing fast
version: 1
---

`airflow tasks test` runs one task once, outside the scheduler, which is the quickest way to see
what a failure turns into. Ana runs `fetch` twice: once with a wrong key, and once with the key
right and the API down.

```
ana@vm:~/etl$ PRICES_API_KEY=wrong airflow tasks test prices_daily fetch 2026-03-09 2>&1 | grep -oE "new_state=[a-z_]+|[A-Za-z.]*(Exception|Error): .*" | uniq
airflow.sdk.exceptions.AirflowFailException: the API refused the request: 401 {"error": "missing or wrong X-Api-Key"}
new_state=failed
ana@vm:~/etl$ airflow tasks test prices_daily fetch 2026-03-09 2>&1 | grep -oE "new_state=[a-z_]+|[A-Za-z.]*(Exception|Error): .*" | uniq
requests.exceptions.HTTPError: 503 Server Error: Service Unavailable for url: http://127.0.0.1:8081/v1/prices?page_size=200
new_state=up_for_retry
```

**The same task, two failures, two different states.** The `503` left the task `up_for_retry`: a
plain exception, so Airflow will try again after the retry delay, as many times as `retries`
allows. The `401` left it `failed`, with four retries still unused, because the code raised
`AirflowFailException`, which is Airflow's word for *do not bother trying again*.

That one `if` decides how the night goes. Without it, a wrong key costs five tries and the waits
between them — fifteen seconds, then thirty, sixty and a hundred and twenty, close to four minutes
here and hours with a production retry delay — **and then** the alert, saying the same thing it
could have said at the start. With it, the alert is written at the first try.

The list in the `if` is the judgement, and it has to be made per source. `400`, `401` and `403` are
the API refusing the request as written. `404` could be either: a page that was removed, or one that
has not been published yet. `429` is not a failure at all here, because the loop waits as the API
asks and tries the same page again without leaving the task. And everything the code did not think
of falls through to `raise_for_status()` and is retried, which is the safe default: a mistaken retry
costs minutes, and a mistaken refusal to retry costs the night's data.
