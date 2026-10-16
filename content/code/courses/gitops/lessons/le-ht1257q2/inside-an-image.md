---
title: Inside an image: an index, manifests and layers
version: 1
---

**An image is not one file.** It is a small JSON document that lists other documents and blobs by
their digests, and the registry stores each of them under its own digest. A tag is only a pointer
from a name to the document at the top. The registry's API is plain HTTP, so `curl` can read all of
it, asking for the formats it understands in the `Accept` header:

```
ana@laptop:~$ INDEX="Accept: application/vnd.oci.image.index.v1+json"
ana@laptop:~$ curl -s -H "$INDEX" localhost:5001/v2/bulletin/manifests/1.1 | jq '{mediaType, manifests: [.manifests[] | {digest, platform: .platform.architecture, type: .annotations."vnd.docker.reference.type"}]}'
{
  "mediaType": "application/vnd.oci.image.index.v1+json",
  "manifests": [
    {
      "digest": "sha256:e9d75f9598cdf367846d7fb80f8ae0688daa34e36aecd37338558c04b8f22353",
      "platform": "amd64",
      "type": null
    },
    {
      "digest": "sha256:6ecfd35cac7abcc3a7e3d49921143dffa4ac6dee4689d8e4d29400fdba606f4d",
      "platform": "unknown",
      "type": "attestation-manifest"
    }
  ]
}
```

The top of `bulletin:1.1` is an **index**: a list of manifests. One is the image for `linux/amd64`.
The other is an **attestation** that Docker added on its own when it built the image, a record of
how it was built, which lesson 8 reads. The image manifest is one level down:

```
ana@laptop:~$ IMAGE=$(curl -s -H "$INDEX" localhost:5001/v2/bulletin/manifests/1.1 | jq -r '.manifests[0].digest')
ana@laptop:~$ curl -s -H 'Accept: application/vnd.oci.image.manifest.v1+json' localhost:5001/v2/bulletin/manifests/$IMAGE | jq '{config: .config.digest, layers: [.layers[] | {digest, size}]}'
{
  "config": "sha256:3ff88186d1717fa414d32f3b6a52a2250fe3edebcd8d5645634454acad8ef473",
  "layers": [
    {
      "digest": "sha256:68fe9bff2ad4ad46da3e58db03faa64eb73c0ff16d546b0c42539eaa9854cb7f",
      "size": 2211514
    },
    {
      "digest": "sha256:c51f0f4c6579f5df8742ec674a77f7e28a2873628a62f678f9c6a96f9b50433e",
      "size": 370
    }
  ]
}
```

A config, which holds the image's settings, and two layers, each a compressed tarball of files:
BusyBox, two megabytes, and `index.cgi`, a few hundred bytes. Nothing is named except by digest and
size. The index's own digest, the one name that covers all of it, comes back in a header:

```
ana@laptop:~$ curl -sI -H "$INDEX" localhost:5001/v2/bulletin/manifests/1.1 | grep -i docker-content-digest
Docker-Content-Digest: sha256:0a8edf25732e8b60073fb97de9e9f93b1634730f19bce0b5725bc9526f818366
```

`docker buildx imagetools inspect`, part of Docker, prints the same facts in a friendlier shape and
takes the same names:

```
ana@laptop:~$ docker buildx imagetools inspect localhost:5001/bulletin:1.1
Name:      localhost:5001/bulletin:1.1
MediaType: application/vnd.oci.image.index.v1+json
Digest:    sha256:0a8edf25732e8b60073fb97de9e9f93b1634730f19bce0b5725bc9526f818366
           
Manifests: 
  Name:        localhost:5001/bulletin:1.1@sha256:e9d75f9598cdf367846d7fb80f8ae0688daa34e36aecd37338558c04b8f22353
  MediaType:   application/vnd.oci.image.manifest.v1+json
  Platform:    linux/amd64
               
  Name:        localhost:5001/bulletin:1.1@sha256:6ecfd35cac7abcc3a7e3d49921143dffa4ac6dee4689d8e4d29400fdba606f4d
  MediaType:   application/vnd.oci.image.manifest.v1+json
  Platform:    unknown/unknown
  Annotations: 
    vnd.docker.reference.digest: sha256:e9d75f9598cdf367846d7fb80f8ae0688daa34e36aecd37338558c04b8f22353
    vnd.docker.reference.type:   attestation-manifest
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"A tag points at an index. The index lists an image manifest for linux/amd64 and an attestation manifest. The image manifest lists a config and two layers, busybox and index.cgi. The attestation manifest holds the build&#x27;s provenance. Every arrow is a digest.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"330\" fill=\"var(--ink)\"/><rect x=\"15\" y=\"140\" width=\"110\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"70.0\" y=\"160.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">tag 1.1</text><text x=\"70.0\" y=\"178.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">a movable name</text><rect x=\"165\" y=\"130\" width=\"130\" height=\"70\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"230.0\" y=\"160.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">index</text><text x=\"230.0\" y=\"178.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">one per image</text><rect x=\"340\" y=\"50\" width=\"170\" height=\"60\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"425.0\" y=\"75.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">image manifest</text><text x=\"425.0\" y=\"93.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">linux/amd64</text><rect x=\"340\" y=\"220\" width=\"170\" height=\"60\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"425.0\" y=\"245.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">attestation</text><text x=\"425.0\" y=\"263.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">manifest</text><rect x=\"560\" y=\"10\" width=\"150\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"635.0\" y=\"32.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">config</text><rect x=\"560\" y=\"60\" width=\"150\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"635.0\" y=\"82.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">layer: busybox</text><rect x=\"560\" y=\"110\" width=\"150\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"635.0\" y=\"132.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">layer: index.cgi</text><rect x=\"560\" y=\"232\" width=\"150\" height=\"36\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"635.0\" y=\"254.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">provenance</text><line x1=\"125\" y1=\"165\" x2=\"153.0\" y2=\"165.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\"/><polygon points=\"161,165 153.0,160.5 153.0,169.5\" fill=\"var(--amber)\"/><line x1=\"295\" y1=\"150\" x2=\"331.7\" y2=\"91.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"336,85 327.9,89.4 335.5,94.2\" fill=\"var(--paper-dim)\"/><line x1=\"295\" y1=\"180\" x2=\"331.7\" y2=\"238.2\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"336,245 335.5,235.8 327.9,240.6\" fill=\"var(--paper-dim)\"/><line x1=\"510\" y1=\"75\" x2=\"550.4\" y2=\"33.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"556,28 547.2,30.6 553.6,36.9\" fill=\"var(--paper-dim)\"/><line x1=\"510\" y1=\"80\" x2=\"548.0\" y2=\"78.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"556,78 547.8,73.9 548.2,82.8\" fill=\"var(--paper-dim)\"/><line x1=\"510\" y1=\"85\" x2=\"550.2\" y2=\"122.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"556,128 553.2,119.2 547.1,125.8\" fill=\"var(--paper-dim)\"/><line x1=\"510\" y1=\"250\" x2=\"548.0\" y2=\"250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"556,250 548.0,245.5 548.0,254.5\" fill=\"var(--paper-dim)\"/><text x=\"440\" y=\"315\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">every arrow is a digest, except the tag's</text></svg>", "caption": "What bulletin:1.1 resolves to in this registry. The tag can be moved to another index; nothing below it can change without every digest above it changing too."}
```

**Change one byte of one layer and its digest changes, so the manifest that lists it changes, so the
index that lists the manifest changes.** A digest at the top is a promise about every byte below it,
which is why lesson 8 signs digests and not tags.
