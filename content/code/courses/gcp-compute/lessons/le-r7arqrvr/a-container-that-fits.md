---
title: A container that fits, built and run at home
version: 1
---

The shop's orders service is the program the next four lessons deploy, split, schedule and load.
**It is deliberately small: about fifty lines of Python with no dependencies, and a Dockerfile of
five lines.** Everything in it is there because the contract of the last section asks for it, and
nothing in it is specific to Google.

## The program

**Create a folder `orders` in `~/gcp` and save this as `app.py` in it:**

```python
# orders/app.py
"""The shop's orders service: a small HTTP API that keeps Cloud Run's contract."""
import json
import os
import signal
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ORDERS = [
    {'id': 1001, 'item': 'notebook', 'quantity': 2},
    {'id': 1002, 'item': 'pencil', 'quantity': 12},
]
DELAY = int(os.environ.get('ORDERS_DELAY_MS', '0')) / 1000


def log(message):
    print(json.dumps({'severity': 'INFO', 'message': message}), flush=True)


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.reply(200, {'status': 'ok'})
        elif self.path == '/orders':
            time.sleep(DELAY)
            self.reply(200, {'orders': ORDERS, 'revision': os.environ.get('K_REVISION', 'local')})
        else:
            self.reply(404, {'error': 'not found'})

    def reply(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):
        log(fmt % args)


def stop(signum, frame):
    log('SIGTERM: shutting down')
    sys.exit(0)


if __name__ == '__main__':
    signal.signal(signal.SIGTERM, stop)
    port = int(os.environ.get('PORT', '8080'))
    server = ThreadingHTTPServer(('0.0.0.0', port), Handler)
    log(f'listening on {port}')
    server.serve_forever()
```

Read it against the contract. **The port comes from `PORT`**, with 8080 when nothing sets it, and
the server binds to `0.0.0.0`, every interface of the container. **Logs are one JSON object per
line on standard output**, which Cloud Logging reads as structured entries with a `severity`, so a
warning stays a warning in the console instead of becoming text. **`SIGTERM` is handled**: the
handler logs one line and exits at once, well inside the ten seconds the platform allows.

Three details are there for later lessons. `ThreadingHTTPServer` answers each request on a thread
of its own, so one instance serves several requests at once; lesson 11 measures what that buys.
`ORDERS_DELAY_MS` makes `/orders` wait before answering, a stand-in for the database call a real
service would make, and it is zero unless set. And the answer carries `K_REVISION`, a variable
Cloud Run sets to the name of the revision serving the request, which lesson 9 reads while it
splits traffic; at home it says `local`.

## The image

Save this as `Dockerfile` in the same folder:

```dockerfile
# orders/Dockerfile
FROM python:3.12.13-slim
WORKDIR /app
COPY app.py .
USER nobody
CMD ["python3", "app.py"]
```

`CMD` is written in the **exec form**, a JSON list, so `python3` itself is the container's first
process and receives `SIGTERM` directly; section 04 shows what the other form costs. `USER nobody`
runs the program without root, which costs nothing here because it writes no file. Build it from
`~/gcp`:

```
ana@laptop:~/gcp$ docker build -q -t orders:1 orders
sha256:fe71508314d462d9a3951a947556bd36a83f51dc4b03f31e244ba11d4760a6a0
ana@laptop:~/gcp$ docker image ls orders:1 --format "{{.Repository}}:{{.Tag}}  {{.Size}}"
orders:1  177MB
```

`-q` prints only the image's id. **About 180 MB, nearly all of it the Python base image**; the
program adds a few kilobytes. Cloud Run pulls an image from Artifact Registry when it starts an
instance, which lesson 21 is about, and a smaller image starts sooner; lesson 11 puts a number on
how much that matters and how much it does not.
