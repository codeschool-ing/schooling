---
title: Starting it and asking it
version: 1
---

Two programs talk to the server in this section: `curl`, which sends a request from the terminal, and
`jq`, which reads the JSON that comes back. On Ubuntu, and in WSL, check that both are there:

```sh
curl --version | head -1
jq --version
```

If either says `command not found`, install them with `sudo apt install curl jq`. On macOS `curl` comes
with the system and `jq` is `brew install jq`.

The server needs a terminal of its own, because it runs until it is stopped. Open a second terminal,
which `~/.bashrc` puts in the course's environment, and start it there:

```sh
cd ~/ml
uvicorn app:app
```

`app:app` means *the object called `app` in the file `app.py`*. Uvicorn answers on
`http://127.0.0.1:8000`, which is this machine and nothing outside it, and prints a line for every
request it receives. Leave it running, and go back to the first terminal.

To ask about a real subscriber, the request needs one row of `churn_2026.csv` as JSON, without the two
columns the API does not take. Save this as `row.py`:

```python
# row.py
import sys

import pandas as pd

rows = pd.read_csv("data/churn_2026.csv")
row = rows[(rows["customer_id"] == sys.argv[1]) & (rows["snapshot"] == sys.argv[2])]
print(row.drop(columns=["snapshot", "days_since_last_order"]).iloc[0].to_json(force_ascii=False))
```

Then ask the server about two subscribers in March 2026:

```
ana@lab:~/ml$ curl -s localhost:8000/health | jq -c
{"model":"churn-2025-12","trained_to":"2025-12-01","cut":0.2778}
ana@lab:~/ml$ python row.py C00007 2026-03-01 > c00007.json
ana@lab:~/ml$ cat c00007.json
{"customer_id":"C00007","city":"São Paulo","age":18,"app_user":1,"payment":"pix","plan":"weekly","box":"large","channel":"ads","tenure_months":5,"price_month":757.12,"orders_90d":11,"skips_90d":1,"late_90d":2,"complaints_90d":0,"support_calls_90d":1,"rating_90d":3.58,"days_since_login":5.0}
ana@lab:~/ml$ curl -s localhost:8000/score -H 'content-type: application/json' -d @c00007.json | jq -c
{"customer_id":"C00007","chance":0.6449,"credit":true,"model":"churn-2025-12"}
ana@lab:~/ml$ python row.py C00035 2026-03-01 | curl -s localhost:8000/score -H 'content-type: application/json' -d @- | jq -c
{"customer_id":"C00035","chance":0.0795,"credit":false,"model":"churn-2025-12"}
```

`-d @c00007.json` sends the file as the body of the request, and `-d @-` sends whatever arrives
through the pipe. `jq -c` prints the answer on one line.

**C00007 gets a credit**: 18 years old, five months in, two late deliveries and a rating of 3.58, which
is lesson 14's unhappy shape. **C00035 does not**, and it is the more interesting request: on the monthly
plan, with no app and no rating, so `rating_90d` and `days_since_login` both arrived as `null`, and the
pipeline's imputer filled them as it does in every batch.

Now three requests that should not get a chance:

```
ana@lab:~/ml$ jq '.age = "forty"' c00007.json | curl -s localhost:8000/score -H 'content-type: application/json' -d @- | jq -c '.detail[] | [.loc[1], .msg]'
["age","Input should be a valid integer, unable to parse string as an integer"]
ana@lab:~/ml$ jq 'del(.rating_90d)' c00007.json | curl -s localhost:8000/score -H 'content-type: application/json' -d @- | jq -c '.detail[] | [.loc[1], .msg]'
["rating_90d","Field required"]
ana@lab:~/ml$ jq '.plan = "daily"' c00007.json | curl -s localhost:8000/score -H 'content-type: application/json' -d @- | jq -c
{"customer_id":"C00007","chance":0.3843,"credit":true,"model":"churn-2025-12"}
```

The first two are refused, with **status 422** and a sentence that names the field. An age of
`"forty"` is not a number, and a request without `rating_90d` is not the same as a rating of `null`.
Neither reached the model.

The third was not refused, and that is the cost of the first choice in the previous section. **A plan
called `daily` does not exist**, and it was scored: the encoder gave it zeros, and the chance moved from
0.6449 to 0.3843, still a credit. An API with a list of plans would have refused it, and would have refused the monthly
plan in February as well. One way out is a list kept beside the card, updated when the business adds a
plan; the other is to accept unknowns and count them, which lesson 22 does. Either is a decision, and the
one that is not a decision is to never look.

The second terminal shows what the server saw:

```
ana@lab:~$ cd ~/ml
ana@lab:~/ml$ uvicorn app:app
INFO:     Started server process [12128]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
INFO:     127.0.0.1:45186 - "GET /health HTTP/1.1" 200 OK
INFO:     127.0.0.1:45188 - "POST /score HTTP/1.1" 200 OK
INFO:     127.0.0.1:45198 - "POST /score HTTP/1.1" 200 OK
INFO:     127.0.0.1:45206 - "POST /score HTTP/1.1" 422 Unprocessable Entity
INFO:     127.0.0.1:45214 - "POST /score HTTP/1.1" 422 Unprocessable Entity
INFO:     127.0.0.1:45226 - "POST /score HTTP/1.1" 200 OK
```

One line per request, with its status. The two refusals are there as **422**, so a client sending bad
data shows up in the server's log even when nobody reads the client's. And every answer the server gave
is in `scores.jsonl`:

```
ana@lab:~/ml$ cat scores.jsonl
{"at": "2026-10-16T01:33:34", "customer_id": "C00007", "chance": 0.6449, "credit": true, "model": "churn-2025-12"}
{"at": "2026-10-16T01:33:35", "customer_id": "C00035", "chance": 0.0795, "credit": false, "model": "churn-2025-12"}
{"at": "2026-10-16T01:33:35", "customer_id": "C00007", "chance": 0.3843, "credit": true, "model": "churn-2025-12"}
```
