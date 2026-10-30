---
title: The standard environment, and the file that describes it
version: 1
---

App Engine is the oldest way Google runs your code, older than Compute Engine, and it was built on
an idea that took the rest of the industry years to catch up with. **You hand over source code and
a file describing it; Google builds it, runs it, scales it and gives it an address.** There is no
machine and no container in anything you write.

## What you write

Two files for the shop's storefront, a page that greets the customer and says which version
answered. **Create `~/gcp/storefront` and save this as `main.py` in it:**

```python
# storefront/main.py
import os

from flask import Flask

app = Flask(__name__)


@app.get('/')
def home():
    version = os.environ.get('GAE_VERSION', 'local')
    return f'shop storefront, version {version}\n'
```

It is an ordinary Flask application. `GAE_VERSION` is one of the variables App Engine sets in
every instance, along with `GAE_SERVICE` and `GAE_INSTANCE`; on your laptop it is unset, and the
page says so. Then the description, **saved as `app.yaml` beside it**:

```yaml
# storefront/app.yaml
runtime: python312
entrypoint: gunicorn -b :$PORT main:app
instance_class: F1
automatic_scaling:
  max_instances: 5
```

Four lines of decision. **`runtime`** names the language and version Google will build for.
**`entrypoint`** is the command that starts the server, and App Engine sets `PORT` before running
it, exactly as Cloud Run does. **`instance_class`** is the size of each instance, and section 03
prices it. **`automatic_scaling`** says how many may run at once; `max_instances` is the ceiling
that keeps a burst from turning into a bill. A `requirements.txt` with `Flask` and `gunicorn`
completes the folder; Google's build installs what it lists.

## Running it the way App Engine will

The entrypoint is a command, so it runs on your laptop as written. In the second terminal, with
`PORT` set the way App Engine would set it:

```
ana@laptop:~/gcp/storefront$ PORT=8081 gunicorn -b :$PORT main:app
[2026-10-30 15:36:13 -0300] [6840] [INFO] Starting gunicorn 26.2.0
[2026-10-30 15:36:13 -0300] [6840] [INFO] Listening at: http://0.0.0.0:8081 (6840)
[2026-10-30 15:36:13 -0300] [6840] [INFO] Using worker: sync
[2026-10-30 15:36:13 -0300] [6844] [INFO] Booting worker with pid: 6844
[2026-10-30 15:36:13 -0300] [6840] [INFO] Control socket listening at /home/ana/.gunicorn/gunicorn.ctl
```

gunicorn says which address it bound and which worker it started, then waits. In the first
terminal:

```
ana@laptop:~/gcp/storefront$ curl -s localhost:8081/
shop storefront, version local
```

**The page answered `version local`** because nothing set `GAE_VERSION`. Deployed, the same code
answers with the version's name, and section 03 uses exactly that to show traffic moving between
two versions.

## Deploying, and where the lab stops

Deploying is one command from the folder, and here it is refused for the reason every remote
command in this course is:

```
ana@laptop:~/gcp/storefront$ gcloud app deploy
ERROR: (gcloud.app.deploy) You do not currently have an active account selected.
Please run:

  $ gcloud auth login

to obtain new credentials.

If you have already logged in with a different account, run:

  $ gcloud config set account ACCOUNT

to select an already authenticated account to use.
```

With an account, `gcloud app deploy` uploads the folder, Google builds it, and the version starts
serving at `https://planner-dev.rj.r.appspot.com`, where `rj` is the code Google gives the São
Paulo region. **The first deploy in a project also creates the App Engine application itself**,
and that step has a consequence section 05 returns to: the region you choose then is permanent.

Stop gunicorn with Ctrl+C when you are done.
