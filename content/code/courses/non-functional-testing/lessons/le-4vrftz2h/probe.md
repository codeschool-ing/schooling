---
title: A probe of your own
version: 1
---

A synthetic check is a script with three duties: walk a journey a customer walks, decide at each
step whether what came back is right, and say the verdict in a form a machine can act on. **The
decision is the part people leave out.** A script that fetches a page and prints the status code
is a curl in a loop; a probe knows which answer is a failure before it asks.

The journey here is the box office's own: list the shows on sale, open the first one, book a seat
in it. Each step has three things to check, and each one catches a different defect:

- **the status**, which catches the server refusing or crashing;
- **the body**, which catches a server answering 200 with nothing useful in it — an empty list of
  shows, a booking for a different seat;
- **the time**, which catches the server that still works and has become too slow to use, the
  failure a status code never shows.

The thresholds are the same kind of number lesson 1 asked for, for one request at a time: 300 ms to
list or open, 500 ms to book, measured at the client. **They are deliberately looser than a
percentile requirement**, because a single request can be unlucky and a probe that fails on luck is
a probe somebody learns to ignore.

In `~/monitor`, the directory lesson 22 made, create `probe.py`:

```schooling-example
{"language": "python", "file": "monitor/probe.py", "parts": [{"code": "# monitor/probe.py\n# One synthetic customer: list the shows, open one, book a seat. Prints one\n# line and exits 0 if every step met its threshold, 1 if any step did not.\nimport json, random, sys, time, urllib.error, urllib.request\nfrom datetime import datetime\n", "note": "Standard library only, like boxoffice, so the probe runs on any machine that has Python and nothing else, which matters once it runs from machines you do not otherwise look after."}, {"code": "BASE = \"http://127.0.0.1:8000\"\nCUSTOMER = \"synthetic-probe\"         # every booking it makes says so\nLIMIT_MS = {\"list\": 300, \"show\": 300, \"book\": 500}\n", "note": "Everything that changes between environments sits at the top. `CUSTOMER` is the probe's own name, so every booking it makes can be told from a real one. `LIMIT_MS` is the threshold per step, the five parts of lesson 1 in miniature: the operation, the statistic (this one request), the number."}, {"code": "def call(method, path, body=None):\n    data = json.dumps(body).encode() if body is not None else None\n    req = urllib.request.Request(BASE + path, data=data, method=method,\n                                 headers={\"Content-Type\": \"application/json\"})\n    start = time.perf_counter()\n    try:\n        with urllib.request.urlopen(req, timeout=5) as r:\n            status, raw, rid = r.status, r.read(), r.headers.get(\"X-Request-Id\")\n    except urllib.error.HTTPError as e:\n        status, raw, rid = e.code, e.read(), e.headers.get(\"X-Request-Id\")\n    ms = (time.perf_counter() - start) * 1000\n    return status, json.loads(raw or b\"null\"), ms, rid\n", "note": "One HTTP request, timed from the client's side, the way a customer waits for it. A 4xx or 5xx raises `HTTPError` in `urllib`, so it is caught and turned back into a status. A server that is not there raises something else, which `journey` does not catch and the last lines do. The request id comes back from `observed.py`'s header."}, {"code": "steps = []\n\ndef check(name, status, want, ms, rid):\n    steps.append(f\"{name}={status}/{ms:.0f}ms\")\n    if status != want:\n        raise AssertionError(f\"{name}: wanted {want}, got {status} (request {rid})\")\n    if ms > LIMIT_MS[name]:\n        raise AssertionError(f\"{name}: {ms:.0f} ms is over {LIMIT_MS[name]} ms (request {rid})\")\n", "note": "Each step leaves its status and its time in `steps`, so the result line says how far the journey got. `check` fails on the wrong status or on a time over the limit, and the message carries the request id, so a failure can be looked up in the server's log."}, {"code": "def journey():\n    status, shows, ms, rid = call(\"GET\", \"/shows\")\n    check(\"list\", status, 200, ms, rid)\n    if not shows:\n        raise AssertionError(\"list: no show on sale\")\n    status, show, ms, rid = call(\"GET\", f\"/shows/{shows[0]['id']}\")\n    check(\"show\", status, 200, ms, rid)\n    if show[\"left\"] < 1:\n        raise AssertionError(\"show: no seat left to book\")\n    for _ in range(5):\n        seat = random.randint(1, show[\"capacity\"])\n        status, booked, ms, rid = call(\"POST\", \"/bookings\",\n                                       {\"show_id\": show[\"id\"], \"seat\": seat, \"customer\": CUSTOMER})\n        if status != 409:              # 409: a real customer has that seat, try another\n            break\n    check(\"book\", status, 201, ms, rid)\n    if booked.get(\"seat\") != seat:\n        raise AssertionError(f\"book: asked for seat {seat}, got {booked}\")\n", "note": "The journey: list the shows, open the first, book a random seat of it. A 409 means a real customer already holds that seat, which is the box office working, so the probe tries another seat up to five times. The body is checked too: a 201 that booked a different seat is a failure no status code would show."}, {"code": "if __name__ == \"__main__\":\n    try:\n        journey()\n        verdict, why = \"PASS\", []\n    except (AssertionError, OSError, ValueError, KeyError) as e:\n        verdict, why = \"FAIL\", [f\"-- {e}\"]\n    print(\" \".join([datetime.now().strftime(\"%H:%M:%S\"), verdict] + steps + why), flush=True)\n    sys.exit(0 if verdict == \"PASS\" else 1)", "note": "One line, one exit code. `0` means every step passed and `1` means one did not, which is what a scheduler, a shell loop or lesson 24's alerting can act on without reading the line."}]}
```

## Running it

The probe is aimed at `observed.py`, lesson 22's version of the box office, so that its failures
can be looked up in a log. In the first terminal, in `~/boxoffice`:

```sh
python3 observed.py > requests.log
```

In the second, in `~/monitor`, run the probe once and ask for its exit code:

```
ana@nft:~/monitor$ python3 probe.py; echo "exit $?"
16:33:05 PASS list=200/34ms show=200/16ms book=201/56ms
exit 0
```

Three steps, three statuses, three times, and `exit 0`. The listing took longer than opening a
show, though the server does far less work for it: what the probe times includes everything on the
client's side as well as the server's, which is the reason to time it from outside.

Now stop the server with `Ctrl+C` in the first terminal and run the probe again:

```
ana@nft:~/monitor$ python3 probe.py; echo "exit $?"
16:33:06 FAIL -- <urlopen error [Errno 111] Connection refused>
exit 1
```

No step got an answer, so there is no status to print, and the error is the operating system's:
nothing listening on the port. **This is the failure lesson 22's metrics cannot see**, because the
process that would have counted it is the one that is gone. The metrics simply stop, and `up`
goes to 0 only if Prometheus itself is still running and able to reach where boxoffice used to be.
