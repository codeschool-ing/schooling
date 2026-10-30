---
title: A release is rendered once and promoted unchanged
version: 1
---

**A release is a snapshot: the manifests for every target, rendered at the moment it is created,
with the image fixed by digest.** Promoting it to `prod` deploys what was rendered for `prod` when the
release was made. Nothing is rebuilt, nothing is re-rendered, and a push to the registry after the
release was created changes nothing about it. That is what makes a promotion mean something: what
reaches production is the thing that ran in `dev`, not something built again from the same commit.

The release, created at the end of the build of lesson 1, would look like this (not run):

```sh
gcloud deploy releases create rel-a1b2c3d \
  --delivery-pipeline=shop-api \
  --region=southamerica-east1 \
  --images=shop-api=southamerica-east1-docker.pkg.dev/planner-dev/shop/api:a1b2c3d
```

`--images` maps the name in the manifests to the image the build pushed, by its tag. Cloud Deploy
resolves the tag to its digest right then and renders every target with the digest, so the tag moving
later, as it did in lesson 2, cannot reach a release that already exists. The release then rolls out
to the first target, `dev`, on its own.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"A row of four boxes joined by arrows: a build produces an image identified by its digest; a release renders the manifests for every target with that digest; the dev target runs it; a promotion, gated by an approval, runs the same release on prod. Nothing is rebuilt between dev and prod.\"><defs><marker id=\"ah1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"140\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">build</text><text x=\"90\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one image</text><rect x=\"200\" y=\"40\" width=\"140\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">release</text><text x=\"270\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">manifests, rendered</text><rect x=\"380\" y=\"40\" width=\"140\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">target dev</text><text x=\"450\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">runs the digest</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">target prod</text><text x=\"630\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the same digest</text><line x1=\"162\" y1=\"70\" x2=\"198\" y2=\"70\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah1)\"></line><line x1=\"342\" y1=\"70\" x2=\"378\" y2=\"70\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah1)\"></line><line x1=\"522\" y1=\"70\" x2=\"558\" y2=\"70\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#ah1)\"></line><text x=\"540\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">approval</text><text x=\"360\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sha256:… fixed at release time, from dev to prod</text></svg>", "caption": "The release is fixed when it is created. Promotion moves it; it never rebuilds it."}
```

## The same property, on your computer

Cloud Deploy cannot run here, but the property it exists to guarantee can be shown with two
containers. Below, `dev` and `prod` are two containers on two ports, and **this is not Cloud Deploy**;
it is what a promotion leaves behind. The image the build pushed as `a1b2c3d` is pulled, and its
digest is what both environments are started from:

```
ana@laptop:~/gcp/shop$ docker pull -q localhost:5000/shop/api:a1b2c3d
localhost:5000/shop/api:a1b2c3d
ana@laptop:~/gcp/shop$ docker inspect --format '{{index .RepoDigests 0}}' localhost:5000/shop/api:a1b2c3d
localhost:5000/shop/api@sha256:2ef55b164735d434b930e807ece5ecd64f07ece1ba0a81ee34f89908a4e3f9ab
```

The local registry of lesson 2 is running again here, with the image already in it. `dev` runs the
digest and answers its health check:

```
ana@laptop:~/gcp/shop$ docker run -d --rm --name dev -p 8081:8080 localhost:5000/shop/api@sha256:2ef55b164735d434b930e807ece5ecd64f07ece1ba0a81ee34f89908a4e3f9ab
dcd13fb546667ac8fbc067d3c95e81495bf685f93fc4096c7582d44124900097
ana@laptop:~/gcp/shop$ curl -s localhost:8081/healthz; echo
{"status": "ok"}
```

Then the promotion: `prod` from the same digest, and the two containers asked which image they run:

```
ana@laptop:~/gcp/shop$ docker run -d --rm --name prod -p 8082:8080 localhost:5000/shop/api@sha256:2ef55b164735d434b930e807ece5ecd64f07ece1ba0a81ee34f89908a4e3f9ab
d46ff18324ca73a2a333a56dfe470e2d74336ab952a06f9efe36f0148fcc46c0
ana@laptop:~/gcp/shop$ docker inspect --format '{{.Name}} {{.Image}}' dev prod
/dev sha256:2ef55b164735d434b930e807ece5ecd64f07ece1ba0a81ee34f89908a4e3f9ab
/prod sha256:2ef55b164735d434b930e807ece5ecd64f07ece1ba0a81ee34f89908a4e3f9ab
ana@laptop:~/gcp/shop$ curl -s localhost:8082/healthz; echo
{"status": "ok"}
```

**One image, two environments.** If `prod` had been started from the tag after somebody pushed to it,
the two lines would differ, and the tests that passed in `dev` would say nothing about what runs in
production. Cloud Deploy's release is the record that they do not differ, kept by Google rather than by
whoever typed the command.

## What differs, and what must not

| between `dev` and `prod` | differs? |
|---|---|
| the image | **never**: one digest |
| the service name, the scale, the memory | yes, from the profile |
| the database address and the secrets' names | yes, from the profile |
| the service account that deploys | yes, from the target |

A difference in the first row is a different release, and the way to get one is a new build and a new
release, never an edit on the way to production.
