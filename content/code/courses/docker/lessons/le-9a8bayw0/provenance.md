---
title: SBOMs and provenance
version: 2
---

**A scanner rebuilds the list of what is inside an image after the fact. A build can write that list
down as it happens, and say how it was made.** BuildKit does both, as **attestations** attached to
the image:

- an **SBOM**, a software bill of materials: every package and module in the image;
- a **provenance** statement: what was built, from which inputs, by which builder.

## Building with attestations

The pushes go to a registry on `127.0.0.1:5000` without a password, the kind lesson 15 started. If
your machine has none running, `docker run -d --name registry -p 127.0.0.1:5000:5000 registry:3`
starts one.

```
ana@vm:~$ cd shelf && docker build --sbom=true --provenance=mode=min --build-arg VERSION=1.6.0 -t localhost:5000/shelf:1.6.0 --push . 2>&1 | grep -E "attestation|manifest list|pushing manifest" | sort -u; cd ..
#19 exporting attestation manifest sha256:c28681d5e8a5479d48f497649f9c751c45f326c64665ae3dc2f37d6fb240cbf6
#19 exporting attestation manifest sha256:c28681d5e8a5479d48f497649f9c751c45f326c64665ae3dc2f37d6fb240cbf6 done
#19 exporting manifest list sha256:cf910c28505a72e84857dfe877a074b099f8364e9c3184b4797855c0150e1489 done
#19 pushing manifest for localhost:5000/shelf:1.6.0@sha256:cf910c28505a72e84857dfe877a074b099f8364e9c3184b4797855c0150e1489
#19 pushing manifest for localhost:5000/shelf:1.6.0@sha256:cf910c28505a72e84857dfe877a074b099f8364e9c3184b4797855c0150e1489 0.0s done
```

Two flags: `--sbom=true` runs a scanner during the build and stores what it finds, and
`--provenance=mode=min` records how the image was built. The image is pushed to Ana's registry,
because attestations are stored next to the image in a registry.

```
ana@vm:~$ docker buildx imagetools inspect localhost:5000/shelf:1.6.0
Name:      localhost:5000/shelf:1.6.0
MediaType: application/vnd.oci.image.index.v1+json
Digest:    sha256:cf910c28505a72e84857dfe877a074b099f8364e9c3184b4797855c0150e1489
           
Manifests: 
  Name:        localhost:5000/shelf:1.6.0@sha256:eeef854599e05d2c252ec21807b7d3ed3b38dd8c4cc4a6ab93da6fd602b5c2e3
  MediaType:   application/vnd.oci.image.manifest.v1+json
  Platform:    linux/amd64
               
  Name:        localhost:5000/shelf:1.6.0@sha256:c28681d5e8a5479d48f497649f9c751c45f326c64665ae3dc2f37d6fb240cbf6
  MediaType:   application/vnd.oci.image.manifest.v1+json
  Platform:    unknown/unknown
  Annotations: 
    vnd.docker.reference.digest: sha256:eeef854599e05d2c252ec21807b7d3ed3b38dd8c4cc4a6ab93da6fd602b5c2e3
    vnd.docker.reference.type:   attestation-manifest
```

**The tag names an index with two entries.** `linux/amd64` is the image. **`unknown/unknown` is not a
platform at all**: it is the attestation manifest, and its annotation names the image it describes
by digest. Docker never runs it; `docker pull` on a `linux/amd64` machine ignores it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"What the tag localhost:5000/shelf:1.6.0 points to after a build with --sbom=true and --provenance=mode=min. The tag names an image index, sha256:b1cf589fefbf. The index lists two manifests. The first, for platform linux/amd64, is the image: its config and layers, what docker run uses. The second, with platform unknown/unknown, is an attestation manifest that refers to the first by digest; its layers are two documents, an SPDX software bill of materials listing the packages and Go modules in the image, and a SLSA provenance statement naming the base images by digest and the Git revision built.\"><defs><marker id=\"l20index-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l20index-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"105\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">shelf:1.6.0</text><text x=\"95\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tag</text><path d=\"M170 130 L210 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20index-ah-wire)\"></path><rect x=\"210\" y=\"95\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"290\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">image index</text><text x=\"290\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">b1cf589fefbf</text><path d=\"M370 115 L420 70\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20index-ah-wire)\"></path><path d=\"M370 145 L420 190\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20index-ah-wire)\"></path><rect x=\"420\" y=\"30\" width=\"280\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"436\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">linux/amd64</text><text x=\"436\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the image: config and layers</text><text x=\"436\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what docker run uses</text><rect x=\"420\" y=\"150\" width=\"280\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"436\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">unknown/unknown</text><text x=\"436\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">attestations about the image above</text><text x=\"436\" y=\"213\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SBOM (SPDX): packages and modules</text><text x=\"436\" y=\"231\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">provenance (SLSA): bases, revision</text><path d=\"M560 150 L560 110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#l20index-ah-amber)\"></path><text x=\"568\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">refers to it by digest</text></svg>", "caption": "The attestations travel in the same index as the image, so whoever can pull the image can read them."}
```

## The SBOM

```
ana@vm:~$ docker buildx imagetools inspect localhost:5000/shelf:1.6.0 --format "{{json .SBOM.SPDX}}" | jq -r ".packages[] | select(.versionInfo != null) | \"\(.name) \(.versionInfo)\"" | sort
base-files 12.4+deb12u15
ca-certificates 20250419~deb12u1
example.com/shelf UNKNOWN
example.com/shelf v1.6.0
github.com/jackc/pgpassfile v1.0.0
github.com/jackc/pgservicefile v0.0.0-20240606120523-5a60cdf6a761
github.com/jackc/pgx/v5 v5.11.0
github.com/jackc/puddle/v2 v2.2.2
golang.org/x/sync v0.17.0
golang.org/x/text v0.29.0
media-types 10.0.0
netbase 6.4
stdlib go1.25.14
stdlib go1.25.14
tzdata 2026b-0+deb12u1
```

**The whole of `shelf` 1.6.0 in fifteen lines**: five Debian packages from distroless, the Go
modules from `go.mod`, the standard library twice because there are two binaries. That is the answer
lesson 14 said distroless could not give from the inside. When an advisory appears next month for
some package, an SBOM kept from each release answers "which of our images have it" without pulling
and scanning every one again.

## The provenance

```
ana@vm:~$ docker buildx imagetools inspect localhost:5000/shelf:1.6.0 --format "{{json .Provenance.SLSA}}" | jq "{dependencies: [.buildDefinition.resolvedDependencies[] | {uri, sha256: .digest.sha256[0:12]}], revision: .runDetails.metadata.buildkit_metadata.vcs.revision}"
{
  "dependencies": [
    {
      "uri": "pkg:docker/docker/buildkit-syft-scanner@stable-1?platform=linux%2Famd64",
      "sha256": "ae4f3b554449"
    },
    {
      "uri": "pkg:docker/golang@1.25?platform=linux%2Famd64",
      "sha256": "699337d62055"
    },
    {
      "uri": "pkg:docker/gcr.io/distroless/static-debian12@nonroot?platform=linux%2Famd64",
      "sha256": "afa5c872c891"
    }
  ],
  "revision": "12d9616b24830fb27b50a1fc21ad71ddd58010e6"
}
```

**The base images by digest, and the Git commit that was built.** The provenance names the exact
`golang:1.25` and distroless images used, even though the Dockerfile wrote only tags, and the
revision `12d9616…` of Ana's repository. Given an image, it says where it came from.

## Signing, which the lab cannot do

Attestations say what an image is. A **signature** says who vouches for it: whoever holds the key
signed this digest. The common tool is **Cosign**, from the Sigstore project, which signs a digest
and stores the signature in the registry beside it, and in keyless mode ties it to an identity, a
person or a CI job, instead of a long-lived key. The distroless images are signed this way, and
their documentation gives the command to check one:

```sh
cosign verify gcr.io/distroless/static-debian12:nonroot \
  --certificate-oidc-issuer https://accounts.google.com \
  --certificate-identity keyless@distroless.iam.gserviceaccount.com
```

**It was not run in the lab**, which cannot reach Sigstore's services. The point is where the check
sits: before an image is run, verify that its signature comes from the identity you expect, and
refuse it otherwise. In a cluster that check is an admission policy, the subject of lesson 25 of
the `kubernetes` course.
