---
title: InfluxDB, sales by the hour
version: 1
---

InfluxDB stores time series: **measurements** with **tags**, **fields** and a timestamp, written in
the line protocol of lesson 4. Version 2 groups data into **buckets**, each with a **retention
period** after which its data is dropped.

The first start can set everything up from environment variables: a user, an organisation, a bucket
called `sales` that keeps 30 days, and an access token, which the `influx` command inside the
container then uses on its own.

## Generating the points

Three hours of sales for show 1, one point per minute for each of two channels, the web and the app,
written as line protocol by a short program saved as `points.py`:

```python
# points.py
"""Three hours of ticket sales, one line per minute per channel, in line protocol."""
START = 1794776400  # 2026-11-15 18:00 in São Paulo, in seconds since 1970

for minute in range(180):
    for channel, share in (("web", 3), ("app", 2)):
        tickets = (minute * 7 + share * 11) % 9 + share
        print(f"sales,show=1,channel={channel} tickets={tickets}i {START + minute * 60}")
```

The number of tickets per minute comes from arithmetic on the minute, so every run produces the same
360 lines. The timestamps are in seconds, which is why the write below says `-p s`, precision in
seconds.

```
ana@lab:~/tickets$ docker run -d --name influx --memory 1g -e DOCKER_INFLUXDB_INIT_MODE=setup -e DOCKER_INFLUXDB_INIT_USERNAME=ana -e DOCKER_INFLUXDB_INIT_PASSWORD=lab-password -e DOCKER_INFLUXDB_INIT_ORG=sabia -e DOCKER_INFLUXDB_INIT_BUCKET=sales -e DOCKER_INFLUXDB_INIT_RETENTION=30d -e DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=lab-token influxdb:2.9.1
a6df716145711c625627aac4261ecd9b39a3826f718dc82f99e33e8d3c8c0f54
ana@lab:~/tickets$ python3 points.py > sales.lp
ana@lab:~/tickets$ head -3 sales.lp
sales,show=1,channel=web tickets=9i 1794776400
sales,show=1,channel=app tickets=6i 1794776400
sales,show=1,channel=web tickets=7i 1794776460
ana@lab:~/tickets$ docker cp sales.lp influx:/tmp/sales.lp
ana@lab:~/tickets$ docker exec influx influx write -b sales -p s -f /tmp/sales.lp
```

## Asking by the hour

A query, saved as `hourly.flux`, in InfluxDB's language Flux: read the bucket for the three hours,
keep the `sales` measurement, group by channel, sum each hour, and keep three columns:

```
// hourly.flux
from(bucket: "sales")
  |> range(start: 2026-11-15T21:00:00Z, stop: 2026-11-16T00:00:00Z)
  |> filter(fn: (r) => r._measurement == "sales")
  |> group(columns: ["channel"])
  |> aggregateWindow(every: 1h, fn: sum)
  |> keep(columns: ["_time", "channel", "_value"])
```

```
ana@lab:~/tickets$ docker cp hourly.flux influx:/tmp/hourly.flux
ana@lab:~/tickets$ docker exec influx influx query -f /tmp/hourly.flux
Result: _result
Table: keys: [channel]
        channel:string                      _time:time                  _value:int
----------------------  ------------------------------  --------------------------
                   app  2026-11-15T22:00:00.000000000Z                         357
                   app  2026-11-15T23:00:00.000000000Z                         357
                   app  2026-11-16T00:00:00.000000000Z                         366
Table: keys: [channel]
        channel:string                      _time:time                  _value:int
----------------------  ------------------------------  --------------------------
                   web  2026-11-15T22:00:00.000000000Z                         420
                   web  2026-11-15T23:00:00.000000000Z                         420
                   web  2026-11-16T00:00:00.000000000Z                         420
ana@lab:~/tickets$ docker exec influx influx bucket list --name sales
ID			Name	Retention	Shard group duration	Organization ID		Schema Type
d2ac90aec3114e1c	sales	720h0m0s	24h0m0s			512f1b194a989be8	implicit
ana@lab:~/tickets$ docker rm -f influx
influx
```

Two tables, one per channel, three hours each: **420 tickets an hour on the web, 357 to 366 on the
app**. The times are in UTC and each row is labelled with the **end** of its hour, so `22:00Z` is
the hour from 18:00 to 19:00 in São Paulo. `aggregateWindow` is the downsampling of lesson 4 done at
query time; InfluxDB can also run it as a scheduled task that writes the hourly sums into a second
bucket with a longer retention, and lets the raw points expire.

`bucket list` shows the retention, **720 hours**, thirty days, set when the bucket was created. A
point older than that is removed by InfluxDB without anybody deleting it. Remove the container when
you are done.
