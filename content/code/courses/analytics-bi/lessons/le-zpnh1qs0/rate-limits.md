---
title: Rate limits, retries and batches
version: 1
---

Every operational tool's API limits how fast it may be called, to protect itself from exactly what a
sync does: thousands of requests in a row. The pretend CRM allows ten a second. Faster than that, it
answers `429 Too Many Requests` with a `Retry-After` header. Save this as `burst.sh`; it sends thirty
requests as fast as `curl` can:

```sh
for i in $(seq 30); do
  curl -s -o /dev/null -w '%{http_code}\n' -X PUT localhost:8000/contacts/lantern-10 \
    -H 'Content-Type: application/json' -d '{"health": "lapsed"}'
done | sort | uniq -c
```

```
ana@vm:~/reverse$ bash burst.sh
      9 200
     21 429
```

Some accepted, the rest refused — how many of each depends on how fast your machine sends them. A sync
that treats `429` as a failure would mark those contacts failed and leave the CRM half updated. The
script's `send` treats it as **"not yet"**: it waits the second the header asks for and tries again, up
to five times.

Three habits make a sync a good citizen of somebody else's API:

- **Respect the limit the API states**, and its `Retry-After`. Retrying immediately makes the refusal
  last longer.
- **Retry what can succeed later, and only that.** `429` and a server error (`5xx`) may succeed in a
  minute. A `400` — the request itself is wrong — will fail identically every time; the next section is
  about those.
- **Batch where the API allows it.** Real CRMs accept a hundred or a thousand records in one request,
  and the commercial tools of lesson 8 use those bulk endpoints. One request per contact, as here, is
  what makes the first sync take minutes; it is also what makes this one readable.
