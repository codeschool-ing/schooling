---
title: A build is a list of containers sharing one directory
version: 1
---

**Cloud Build runs a build as a series of containers, one per step, and every step sees the same
directory, `/workspace`.** That is the whole model. There is no build server with tools installed
on it and no state left over from yesterday: each step names an image, Cloud Build pulls it, runs
it with your source mounted at `/workspace`, and moves to the next step when it exits with status
0. A step that exits with anything else stops the build. What one step writes into `/workspace`,
the next step can read, and that is the only thing that passes between them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Three step containers in a row, test, build and push, each joined by a dashed line to one shared directory, /workspace, which holds the repository. An arrow between steps is labelled exit 0. A step that exits with anything else ends the build as FAILURE.\"><defs><marker id=\"ah1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">one build, three containers, one directory</text><rect x=\"20\" y=\"44\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">step test</text><text x=\"110\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">python:3.12.16-slim</text><line x1=\"110\" y1=\"100\" x2=\"110\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><rect x=\"270\" y=\"44\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">step build</text><text x=\"360\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">cloud-builders/docker</text><line x1=\"360\" y1=\"100\" x2=\"360\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><rect x=\"520\" y=\"44\" width=\"180\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">after the last step</text><text x=\"610\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">push images</text><line x1=\"610\" y1=\"100\" x2=\"610\" y2=\"150\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><line x1=\"202\" y1=\"72\" x2=\"268\" y2=\"72\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah1)\"></line><text x=\"235.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">exit 0</text><line x1=\"452\" y1=\"72\" x2=\"518\" y2=\"72\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah1)\"></line><text x=\"485.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">exit 0</text><rect x=\"20\" y=\"150\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/workspace</text><text x=\"20\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">any other exit status: the build stops here, as FAILURE, and nothing is pushed</text></svg>", "caption": "Each step is a new container from its own image. Only /workspace survives from one to the next."}
```

The common wrong picture is of a machine with a long script, like a laptop that somebody keeps
tidy. The containers are why that picture fails: a step cannot install a tool for the steps after
it, because the next step starts from its own image. A tool you need in three steps is in the image
of all three.

## The shop's API

This course operates a small shop. Its API is one Python file with two routes, written with the
standard library only, so that nothing has to be installed to run it. Create the directory
`~/gcp/shop/api` and put these four files in it:

```python
# shop/api/app.py
import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

PRODUCTS = [
    {"id": "p-001", "name": "Notebook", "price_cents": 2490},
    {"id": "p-002", "name": "Pencil case", "price_cents": 1890},
]


def route(path):
    if path == "/healthz":
        return 200, {"status": "ok"}
    if path == "/products":
        return 200, PRODUCTS
    return 404, {"error": "not found"}


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        status, body = route(self.path)
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(data)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    HTTPServer(("", port), Handler).serve_forever()
```

```python
# shop/api/test_app.py
import unittest

from app import route


class RouteTest(unittest.TestCase):
    def test_health(self):
        self.assertEqual(route("/healthz"), (200, {"status": "ok"}))

    def test_products_have_prices_in_cents(self):
        status, body = route("/products")
        self.assertEqual(status, 200)
        self.assertTrue(all(isinstance(p["price_cents"], int) for p in body))

    def test_unknown_path(self):
        self.assertEqual(route("/nope")[0], 404)
```

```dockerfile
# shop/api/Dockerfile
FROM mirror.gcr.io/library/python:3.12.16-slim
WORKDIR /app
COPY app.py .
USER nobody
ENV PORT=8080
CMD ["python", "app.py"]
```

The image comes from `mirror.gcr.io`, Google's copy of Docker Hub's official images. It is the
same image Docker Hub serves, and pulling it from Google's mirror avoids Docker Hub's limit on
anonymous pulls, which a build machine shared by many people reaches quickly. **Prices are in
cents, as integers**, which the second test holds; lesson 23 comes back to why money is never a
float.

## The build file

The build is described in `cloudbuild.yaml`, at the root of the repository, one level above the
API:

```yaml
# shop/cloudbuild.yaml
steps:
  - id: test
    name: mirror.gcr.io/library/python:3.12.16-slim
    dir: api
    entrypoint: python
    args: ["-m", "unittest", "-v"]

  - id: build
    name: gcr.io/cloud-builders/docker
    args:
      - build
      - -t
      - ${_REGION}-docker.pkg.dev/$PROJECT_ID/shop/api:$SHORT_SHA
      - api

images:
  - ${_REGION}-docker.pkg.dev/$PROJECT_ID/shop/api:$SHORT_SHA

substitutions:
  _REGION: southamerica-east1

serviceAccount: projects/planner-dev/serviceAccounts/shop-build@planner-dev.iam.gserviceaccount.com
options:
  logging: CLOUD_LOGGING_ONLY
```

Read it from the top:

- **`steps`** is the list, run in order. Each step has an `id` you choose, the `name` of the image
  it runs, and the `args` handed to it. `dir` is a directory inside `/workspace` to start in, and
  `entrypoint` replaces the image's own command.
- **`gcr.io/cloud-builders/docker`** is an image Google publishes for builds, with the Docker
  client in it. Cloud Build gives a step the Docker daemon of the build machine, so this step builds
  an image that later steps, and the `images` list, can see.
- **`images`** lists the images Cloud Build pushes to the registry once every step has succeeded,
  and records them in the build's result. An image a step builds and nobody lists is thrown away
  with the machine.
- **`$PROJECT_ID`, `$SHORT_SHA` and `${_REGION}`** are substitutions, which the next section is
  about.
- **`serviceAccount`** names the identity the steps act as. Lesson 8 of `gcp-foundations` is about
  why a build should not run as an account that can do everything, and `options.logging` is not
  optional here: with a service account of your own, Cloud Build refuses the build until you say
  where its logs go, and `CLOUD_LOGGING_ONLY` sends them to Cloud Logging, which lesson 9 reads.

## The same steps, by hand

**Nothing on your computer runs a `cloudbuild.yaml`.** Google once published a tool that did,
`cloud-build-local`, and retired it; no emulator replaces it. What you can do is what each step
does: run its image with the repository mounted at `/workspace`. That is not Cloud Build, and it
shows nothing about triggers, permissions or logs, but it is exactly what one step is:

```
ana@laptop:~/gcp/shop$ find . -type f | sort
./api/Dockerfile
./api/app.py
./api/test_app.py
./cloudbuild.yaml
```

The first step runs the tests in the Python image, from `/workspace/api`:

```
ana@laptop:~/gcp/shop$ docker run --rm -v "$PWD":/workspace -w /workspace/api mirror.gcr.io/library/python:3.12.16-slim python -m unittest -v
test_health (test_app.RouteTest.test_health) ... ok
test_products_have_prices_in_cents (test_app.RouteTest.test_products_have_prices_in_cents) ... ok
test_unknown_path (test_app.RouteTest.test_unknown_path) ... ok

----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

`unittest` exits with 0, so the build would carry on. Had a test failed, it would have exited
with 1, Cloud Build would have marked the step and the build `FAILURE`, and the second step would
never have started. **That is the only gate a build has**: an exit status.

The second step builds the image under the name the registry will know it by, here with the tag
`local` in place of a commit, and the container it makes answers like the API should:

```
ana@laptop:~/gcp/shop$ docker build -q -t southamerica-east1-docker.pkg.dev/planner-dev/shop/api:local api
sha256:016bb774b74e180f15317c580c6ece56e1e90b9ccbc9a5c6cb4f536a0b9e7286
ana@laptop:~/gcp/shop$ docker run -d --rm --name api -p 8080:8080 southamerica-east1-docker.pkg.dev/planner-dev/shop/api:local
1c46ce94c2c672e080330043e42791557473884c32c1e3cbe17f50020402a536
ana@laptop:~/gcp/shop$ curl -s localhost:8080/products; echo
[{"id": "p-001", "name": "Notebook", "price_cents": 2490}, {"id": "p-002", "name": "Pencil case", "price_cents": 1890}]
```

**The image's name is an address**: `southamerica-east1-docker.pkg.dev` is Artifact Registry in São
Paulo, `planner-dev` the project, `shop` a repository and `api` the image inside it. Lesson 2 pushes
to an address of that shape. On Cloud Build the push happens after the last step, because the image
is in `images`; here nothing was pushed, and the image stays on your computer.
