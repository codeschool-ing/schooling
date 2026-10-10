---
title: APIs, read page by page at the owner's pace
version: 1
---

**An API is a source you can only read the way its owner allows: in pages, at a rate, and with a
key.** Roda Livre's charges and refunds live at the payments provider, another company, and are in no
database Roda Livre owns. The only way to have them is to ask the provider's API: a program sends an
HTTP request to an address like `https://api.payments.example/v1/charges` and gets an answer in JSON.

The picture people bring is a download: one request, every charge. No API that holds more than a
screenful works that way, for a reason that is the owner's and not yours. The same servers answer
every customer of the provider, and one client asking for three years of charges in one request would
slow it for all of them. So the owner sets three rules, and a program that reads an API is mostly a
program that obeys them.

- **Pagination.** An answer carries a page of results and says how to ask for the next one, often
  with a field like `next`. The client keeps asking until there is no next page. Some APIs number the
  pages; others hand back an opaque cursor, which stays correct when rows are added while you walk,
  where page numbers can skip a row or show one twice.
- **Rate limits.** The owner allows so many requests a minute. Past that, the answer is status `429
  Too Many Requests`, often with a `Retry-After` header saying how many seconds to wait. A client that
  ignores it and retries at once is the client that gets its key suspended.
- **Authentication.** Every request carries a token that says who is asking. **The token never goes
  in the program's code**, because code is copied, shared and committed to git, and a token in a
  repository is a token anybody with the repository can use. It is read from the environment, or in
  production from a secret store that `cloud` covers.

## An API on your own machine

The lab cannot reach a payments provider, so a program stands in for one. It serves seven rides, three
to a page, on `127.0.0.1`, an address only your own machine can reach. To show a rate limit without
waiting for a real one, it refuses every third request it receives.

```schooling-example
{"language": "python", "file": "sources/api.py", "parts": [
{"code": "# sources/api.py\nimport json\nimport os\nfrom http.server import BaseHTTPRequestHandler, HTTPServer\nfrom urllib.parse import parse_qs, urlparse\n\n", "note": "Only the standard library: `http.server` answers requests, `urllib.parse` reads the address."},
{"code": "TOKEN = os.environ[\"RODA_TOKEN\"]\nRIDES = [{\"ride_id\": f\"R{n:06d}\", \"station\": f\"ST{n % 12 + 1:02d}\"} for n in range(201, 208)]\nPAGE = 3\ncalls = 0\n\n\n", "note": "The token comes from the environment, never from the code. Seven rides, three to a page, and a counter of requests received."},
{"code": "class Handler(BaseHTTPRequestHandler):\n    def do_GET(self):\n        global calls\n        calls += 1\n", "note": "`do_GET` runs once for every request."},
{"code": "        if self.headers.get(\"Authorization\") != f\"Bearer {TOKEN}\":\n            return self.reply(401, {\"error\": \"missing or wrong token\"})\n", "note": "No token, or the wrong one: `401 Unauthorized`, checked before anything else."},
{"code": "        if calls % 3 == 0:\n            return self.reply(429, {\"error\": \"too many requests\"}, {\"Retry-After\": \"1\"})\n", "note": "The staged rate limit: every third request is refused with `429` and told to wait one second."},
{"code": "        page = int(parse_qs(urlparse(self.path).query).get(\"page\", [\"1\"])[0])\n        rides = RIDES[(page - 1) * PAGE : page * PAGE]\n        last = page * PAGE >= len(RIDES)\n        self.reply(200, {\"page\": page, \"rides\": rides, \"next\": None if last else page + 1})\n\n", "note": "The page asked for in `?page=`, its slice of the rides, and `next`, which is `None` (JSON's `null`) on the last page."},
{"code": "    def reply(self, status, body, headers={}):\n        self.send_response(status)\n        for name, value in headers.items():\n            self.send_header(name, value)\n        self.send_header(\"Content-Type\", \"application/json\")\n        self.end_headers()\n        self.wfile.write(json.dumps(body).encode())\n\n    def log_message(self, *args):\n        pass\n\n\n", "note": "Every answer is JSON with a status and, sometimes, extra headers. `log_message` is silenced so the terminal shows only the client."},
{"code": "HTTPServer((\"127.0.0.1\", 8040), Handler).serve_forever()\n", "note": "Listen on port 8040 of `127.0.0.1`, which nothing outside your machine can reach, until stopped."}
]}
```

It reads its token from the environment, like the client below, so set one in the terminal and start
the server in the background. The `&` gives the terminal back while the server keeps running:

```sh
export RODA_TOKEN=lab-token-not-a-secret
python api.py &
```

The client walks the pages, waits when it is told to, and stops when `next` is empty:

```python
# sources/walk.py
import json
import os
import time
import urllib.error
import urllib.request

TOKEN = os.environ["RODA_TOKEN"]
page, rides = 1, []
while page is not None:
    request = urllib.request.Request(f"http://127.0.0.1:8040/rides?page={page}",
                                     headers={"Authorization": f"Bearer {TOKEN}"})
    try:
        with urllib.request.urlopen(request) as response:
            body = json.load(response)
    except urllib.error.HTTPError as error:
        if error.code != 429:
            raise
        wait = int(error.headers["Retry-After"])
        print(f"page {page}: 429, waiting {wait} s as the server asked")
        time.sleep(wait)
        continue
    print(f"page {page}: {[r['ride_id'] for r in body['rides']]} next={body['next']}")
    rides += body["rides"]
    page = body["next"]
print(len(rides), "rides in all")
```

```
ana@lab:~/roda/sources$ python walk.py
page 1: ['R000201', 'R000202', 'R000203'] next=2
page 2: ['R000204', 'R000205', 'R000206'] next=3
page 3: 429, waiting 1 s as the server asked
page 3: ['R000207'] next=None
7 rides in all
```

Four requests for three pages. The third was refused, the client waited the one second it was asked
to, and asked for page 3 again. Notice what the `continue` does: it goes back to the top of the loop
**without moving `page` on**, so the refused page is asked for again rather than skipped. A client that
treated the 429 as an empty page would report six rides and nothing else would complain.

Any other error is raised, and stops the program, which is what a wrong token should do. Only the last
line of the traceback is kept here:

```
ana@lab:~/roda/sources$ RODA_TOKEN=wrong python walk.py 2>&1 | tail -1
urllib.error.HTTPError: HTTP Error 401: Unauthorized
```

When you have finished, `kill %1` stops the server.

## What changes under you

An API is versioned by its owner, which is what the `v1` in the address is for: a new `v2` can change
the answers while `v1` keeps its promise for a while. The changes that hurt are the ones made inside a
version, with no new number, such as a field that was always present becoming optional or an amount in
reais becoming an amount in centavos. Nothing about the HTTP request fails. Building APIs, and keeping
those promises from the other side, is what the `apis` course is about.
