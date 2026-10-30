---
title: An indicator, counted from what customers see
version: 1
---

**A service level indicator is a ratio: good events over valid events.** Not CPU, not memory, not the
number of pods: those are causes, and a customer feels none of them directly. The shop's indicators are
about checkout, the route where a failure loses a sale, and there are two:

- **availability**: of all checkout requests, the share that succeeded;
- **speed**: of all checkout requests, the share that succeeded within one second.

Both are counted from `AppRequests`, the record of what customers actually received. Per day, with the
day taken in São Paulo's calendar rather than UTC's, because that is the day the business reports on:

```kql
// sli.kql: two indicators for checkout, per day: availability and speed
AppRequests
| where Name == "POST /checkout"
| summarize valid = count(), available = countif(Success), fast = countif(Success and DurationMs <= 1000)
    by day = bin(datetime_utc_to_local(TimeGenerated, "America/Sao_Paulo"), 1d)
| extend availability = round(100.0 * available / valid, 2), speed = round(100.0 * fast / valid, 2)
| order by day asc
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < sli.kql
day                   valid  available  fast  availability  speed
2026-10-12T00:00:00Z  4269   4264       4243  99.88         99.39
2026-10-13T00:00:00Z  4256   4253       4233  99.93         99.46
2026-10-14T00:00:00Z  4265   4260       4249  99.88         99.62
2026-10-15T00:00:00Z  4193   4084       4009  97.4          95.61
2026-10-16T00:00:00Z  4229   4226       4201  99.93         99.34
2026-10-17T00:00:00Z  4427   4424       4407  99.93         99.55
2026-10-18T00:00:00Z  4224   4222       4207  99.95         99.6
```

`datetime_utc_to_local()` moves each timestamp into local time before `bin()` cuts it into days, so the
`day` column is a local date even though it prints with a `Z`. Six days sit near 99.9% available and
99.5% fast. **Thursday was 97.4% and 95.6%.** Those two numbers are the incident, seen by the only judge
that matters.

Two choices in the query are decisions, not details. **The speed indicator counts a fast failure as bad**
(`Success and DurationMs <= 1000`): an error in 20 ms is not a fast checkout. And **valid** is every
checkout request; a team that excluded, say, requests from bots would put that filter here, once, where
everybody can see it.
