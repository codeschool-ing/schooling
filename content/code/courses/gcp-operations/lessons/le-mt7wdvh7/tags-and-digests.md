---
title: A tag is a label that moves; a digest is the image
version: 1
---

**A tag points at an image, and pushing again moves it. A digest is the image's own fingerprint, and
it cannot point at anything else.** A digest is the SHA-256 of the image's manifest, so two
different images cannot share one, and the same image has the same digest in every registry it is
copied to. A deployment that names a tag runs whatever the tag points at when it pulls; a deployment
that names a digest runs one image, always.

Build the shop's API under a tag in the local registry, push it, and ask Docker for the digest the
registry gave back:

```sh
docker build -q -t localhost:5000/shop/api:v1 api
```

```
ana@laptop:~/gcp/shop$ docker push -q localhost:5000/shop/api:v1
localhost:5000/shop/api:v1
ana@laptop:~/gcp/shop$ docker inspect --format '{{index .RepoDigests 0}}' localhost:5000/shop/api:v1
localhost:5000/shop/api@sha256:7f5dda35d7b5b73891a2a410b56bcdae89b0bb7cb243b2e9be4fdd882f36d1f7
```

Now change the code. Add a third product to `PRODUCTS` in `api/app.py`, below the pencil case:

```python
    {"id": "p-003", "name": "Eraser", "price_cents": 390},
```

Build it again under **the same tag**, and push it:

```
ana@laptop:~/gcp/shop$ grep -c price_cents api/app.py
3
ana@laptop:~/gcp/shop$ docker push -q localhost:5000/shop/api:v1
localhost:5000/shop/api:v1
ana@laptop:~/gcp/shop$ docker inspect --format '{{index .RepoDigests 0}}' localhost:5000/shop/api:v1
localhost:5000/shop/api@sha256:f35a09acfff5676670ca95f02f72479bbc8a1173d716feb33787ae3a89e18c1d
ana@laptop:~/gcp/shop$ curl -s localhost:5000/v2/shop/api/tags/list; echo
{"name":"shop/api","tags":["v1"]}
```

The registry accepted the second push without a word. There is still one tag, `v1`, and it now
points at a different image, `f35a…`. **Anything that pulls `v1` from now on gets the eraser**,
including a machine that restarts tomorrow running what it believes is yesterday's release, and a
rollback "to v1" that rolls forward instead. Nothing in either push said anything had moved.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"The tag v1 is drawn twice. Before the second push, it points at the image with digest sha256:7f5d, which holds two products. After the push, it points at sha256:f35a, which holds three. The first image is still in the registry, untagged, and reachable by its digest.\"><defs><marker id=\"ah1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">the same tag, before and after the second push</text><rect x=\"20\" y=\"60\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"65\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">v1</text><text x=\"65\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">before</text><rect x=\"20\" y=\"130\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"65\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">v1</text><text x=\"65\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">after</text><rect x=\"300\" y=\"50\" width=\"400\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sha256:7f5dda35…</text><text x=\"500\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">two products; untagged after the push</text><rect x=\"300\" y=\"120\" width=\"400\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sha256:f35a09ac…</text><text x=\"500\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">three products</text><line x1=\"112\" y1=\"75\" x2=\"298\" y2=\"75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah1)\"></line><line x1=\"112\" y1=\"145\" x2=\"298\" y2=\"145\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah1)\"></line></svg>", "caption": "Pushing again moved the label. Both images are still there; only one has a name."}
```

The first image is not gone. The tag left it, and it can still be pulled by its digest:

```
ana@laptop:~/gcp/shop$ docker pull -q localhost:5000/shop/api@sha256:7f5dda35d7b5b73891a2a410b56bcdae89b0bb7cb243b2e9be4fdd882f36d1f7
localhost:5000/shop/api@sha256:7f5dda35d7b5b73891a2a410b56bcdae89b0bb7cb243b2e9be4fdd882f36d1f7
ana@laptop:~/gcp/shop$ docker run --rm -d --name api -p 8080:8080 localhost:5000/shop/api@sha256:7f5dda35d7b5b73891a2a410b56bcdae89b0bb7cb243b2e9be4fdd882f36d1f7
854df6e7fd771402869f6a6bca79c31816ac8a03d02629fd9ff5ddf4760e7f5d
ana@laptop:~/gcp/shop$ curl -s localhost:8080/products; echo
[{"id": "p-001", "name": "Notebook", "price_cents": 2490}, {"id": "p-002", "name": "Pencil case", "price_cents": 1890}]
```

Two products: the image from before the change, exactly. An image whose tags have all moved away is
**untagged**, and it is the kind of image a cleanup policy deletes in the next section.

## Which one to write where

| where | write | why |
|---|---|---|
| a build's `images` and its push | a tag from the commit, `$SHORT_SHA` | a person can read which commit an image came from |
| a deployment, a release, a Kubernetes manifest | the digest | what runs cannot change under it |
| a person's conversation | the tag | nobody reads a digest aloud |

Cloud Run already does the second for you: a revision records the digest the tag pointed at when the
revision was created, so a later push to the tag does not change a running revision. A Compute Engine
machine with a startup script that pulls `:latest` does not, and lesson 3 deploys by digest for this
reason.
