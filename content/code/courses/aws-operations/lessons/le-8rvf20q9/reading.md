---
title: Reading a secret from code, and how often
version: 1
---

The shop's API reads its database credentials when it needs a connection. Asking Secrets Manager every
time costs a call every time, and a call has a price, a latency and a quota. **Asking once and keeping
the answer for a few minutes** costs almost nothing and still picks up a new password within those
minutes. That is what this module does, in `dbconfig.py`:

```python
# dbconfig.py: the database credentials, read from Secrets Manager and kept for a while
import json
import time

import boto3

client = boto3.client("secretsmanager")
cache = {"value": None, "at": 0.0}
calls = 0


def db_credentials(max_age=300):
    global calls
    if cache["value"] is None or time.monotonic() - cache["at"] > max_age:
        raw = client.get_secret_value(SecretId="shop/prod/db")["SecretString"]
        cache["value"], cache["at"] = json.loads(raw), time.monotonic()
        calls += 1
    return cache["value"]
```

`max_age` is five minutes in production. A program to watch it work, `cache-demo.py`, sets it to two
seconds, changes the secret in the middle, and prints a **fingerprint** of the password rather than the
password, the first characters of its SHA-256, which is what a log line about a secret should carry:

```python
# cache-demo.py: three reads, one change, and how many reached Secrets Manager
import hashlib
import json
import time

import boto3

import dbconfig


def fingerprint(creds):
    return hashlib.sha256(creds["password"].encode()).hexdigest()[:8]


print("first read ", fingerprint(dbconfig.db_credentials(max_age=2)))
new = {"username": "shop", "password": "third-pass"}
boto3.client("secretsmanager").put_secret_value(SecretId="shop/prod/db", SecretString=json.dumps(new))
print("just after ", fingerprint(dbconfig.db_credentials(max_age=2)))
time.sleep(3)
print("3 s later  ", fingerprint(dbconfig.db_credentials(max_age=2)))
print("calls:", dbconfig.calls)
```

```
ana@laptop:~/aws/secrets$ python3 cache-demo.py
first read  0c4368d9
just after  0c4368d9
3 s later   7cb5cd66
calls: 2
```

The read just after the change still returns the old password, from the cache; three seconds later the
cache has expired and the new one arrives. Three reads, two calls. **During those seconds both
passwords must work**, which is exactly why rotation keeps `AWSPREVIOUS` valid until it finishes: the
database accepts the old password while every running copy of the program catches up.

## What the cache is worth

The shop's API runs 20 containers. Reading on every request, at 50 million requests a month, is 50
million calls: **250 USD a month** at 5 cents per 10,000. With a five-minute cache, each container asks
twelve times an hour: 20 × 12 × 24 × 30 = 172,800 calls, **under 0.87 USD**. The secret itself is 0.40.

Three more habits keep secrets where they belong:

- **never in an environment variable baked into an image** or a task definition in plain text; ECS and
  Lambda can inject a secret from either store by ARN at start-up, which keeps it out of the file;
- **never in a log line**, which is why the demo printed a fingerprint, and never in an exception
  message, which is where they usually leak;
- **a connection that fails with the cached password reads again at once** before failing, so a
  rotation that finished a minute ago does not wait out the five minutes.
