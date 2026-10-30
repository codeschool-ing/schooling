---
title: Reading a secret at run time
version: 1
---

**The API reads its password when it starts, from a file the platform puts there, and never from its own
image or repository.** Cloud Run can expose a secret version to a container two ways: as an **environment
variable**, resolved once when the instance starts, or as a **file in a mounted volume**, which Cloud Run keeps
pointing at the version it names. Either way the code reads a value at run time, and the image holds only the
name of where to look. Neither ran here; what runs is the same shape with Docker, where a file you write
stands for the volume Cloud Run would mount.

The program reads the file whose path it is given, and says what it found without printing it. Write it into
`~/gcp/readsecret.py`:

```python
# readsecret.py
import os
import pathlib

path = pathlib.Path(os.environ.get("DB_PASSWORD_FILE", "/secrets/db-password"))
password = path.read_text().strip()
print(f"read {len(password)} characters from {path}, starting with {password[:2]}…")
```

Then create `~/gcp/secrets/db-password` with a practice value in it, and mount that directory read-only where
Cloud Run would mount the secret:

```
ana@laptop:~/gcp$ docker run --rm -v "$PWD/secrets":/secrets:ro -v "$PWD/readsecret.py":/app/readsecret.py:ro mirror.gcr.io/library/python:3.12.16-slim python /app/readsecret.py
read 19 characters from /secrets/db-password, starting with k7…
```

**The program prints the length and two characters, never the value.** A secret printed in a log is a secret in
Cloud Logging, readable by everybody with `roles/logging.viewer` and kept for as long as the bucket of lesson 9
keeps it. Debugging a connection string by printing it is the commonest way a password leaves Secret Manager.

## Environment variable or file

| | environment variable | mounted file |
|---|---|---|
| when it is read | once, when the instance starts | by the code, whenever it opens the file |
| a new version | reaches only instances started after it | reaches the file of a running instance if the mount names `latest` |
| visible to | anything that can read the process's environment, including a crash report that dumps it | the process reading the file |

The shop mounts files, for the second and third rows: a running instance picks up a rotated password without a
restart, as long as the code reads the file again on a failed connection, and nothing that dumps the environment
dumps the password. **Pin a version number, not `latest`, for anything where an unreviewed change would break
production**; `latest` is right for a password that a rotation job replaces on purpose.
