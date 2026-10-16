---
title: Locust, in a virtual environment
version: 1
---

Locust goes one step further than k6 and Gatling: **the test is a Python program, and Locust is a
library it imports.** There is no DSL to learn beyond a few classes and a decorator, and anything
Python can do, a test can do too. It is the natural choice for a team that already writes Python.

## Installing it

Locust comes from PyPI, and it goes into a virtual environment of its own rather than into the
system's Python, which Ubuntu 24.04 does not let `pip` change. The environment is `~/venv`;
lesson 21 adds a second tool to the same one.

```sh
python3 -m venv ~/venv
~/venv/bin/pip install locust==2.46.7
```

Those two lines were run when the machine in the transcripts was built. Check what you have:

```
ana@nft:~/locust$ ~/venv/bin/locust --version
locust 2.46.7 from /home/ana/venv/lib/python3.12/site-packages/locust (Python 3.12.3)
```

## A locustfile

Make a directory for it and open the file with `mkdir -p ~/locust && nano ~/locust/locustfile.py`:

```schooling-example
{"language": "python", "file": "locust/locustfile.py", "parts": [{"code": "# locust/locustfile.py\nimport os, random\nfrom locust import HttpUser, between, events, task\n\n", "note": "Plain Python, and Locust is an ordinary library imported from the virtual environment. Anything else Python can do, a locustfile can do too: read a file, call a function of your own, import another module."}, {"code": "class Visitor(HttpUser):\n    wait_time = between(1, 3)\n\n    def on_start(self):\n        self.customer = f\"locust{random.randint(1, 10000)}\"\n", "note": "A user is a class. `HttpUser` gives it `self.client`, an HTTP session that keeps its connection and its cookies like a browser. `wait_time = between(1, 3)` is the think time, a random wait after every task. `on_start` runs once per user before its first task, here to give each one a customer name."}, {"code": "    @task(3)\n    def look_at_a_show(self):\n        show = random.randint(981, 1000)\n        with self.client.get(f\"/shows/{show}\", name=\"/shows/[id]\", catch_response=True) as r:\n            if r.status_code != 200 or not isinstance(r.json().get(\"left\"), int):\n                r.failure(f\"show answered {r.status_code}\")\n", "note": "A task is a method with `@task`, and the number is its weight: this one is picked three times as often as a weight of 1, so three in four tasks look at a show. `name=` puts the twenty addresses under one line of the statistics. With `catch_response=True`, the block decides whether the request counts as a success: a 200 without a numeric `left` is marked as a failure."}, {"code": "    @task(1)\n    def book_a_seat(self):\n        order = {\"show_id\": random.randint(981, 1000), \"seat\": random.randint(1, 300),\n                 \"customer\": self.customer}\n        with self.client.post(\"/bookings\", json=order, catch_response=True) as r:\n            if r.status_code == 409:\n                r.success()\n            elif r.status_code != 201:\n                r.failure(f\"booking answered {r.status_code}\")\n", "note": "The booking, picked one time in four. Locust counts any status of 400 or above as a failure by default, so the 409 for a seat already taken is marked a success by hand, and anything that is not a 201 is marked a failure."}, {"code": "\n@events.quitting.add_listener\ndef judge(environment, **kwargs):\n    total = environment.stats.total\n    p95 = environment.stats.get(\"/shows/[id]\", \"GET\").get_response_time_percentile(0.95)\n    if total.fail_ratio > 0.01 or p95 > int(os.environ.get(\"P95\", 200)):\n        print(f\"FAIL: errors {total.fail_ratio:.2%}, p95 of /shows/[id] {p95} ms\")\n        environment.process_exit_code = 1", "note": "Locust has no thresholds. Its exit code is 1 if any request failed and 0 otherwise, and a pass or fail on a percentile has to be written. This function runs when the test ends, reads the statistics, and sets the exit code to 1 when errors are over 1% or the 95th percentile of `/shows/[id]` is over the limit: 200 ms, or the value of the `P95` environment variable."}]}
```

## Running it without the web page

Started with no flags, Locust opens a web page on port 8089 where you type the number of users
and press a button. **For a test that has to give the same verdict every time, run it headless**:
`-u` is the number of users, `-r` how many start each second, `-t` how long the test lasts, and
`--only-summary` keeps the statistics for the end instead of printing them every few seconds.
With the box office running in the first terminal:

```
ana@nft:~/locust$ ~/venv/bin/locust -f locustfile.py --headless -u 10 -r 2 -t 20s --host http://127.0.0.1:8000 --only-summary --csv boxoffice; echo "exit $?"
[2026-10-10 16:38:44,973] nft/INFO/locust.main: Starting Locust 2.46.7
[2026-10-10 16:38:44,974] nft/INFO/locust.main: Run time limit set to 20 seconds
[2026-10-10 16:38:44,975] nft/INFO/locust.runners: Ramping to 10 users at a rate of 2.00 per second
[2026-10-10 16:38:48,981] nft/INFO/locust.runners: All users spawned: {"Visitor": 10} (10 total users)
[2026-10-10 16:39:04,974] nft/INFO/locust.main: --run-time limit reached, shutting down
[2026-10-10 16:39:05,002] nft/INFO/locust.main: Shutting down (exit code 0)
Type     Name                                                                          # reqs      # fails |    Avg     Min     Max    Med |   req/s  failures/s
--------|----------------------------------------------------------------------------|-------|-------------|-------|-------|-------|-------|--------|-----------
POST     /bookings                                                                         25     0(0.00%) |     54      11     123     61 |    1.25        0.00
GET      /shows/[id]                                                                       72     0(0.00%) |     19      10      45     18 |    3.60        0.00
--------|----------------------------------------------------------------------------|-------|-------------|-------|-------|-------|-------|--------|-----------
         Aggregated                                                                        97     0(0.00%) |     28      10     123     20 |    4.84        0.00

Response time percentiles (approximated)
Type     Name                                                                                  50%    66%    75%    80%    90%    95%    98%    99%  99.9% 99.99%   100% # reqs
--------|--------------------------------------------------------------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
POST     /bookings                                                                              61     66     71     73     97    110    120    120    120    120    120     25
GET      /shows/[id]                                                                            18     20     23     23     28     30     40     46     46     46     46     72
--------|--------------------------------------------------------------------------------|--------|------|------|------|------|------|------|------|------|------|------|------
         Aggregated                                                                             20     23     28     31     65     73    110    120    120    120    120     97

exit 0
ana@nft:~/locust$ ls boxoffice*
boxoffice_exceptions.csv
boxoffice_failures.csv
boxoffice_stats.csv
boxoffice_stats_history.csv
```

**The first table is the counts and the times; the second is the percentiles.** Read the rows
before the numbers. There were 72 requests for a show and 25 bookings, close to the three to one
the task weights ask for, and the `Aggregated` row mixes the two kinds, which is why its median of
20 ms describes neither the shows at 18 ms nor the bookings at 61 ms. The bookings carry the
40 ms payment, and the `GET` row has the numbers lesson 1's requirement is about: a 95th
percentile of 30 ms.

**Locust is a closed model.** Ten users, each waiting between one and three seconds after every
task, send about one request every two seconds each, and the run reached 4.84 requests a second
in total. Had the box office slowed down, each user would have waited for its answer before its
next wait, and the rate would have fallen with it. `wait_time = constant_throughput(0.5)` paces
each user to one task every two seconds whatever the answers take, which keeps the rate up until
the answers themselves take longer than two seconds. The percentiles are marked *approximated*
because Locust rounds each time before counting: to the millisecond under 100 ms, and to the
nearest ten from there to a second, which is why the bookings read 110 and 120.

`--csv boxoffice` wrote the same statistics as files, beside the locustfile, which is the form a
spreadsheet or a pipeline wants: `boxoffice_stats.csv` holds the two tables, and
`boxoffice_stats_history.csv` one row of totals every few seconds of the run.

The judge at the end of the file has to work in the other direction too. `P95=5` sets a limit
nobody could meet:

```
ana@nft:~/locust$ P95=5 ~/venv/bin/locust -f locustfile.py --headless -u 10 -r 2 -t 20s --host http://127.0.0.1:8000 --only-summary > fail.log 2>&1; echo "exit $?"
exit 1
ana@nft:~/locust$ grep -E 'FAIL|exit code' fail.log
[2026-10-10 16:39:25,524] nft/INFO/locust.main: Shutting down (exit code 1)
FAIL: errors 0.00%, p95 of /shows/[id] 29 ms
```

**The exit code is 1, and the reason is printed.** Without the function, Locust would have exited
0 here, because no request failed; a slow test passes unless somebody wrote down what slow means.
