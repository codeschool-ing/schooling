"""Every list price the publishers changed since a moment, page by page."""
import json
import os
import sys
import time

import requests

URL = "http://127.0.0.1:8081/v1/prices"
HEADERS = {"X-Api-Key": os.environ["PRICES_API_KEY"]}
params = {"updated_since": sys.argv[1], "page_size": 200}
rows, pages, waits = [], 0, 0
while True:
    r = requests.get(URL, headers=HEADERS, params=params, timeout=10)
    if r.status_code == 429:
        waits += 1
        time.sleep(float(r.headers.get("Retry-After", "1")))
        continue
    r.raise_for_status()
    body = r.json()
    rows += body["data"]
    pages += 1
    if body["next_cursor"] is None:
        break
    params["cursor"] = body["next_cursor"]
with open(sys.argv[2], "w") as out:
    for row in rows:
        out.write(json.dumps(row) + "\n")
print(f"{len(rows)} prices in {pages} pages, {waits} waits for the rate limit")
