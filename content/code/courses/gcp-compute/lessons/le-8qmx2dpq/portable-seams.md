---
title: Portable seams
version: 1
---

A **seam** is a place where your system meets the provider through an interface somebody else
also implements. Code that touches Google only at seams can be moved by rebuilding the other side
of each seam; code that touches Google everywhere has to be rewritten. **Designing for portability
does not mean avoiding Google's services. It means choosing where the seams are, and keeping the
code on your side of them.**

## The seams this course already uses

**The container image.** An OCI image built for Cloud Run runs unchanged on GKE, on any other
Kubernetes, on a machine with Docker, and on every other provider's container service. The contract
Cloud Run asks for (listen on `$PORT`, keep no state, exit on `SIGTERM`, lesson 8) is a contract
any of them can honour. It is the strongest seam on this list, and the reason lesson 22 put the
shop's services in containers.

**Knative's API.** Cloud Run's service description follows the Knative Serving format:
`gcloud run services describe orders --format export` prints a document with
`apiVersion: serving.knative.dev/v1`, and the same document, with Google's annotations removed, is
deployable on any Kubernetes cluster that runs Knative. That command is not run here, because it
needs an account; the format is in Google's Cloud Run reference.

**The Functions Framework.** A Cloud Run function is a Python function with a decorator, and the
decorator comes from an open-source library. Here is the smallest one the shop could use, saved as
`~/gcp/seam/main.py`:

```python
# seam/main.py
import functions_framework


@functions_framework.http
def status(request):
    return {'service': 'orders', 'status': 'ok'}
```

Start it in a terminal of its own, from `~/gcp/seam`, with
`functions-framework --target=status --port=8080`, and ask it from your working terminal:

```
ana@laptop:~/gcp/seam$ curl -s localhost:8080/
{"service":"orders","status":"ok"}
ana@laptop:~/gcp/seam$ curl -s -i localhost:8080/ | head -4
HTTP/1.1 200 OK
Server: gunicorn
Date: Fri, 30 Oct 2026 18:16:20 GMT
Connection: keep-alive
```

**That is the same program Google would run**, served by the same framework, on a laptop with no
account and no network. The `Server` header says what is underneath: gunicorn, an ordinary Python
web server, with the framework as a thin layer on top. Lesson 17 builds real functions this way. What makes it a seam is that
nothing in `main.py` says Google: the framework is the adapter, and it runs anywhere Python does.

**CloudEvents.** The events Eventarc delivers (lesson 18) are CloudEvents, a CNCF specification
with libraries in every major language. A handler written against the CloudEvents format reads the
same envelope from another provider's event router. What differs is the content: an event about a
Cloud Storage object carries Cloud Storage's fields.

## Where there is no seam

Some services have no other implementation, and the honest move is to admit it and contain it.
**Put every call to Pub/Sub, Firestore or Cloud Tasks behind one small module of your own**, named
for what the shop needs ("publish an order event", "queue a thumbnail") rather than for Google's
API. Leaving then means rewriting that module, not hunting through the code base.

What the module must not become is a framework that hides every provider behind the lowest common
denominator. That costs the features you chose Google for and still leaves the data behind. The
module is a list of the places the shop touches Google, kept short on purpose.

**Terraform is a workflow seam, not a resource seam.** The habit of describing infrastructure as
code moves with the team; the resources do not. A `google_cloud_run_v2_service` block has no
equivalent outside Google, and rewriting the configuration is part of what leaving costs.
