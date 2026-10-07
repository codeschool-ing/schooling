---
title: How much you may spend
version: 1
---

A rate limit bounds how fast money is spent; a cap bounds how much. Providers set one and let the
account set a lower one. Anthropic's, in its own words:

```
# https://platform.claude.com/docs/en/api/rate-limits, read 2026-10-05
 233: Each of the Start, Build, and Scale tiers carries a monthly spend cap, which is the
      maximum your organization can spend on the API each calendar month. You can view your
      organization's monthly spend cap and set your own limit on the
 307: Enter a new value. Your spend limit cannot exceed your current tier's cap.
 311: You have reached your specified API usage limits
```

A cap per tier, chosen by the provider, and a spend limit below it, chosen by ana. Past either, the
API refuses with a message that says so and says when access resumes. The cap is there to protect
the provider and the account's balance; **the spend limit is the one ana sets to protect herself**,
and its right value is lesson 4's monthly estimate with room for a bad week, not the tier's cap.

A router adds a narrower one. OpenRouter's documentation lists three sources of credit limits, and
the second is the one that matters to a desk with several programs:

```
# OpenRouterTeam/docs@3e840a21 api_reference/limits.mdx
 130: 2. **Per-key credit limits**, an optional spending cap configured on an individual API
      key. The `limit`, `limit_reset`, and `limit_remaining` fields in the `GET /api/v1/key`
      response above describe this cap and how much of it remains.
```

**A limit per key.** One program's key can run dry while another keeps working. The lab sets a
limit of $0.0005 on ana's OpenRouter key, and `lab/or_spend.py` sorts cases until the key stops it,
then asks the key what it has spent:

```python
import json
import os

import httpx
from openai import OpenAI, APIStatusError

base, key = os.environ["OPENROUTER_BASE_URL"], os.environ["OPENROUTER_API_KEY"]
client = OpenAI(base_url=base, api_key=key)
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")]

for n, c in enumerate(cases, 1):
    try:
        r = client.chat.completions.create(model="standin/large", messages=[
            {"role": "system", "content": prompt}, {"role": "user", "content": c["text"]}])
    except APIStatusError as e:
        print(f"request {n}: {e.status_code} {e.body['message']} ({e.body['metadata']['limit_source']})")
        break
info = httpx.get(f"{base}/key", headers={"Authorization": f"Bearer {key}"}).json()["data"]
print({k: info[k] for k in ("limit", "usage", "limit_remaining")})
```

```
ana@desk:~/desk$ python lab/or_spend.py
request 4: 402 This API key has reached its credit limit. (openrouter_key_limit)
{'limit': 0.0005, 'usage': 0.000696, 'limit_remaining': 0.0}
```

Three requests ran, the fourth was refused with a 402 that names its source, and the key's own
report says what was spent. Note `usage` against `limit`: **0.000696 spent under a limit of
0.0005.** The stand-in checks the limit before each request and charges when the request ends, so
the third request started under the limit and finished over it. OpenRouter's documentation
describes estimating each request's cost up front to narrow exactly this gap, and no cap anywhere
can be read as a promise to the cent. A limit stops the next request, not the one already running.
