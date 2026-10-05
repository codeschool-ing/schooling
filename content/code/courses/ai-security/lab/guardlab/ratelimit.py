"""Per-user and per-key rate limits, replayed over a log of API requests.

The requests in data/api-requests.jsonl were WRITTEN BY THE COURSE by
build() below: five minutes of six of Tarefa's users talking to the
assistant, all of it sent on Tarefa's one key with the model provider. One of
the six runs a script during the second and third minutes. The times are
seconds after the first request, so a replay gives the same answer every
time.

A limit is a sliding window: a request is allowed if fewer than LIMIT
requests were allowed in the 60 seconds before it. Refused requests do not
count against the window, as a client that is refused and waits gets back in.
"""
import json
from collections import deque

USERS = {  # end user: requests per minute in each of the five minutes
    "eu-2b8e41c07d93a5f60e1c": [3, 4, 3, 5, 4],
    "eu-5c0d9f72aa1e48b3c6d2": [6, 5, 6, 4, 6],
    "eu-7e3a18b5c90f2d64a1b7": [2, 2, 3, 2, 2],
    "eu-91f4d2a6e07c3b85d1e9": [4, 6, 5, 6, 5],
    "eu-b37c05e8d1a294f6c0a3": [5, 3, 4, 4, 3],
    "eu-e60a7d3c4b19f8e25d07": [2, 90, 110, 3, 2],
}


def build(path):
    rows = []
    for user, per_minute in USERS.items():
        for minute, n in enumerate(per_minute):
            for i in range(n):
                t = minute * 60 + (i * 60) // n + (sum(map(ord, user)) % 7)
                rows.append({"t": min(t, minute * 60 + 59), "key": "tarefa-prod", "end_user": user})
    rows.sort(key=lambda r: (r["t"], r["end_user"]))
    with open(path, "w") as fh:
        for r in rows:
            fh.write(json.dumps(r) + "\n")


class Window:
    def __init__(self, limit):
        self.limit, self.times = limit, deque()

    def allow(self, t):
        while self.times and self.times[0] <= t - 60:
            self.times.popleft()
        if len(self.times) < self.limit:
            self.times.append(t)
            return True
        return False


def replay(rows, per_key, per_user):
    key_windows, user_windows, out = {}, {}, {}
    for r in rows:
        u = r["end_user"]
        stat = out.setdefault(u, [0, 0])
        stat[0] += 1
        uw = user_windows.setdefault(u, Window(per_user)) if per_user else None
        if uw and not uw.allow(r["t"]):
            continue
        kw = key_windows.setdefault(r["key"], Window(per_key))
        if not kw.allow(r["t"]):
            if uw:
                uw.times.pop()  # the user's slot is given back: the key refused it
            continue
        stat[1] += 1
    return out
