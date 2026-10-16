---
title: A tag is a name, a digest is the image
version: 1
---

The usual picture of `shop/api:latest` is that it names an image. **It names a pointer**, and the
pointer can be moved by the next push. What identifies an image is its **digest**: `sha256:`
followed by a hash of the image's manifest, the small JSON document listing its layers. Change one
byte of one layer, and the layer's own digest changes, so the manifest changes, so the image's
digest changes. Two images with the same digest are the same image; two images with the same tag
may have nothing in common.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Two repositories side by side. In the mutable one, shop/web, the tag latest first points at build A, digest sha256:f75f, and after a second push points at build B, digest sha256:29c5; build A is left with no name. In the immutable one, shop/api, the tag 1.4.0 points at build A for good, while build B carries two tags, 1.4.1 and 3f9c2a1b7e40; a second push of 1.4.0 is refused.\"><defs><marker id=\"tag-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"16\" width=\"330\" height=\"258\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"30\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">mutable repository: shop/web</text><rect x=\"40\" y=\"70\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"85.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">latest</text><rect x=\"200\" y=\"60\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"265.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">build A</text><text x=\"265.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sha256:f75f…</text><rect x=\"200\" y=\"150\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"265.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">build B</text><text x=\"265.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sha256:29c5…</text><path d=\"M132 80 L198 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#tag-ah)\"></path><path d=\"M132 92 L160 92 L160 170 L198 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tag-ah)\"></path><text x=\"30\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Second push: the tag moves to B.</text><text x=\"30\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">A is left with no name at all.</text><rect x=\"374\" y=\"16\" width=\"330\" height=\"258\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"388\" y=\"34\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">immutable repository: shop/api</text><rect x=\"392\" y=\"70\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"447.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1.4.0</text><rect x=\"392\" y=\"140\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"447.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1.4.1</text><rect x=\"392\" y=\"182\" width=\"110\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"447.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">3f9c2a1b7e40</text><rect x=\"560\" y=\"60\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">build A</text><text x=\"625.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sha256:f75f…</text><rect x=\"560\" y=\"150\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">build B</text><text x=\"625.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sha256:29c5…</text><path d=\"M504 85 L558 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tag-ah)\"></path><path d=\"M504 155 L558 165\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tag-ah)\"></path><path d=\"M504 197 L558 185\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tag-ah)\"></path><text x=\"388\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">A second push of 1.4.0 is refused.</text></svg>", "caption": "The digests are the two builds of this lesson's lab. A mutable tag is a pointer the next push moves; an immutable one is a name given once."}
```

## What a push sends

`docker push` does two things, and only the second is about names. It uploads each layer the
registry does not have yet, as a blob addressed by its digest. Then it uploads the manifest under a
tag, and the registry records that the tag now points at the manifest's digest. Against a real
registry, from a machine with Docker, that is:

```sh
aws ecr get-login-password | docker login --username AWS --password-stdin 123456789012.dkr.ecr.sa-east-1.amazonaws.com
docker build -t 123456789012.dkr.ecr.sa-east-1.amazonaws.com/shop/api:1.4.0 .
docker push 123456789012.dkr.ecr.sa-east-1.amazonaws.com/shop/api:1.4.0
```

**Those three commands were not run for this course**: moto does not speak the registry protocol
that `docker push` uses. It does answer `PutImage`, the API call that records a manifest under a
tag, which is the last step of a push. So this lesson's lab writes two manifests by hand, as two
builds of the shop's web front would produce them, differing in the one layer where the code
changed:

```json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": {
    "mediaType": "application/vnd.oci.image.config.v1+json",
    "size": 1470,
    "digest": "sha256:9c7a54a9a43cca047013b82af109fe963fde787f63f9e016fdc3384500c2823d"
  },
  "layers": [
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "size": 29724688,
      "digest": "sha256:c6a83fedfae6ed8a4f5f7cbb6a7b6f1c1ec3d86fea8cb9e5ba2e01e6a87b2a6e"
    },
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "size": 412933,
      "digest": "sha256:3f1b0d6c4e2a8b9f7d5c3e1a0b9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c"
    }
  ]
}
```

## The tag that moved

The front's repository was created with the default, **mutable** tags. The pipeline pushes every
build as `latest`:

```
ana@laptop:~/aws/ecr$ aws ecr create-repository --repository-name shop/web --query repository.imageTagMutability
"MUTABLE"
ana@laptop:~/aws/ecr$ aws ecr put-image --repository-name shop/web --image-tag latest --image-manifest file://build-a.json --query image.imageId.imageDigest --output text
sha256:f75f6a0bd9a18e062a99e28be6c7cfd04509c65060939669e110da25bf700ad3
ana@laptop:~/aws/ecr$ diff build-a.json build-b.json
17,18c17,18
<       "size": 412933,
<       "digest": "sha256:3f1b0d6c4e2a8b9f7d5c3e1a0b9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c"
---
>       "size": 415007,
>       "digest": "sha256:7a2e9c1d5b3f8e6a7d5c3e1a0b9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c"
ana@laptop:~/aws/ecr$ aws ecr put-image --repository-name shop/web --image-tag latest --image-manifest file://build-b.json --query image.imageId.imageDigest --output text
sha256:29c52796acf6ec53f1dd957d4a08f457f117c5935c785f7cf3cdc30cecd86a94
ana@laptop:~/aws/ecr$ aws ecr describe-images --repository-name shop/web --query 'imageDetails[].[imageDigest,imageTags[0]]' --output text
sha256:29c52796acf6ec53f1dd957d4a08f457f117c5935c785f7cf3cdc30cecd86a94	latest
```

Two pushes, two digests, one tag. moto computes a digest from the layers' digests, where a registry
hashes the manifest's bytes, but the consequence is the same: different content, different digest.
**After the second push, `latest` names build B, and nothing says it ever named build A.** In ECR,
build A would still be in the repository with no tag at all, costing storage; moto dropped it.

Now picture the morning after. A task of the web front restarts and pulls `latest`, so it runs
build B, while its neighbours started yesterday still run build A. The service runs two versions
and every dashboard calls them one. Rolling back means pushing A again as `latest`, if anybody can
still find out which image A was. **A deployment that names a tag deploys whatever the tag points at
when each machine asks**, and that is the problem the next section closes.
