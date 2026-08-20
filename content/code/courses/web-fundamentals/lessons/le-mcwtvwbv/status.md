---
title: Status codes: the five families
---

The response starts with a three-digit number, and the first digit already classifies it:

- **1xx** — informational, rare day to day.
- **2xx** — it worked. `200 OK`, `201 Created`, `204 No Content`.
- **3xx** — it is somewhere else. `301` permanent, `302` temporary, `304` not modified since last time.
- **4xx** — the request is wrong. `400` malformed, `401` not authenticated, `403` authenticated but without permission, `404` does not exist, `429` asking too often.
- **5xx** — the server failed. `500` internal error, `502` the server behind answered badly, `503` down, `504` the server behind did not answer in time.

The boundary people get wrong most is 4xx against 5xx: **4xx is the caller's fault, 5xx is the responder's**. And `401` against `403`: the first says "I do not know who you are", the second says "I know who you are, and you cannot".
