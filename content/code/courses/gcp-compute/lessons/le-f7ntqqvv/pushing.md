---
title: Pushing an image, and who lets you
version: 1
---

Pushing to Artifact Registry is `docker push` to a long address, and nearly everything that goes
wrong goes wrong before a byte is sent: Docker has to prove who you are. **gcloud solves that by
becoming Docker's credential helper for Google's registry hosts**, so that every push and pull asks
gcloud for a short-lived token instead of storing a password.

## Telling Docker to ask gcloud

This command only edits a file on your laptop, so it runs here exactly as it would with an account:

```
ana@laptop:~/gcp$ gcloud auth configure-docker southamerica-east1-docker.pkg.dev --quiet
Adding credentials for: southamerica-east1-docker.pkg.dev
Docker configuration file updated.
ana@laptop:~/gcp$ jq . ~/.docker/config.json
{
  "credHelpers": {
    "southamerica-east1-docker.pkg.dev": "gcloud"
  }
}
```

**That is all it did**: one entry in `~/.docker/config.json` saying that for
`southamerica-east1-docker.pkg.dev` Docker should run `docker-credential-gcloud`, a program that
came with the Google Cloud command line. No password was written, and none ever is. With an
account, each push would make gcloud hand Docker an OAuth token that expires within the hour. In
this lab the helper would stop at the missing account, which is why the push to Google itself is
not shown below.

On a build server, which has no person to log in, the same helper works with the server's service
account; Cloud Build needs nothing at all, because it pushes as its own identity.

## The protocol, practised on your laptop

Artifact Registry speaks the **OCI Distribution protocol**, the same HTTP API every container
registry speaks, which is why plain `docker push` works against it. `registry`, the open-source
registry you pulled in lesson 1, speaks that protocol too. **It is not Artifact Registry**: it has
no permissions, no scanning and no cleanup policies. What it shows faithfully is what a push and a
pull are.

Start it, then build a small image for the shop's web front. **Create `~/gcp/web` and save these
two files in it:**

```python
# web/app.py
from http.server import BaseHTTPRequestHandler, HTTPServer


class Hello(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'shop web 1.4.0\n')


HTTPServer(('', 8080), Hello).serve_forever()
```

```dockerfile
# web/Dockerfile
FROM python:3.12.13-slim
COPY app.py /app/app.py
CMD ["python3", "/app/app.py"]
```

```
ana@laptop:~/gcp/web$ docker run -d --name registry -p 5000:5000 registry:3.1.2
e28bf383389bf1f15f9bfcec1894aa1970a933cda96ef70311f13a16880fa9f9
ana@laptop:~/gcp/web$ docker build -q -t localhost:5000/shop/web:1.4.0 .
sha256:8d6f0bfe96db9ba0fff79d8fc46d7ceaa34c8db71506e23b4c9843ce739b42f4
ana@laptop:~/gcp/web$ docker push localhost:5000/shop/web:1.4.0
The push refers to repository [localhost:5000/shop/web]
44136fa355b3: Pushed
b3c7a9bdb4f2: Pushed
afa7bc74001e: Pushed
5a31db4cd478: Pushed
7ff48d07785c: Pushed
c85ad0bcaca8: Pushed
26c307b5e35a: Pushed
1.4.0: digest: sha256:8d6f0bfe96db9ba0fff79d8fc46d7ceaa34c8db71506e23b4c9843ce739b42f4 size: 856
```

The address is the registry's host and port, then the repository path, then the tag, which is the
same shape as an Artifact Registry address with `localhost:5000` where
`southamerica-east1-docker.pkg.dev/planner-dev` would be. **Read the last line of the push**: the
registry answered with a **digest**, the SHA-256 of the image's manifest, and section 04 is about
why that line matters more than the tag.

## What the registry now holds

The protocol is plain HTTP, so curl can ask the registry what it has:

```
ana@laptop:~/gcp/web$ curl -s localhost:5000/v2/_catalog
{"repositories":["shop/web"]}
ana@laptop:~/gcp/web$ curl -s localhost:5000/v2/shop/web/tags/list
{"name":"shop/web","tags":["1.4.0"]}
```

**Every Artifact Registry repository answers the same two questions in the same way**, behind
authentication. That is the whole contract a registry offers: names, tags and blobs addressed by
their digest.

Leave it running: section 04 uses it, and says when to stop it.
