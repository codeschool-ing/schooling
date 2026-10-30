---
title: Tags move, digests do not
version: 1
---

A tag looks like a version number, and the habit is to treat it as one: `web:1.4.0` is what was
released on Tuesday. **A tag is a pointer, and pointers move. The digest is the image itself**, the
SHA-256 of its manifest, and it cannot point at anything else, because changing one byte of the
image changes the digest.

## Watching a tag move

In `~/gcp/web`, with the registry from section 03 still running, give the image a second tag,
`latest`, push it, and ask the registry what each tag points at. The `Accept` header asks for the
manifest formats Docker pushes; the registry answers each request with the digest in a header:

```
ana@laptop:~/gcp/web$ docker tag localhost:5000/shop/web:1.4.0 localhost:5000/shop/web:latest
ana@laptop:~/gcp/web$ docker push -q localhost:5000/shop/web:latest
localhost:5000/shop/web:latest
ana@laptop:~/gcp/web$ curl -s -I -H 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json' localhost:5000/v2/shop/web/manifests/1.4.0 | grep -i docker-content-digest
Docker-Content-Digest: sha256:8d6f0bfe96db9ba0fff79d8fc46d7ceaa34c8db71506e23b4c9843ce739b42f4
ana@laptop:~/gcp/web$ curl -s -I -H 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json' localhost:5000/v2/shop/web/manifests/latest | grep -i docker-content-digest
Docker-Content-Digest: sha256:8d6f0bfe96db9ba0fff79d8fc46d7ceaa34c8db71506e23b4c9843ce739b42f4
```

**Two tags, one digest**: nothing new was stored, and `latest` is a second name for the same
bytes. Now change the program, build again with both tags, and push:

```
ana@laptop:~/gcp/web$ sed -i 's/1.4.0/1.4.1/' app.py
ana@laptop:~/gcp/web$ docker build -q -t localhost:5000/shop/web:1.4.1 -t localhost:5000/shop/web:latest .
sha256:c001e5ca49ea4d38391a3a911d4335f0268f4a7575d5f07600a1bc6631f0a7d2
ana@laptop:~/gcp/web$ docker push -q localhost:5000/shop/web:1.4.1
localhost:5000/shop/web:1.4.1
ana@laptop:~/gcp/web$ docker push -q localhost:5000/shop/web:latest
localhost:5000/shop/web:latest
ana@laptop:~/gcp/web$ curl -s -I -H 'Accept: application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json' localhost:5000/v2/shop/web/manifests/latest | grep -i docker-content-digest
Docker-Content-Digest: sha256:c001e5ca49ea4d38391a3a911d4335f0268f4a7575d5f07600a1bc6631f0a7d2
ana@laptop:~/gcp/web$ curl -s localhost:5000/v2/shop/web/tags/list
{"name":"shop/web","tags":["1.4.0","1.4.1","latest"]}
```

`latest` now points at a different digest, the image built from the changed `app.py`, while
`1.4.0` still points at the first one. Nothing announced the move. Anything that deployed
`web:latest` yesterday and is restarted today runs different code, and its configuration says the
same thing both days.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Before and after the second build. Before: the tags 1.4.0 and latest both point at the digest sha256:8d6f0bfe96db. After: 1.4.0 still points at sha256:8d6f0bfe96db, while latest and the new tag 1.4.1 point at a second digest, sha256:c001e5ca49ea. The tag latest moved; the digests did not change.\"><defs><marker id=\"f21tags-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"f21tags-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"14\" width=\"340\" height=\"222\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"24\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">after the first push</text><rect x=\"26\" y=\"70\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"71\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.4.0</text><rect x=\"26\" y=\"150\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"71\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">latest</text><rect x=\"166\" y=\"108\" width=\"168\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">sha256:8d6f0bfe96db</text><path d=\"M116 85 L164 122\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f21tags-phosphor)\"></path><path d=\"M116 165 L164 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f21tags-phosphor)\"></path><rect x=\"370\" y=\"14\" width=\"340\" height=\"222\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"384\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">after the second build</text><rect x=\"386\" y=\"56\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"431\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.4.0</text><rect x=\"386\" y=\"126\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"431\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">latest</text><rect x=\"386\" y=\"186\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"431\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">1.4.1</text><rect x=\"526\" y=\"56\" width=\"168\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">sha256:8d6f0bfe96db</text><rect x=\"526\" y=\"160\" width=\"168\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">sha256:c001e5ca49ea</text><path d=\"M476 71 L524 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f21tags-phosphor)\"></path><path d=\"M476 141 L524 176\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f21tags-amber)\"></path><path d=\"M476 201 L524 188\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#f21tags-phosphor)\"></path></svg>", "caption": "Tags are pointers into the repository and move when somebody pushes; a digest names the bytes and never points anywhere else."}
```

That is why the rule for anything that runs is **deploy by digest**,
`southamerica-east1-docker.pkg.dev/planner-dev/shop/web@sha256:…`, or at least by a tag nobody can
move. Cloud Run already does the first for you: when you deploy by tag, the revision records the
digest the tag resolved to at that moment, so a revision never changes under you; lesson 9 relies
on that.

That is the end of the registry's part; `docker rm -f registry` stops it and forgets every image
it held.

## Tags that cannot move

Artifact Registry can make that a property of the repository rather than a habit of the team:
`immutable_tags` refuses any push that would move an existing tag. And a repository that receives
an image on every commit grows without end, so it can carry **cleanup policies** that delete what
nobody needs. **Save this as `~/gcp/cleanup/main.tf`:**

```hcl
# cleanup/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.9.0"
    }
  }
}

provider "google" {
  project = "planner-dev"
  region  = "southamerica-east1"
}

resource "google_artifact_registry_repository" "shop" {
  repository_id = "shop"
  location      = "southamerica-east1"
  format        = "DOCKER"

  docker_config {
    immutable_tags = true
  }

  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }

  cleanup_policies {
    id     = "delete-old"
    action = "DELETE"
    condition {
      tag_state  = "ANY"
      older_than = "2592000s"
    }
  }
}
```

Then `terraform init` and the plan:

```
ana@laptop:~/gcp/cleanup$ terraform plan -no-color | grep -E '^  #|immutable_tags|  \+ (id|action) += "|keep_count|older_than|tag_state|^Plan:'
  # google_artifact_registry_repository.shop will be created
          + action = "DELETE"
          + id     = "delete-old"
              + older_than            = "2592000s"
              + tag_state             = "ANY"
          + action = "KEEP"
          + id     = "keep-recent"
              + keep_count            = 10
          + immutable_tags = true
Plan: 1 to add, 0 to change, 0 to destroy.
```

Two policies, and **the KEEP wins over the DELETE**: Google applies keep policies first, so the
ten most recent versions survive even when they are older than thirty days, which
`older_than = "2592000s"` is. Everything else older than that goes. Google's documentation
recommends running new policies in **dry-run** first, which logs what would be deleted without
deleting it; a policy that matches the image production runs is the one mistake here that is hard
to undo.

With immutable tags, `latest` itself can no longer move, which is the point: a team that turns them
on stops pushing `latest` and deploys version tags or digests, and the move you watched at the start of
this section cannot happen.
