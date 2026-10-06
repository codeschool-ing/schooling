---
title: An image, opened
version: 1
---

**An image is not a mysterious binary blob: it is a handful of JSON documents and some tar
archives, each one named after the hash of its own contents.** `docker save` writes an image to a
single file in the OCI layout, and unpacking that file shows everything there is.

```
ana@vm:~$ docker save alpine:3.22 -o alpine.tar
ana@vm:~$ mkdir alpine && tar -xf alpine.tar -C alpine
ana@vm:~$ ls alpine
blobs
index.json
manifest.json
oci-layout
ana@vm:~$ jq -c . alpine/oci-layout
{"imageLayoutVersion":"1.0.0"}
```

Four entries. `oci-layout` says which version of the layout this is. `blobs/` holds the content,
and `index.json` is the way in. `manifest.json` is not part of the OCI layout: Docker writes it as
well, for older tools that expect its own format, and it is ignored below.

## Following the chain from the index

```
ana@vm:~$ jq . alpine/index.json
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.index.v1+json",
  "manifests": [
    {
      "mediaType": "application/vnd.oci.image.index.v1+json",
      "digest": "sha256:5291449c3df73caf6ed85e649dec1b9e818b39a5d8c871e97afc13e9cd5e8fa8",
      "size": 9218,
      "annotations": {
        "containerd.io/distribution.source.docker.io": "library/alpine",
        "io.containerd.image.name": "docker.io/library/alpine:3.22",
        "org.opencontainers.image.ref.name": "3.22"
      }
    }
  ]
}
```

**The index points to one thing, by its digest**: `sha256:5291…`, a document of 9218 bytes. The
annotations record what the image is called, `docker.io/library/alpine:3.22`, but the pointer is
the digest. That document lives in `blobs/sha256/` under the name of its own digest, and it is
itself an index: the list of every platform the image was published for.

```
ana@vm:~$ jq -c '.manifests[] | {platform, digest}' alpine/blobs/sha256/5291449c3df73caf6ed85e649dec1b9e818b39a5d8c871e97afc13e9cd5e8fa8
{"platform":{"architecture":"amd64","os":"linux"},"digest":"sha256:3e9b4b680bfc9fb5269227cffbd6d42be39fbf7c0b908123913864aa4447e764"}
{"platform":{"architecture":"unknown","os":"unknown"},"digest":"sha256:136a7e91b81ee0a601b537ae15392eca6a3c8f6e8496f1f256acf29160bc1fe1"}
{"platform":{"architecture":"arm","os":"linux","variant":"v6"},"digest":"sha256:450c744b1ef46c709ee72b733c54813f149999273fffb17f2097f79160aba27a"}
{"platform":{"architecture":"unknown","os":"unknown"},"digest":"sha256:f46290174829fe15483524136b84210f8782c5162afc1af82d7a72a562c39a6c"}
{"platform":{"architecture":"arm","os":"linux","variant":"v7"},"digest":"sha256:947bab19f99aef448855af6d1886613d95d311a1b8bf9d32e7b329eb76ab4e44"}
{"platform":{"architecture":"unknown","os":"unknown"},"digest":"sha256:139bbf958aa59c02fa4993f70c7d51e447dbf87fa73a037f4a1a204a0c4bbbf1"}
{"platform":{"architecture":"arm64","os":"linux","variant":"v8"},"digest":"sha256:2e1a7aa4cbc4e9e5222bb4c24a839aa1a6170ea5492d644777ce7b178824e44f"}
{"platform":{"architecture":"unknown","os":"unknown"},"digest":"sha256:5c31d531418888d654ec5f9fe128dc369ced192e8fb7bb86108ad6caad39aef7"}
{"platform":{"architecture":"386","os":"linux"},"digest":"sha256:1136d3a024321ad150667cedbb3828db613d57391e471fd87af096a88e2adce5"}
{"platform":{"architecture":"unknown","os":"unknown"},"digest":"sha256:fac6ecbe38dfc1304bd1e4f0d95b2128a9826610431f52295a013347e04cf305"}
{"platform":{"architecture":"ppc64le","os":"linux"},"digest":"sha256:d3f9354d41e5bc6cd8b4e7127860553fa3c3a76369c4bedca0b01d8922b29627"}
{"platform":{"architecture":"unknown","os":"unknown"},"digest":"sha256:e6529a469f2e9a460771b121f69a64144b326d54291a19ccd832d819dea4f90c"}
{"platform":{"architecture":"riscv64","os":"linux"},"digest":"sha256:ddd567990d0fe41158fd851e03e23f1a65c60cb9dd152afe318c9476ecb85e7f"}
{"platform":{"architecture":"unknown","os":"unknown"},"digest":"sha256:d66f3df088e46ca480666689c2011bbf82726fd784997d4c0c31693d0e726105"}
{"platform":{"architecture":"s390x","os":"linux"},"digest":"sha256:5fd1c1a839a5c24fe563cb20862fca94368fa229800ad960bdc22fe166b06d6c"}
{"platform":{"architecture":"unknown","os":"unknown"},"digest":"sha256:8b078795f726190f0ed39dfca3a05d70f376acf3c6e4275356fd69e85510e935"}
```

**One tag, many images.** `alpine:3.22` is published for `amd64`, three kinds of `arm`, `386`,
`ppc64le`, `riscv64` and `s390x`, each with its own manifest. When Ana pulls the tag, her machine
picks the entry that matches it, `amd64`, which is how the same name gives a Raspberry Pi and a
server the right binaries. The entries marked `unknown` are not platforms at all; they are
attestations about how each image was built, and lesson 20 reads them.

The `amd64` manifest is the description of one concrete image:

```
ana@vm:~$ jq . alpine/blobs/sha256/3e9b4b680bfc9fb5269227cffbd6d42be39fbf7c0b908123913864aa4447e764
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": {
    "mediaType": "application/vnd.oci.image.config.v1+json",
    "digest": "sha256:c83674e1999044d33d751661371b873539f47e5b5c5ca3320c7e0377acca6238",
    "size": 611
  },
  "layers": [
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "digest": "sha256:53f8f5e03afd86ade91b7aa57a749f5a3d1419c113be5d8c10e7ee61bb5ab887",
      "size": 3792075
    }
  ],
  "annotations": {
    "com.docker.official-images.bashbrew.arch": "amd64",
    "org.opencontainers.image.base.name": "scratch",
    "org.opencontainers.image.created": "2026-09-17T20:37:41Z",
    "org.opencontainers.image.revision": "32cb3f1f45f4fee15882936c06a264eb9e5130fe",
    "org.opencontainers.image.source": "https://github.com/alpinelinux/docker-alpine.git#32cb3f1f45f4fee15882936c06a264eb9e5130fe:x86_64",
    "org.opencontainers.image.url": "https://hub.docker.com/_/alpine",
    "org.opencontainers.image.version": "3.22.6"
  }
}
```

Two kinds of pointer. **`config`** names the configuration document; **`layers`** names the
filesystem, here a single layer of 3792075 bytes, a gzipped tar. The annotations say where the
image came from, including the exact commit of the repository that built it, which matters in
lesson 20 when the question is whether to trust an image.

The configuration holds what `docker run` uses when it is told nothing else:

```
ana@vm:~$ jq '{architecture, os, config: {Env: .config.Env, Cmd: .config.Cmd}, rootfs}' alpine/blobs/sha256/c83674e1999044d33d751661371b873539f47e5b5c5ca3320c7e0377acca6238
{
  "architecture": "amd64",
  "os": "linux",
  "config": {
    "Env": [
      "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    ],
    "Cmd": [
      "/bin/sh"
    ]
  },
  "rootfs": {
    "type": "layers",
    "diff_ids": [
      "sha256:e477571b896b8d18635f33e4efb8851e6c4929111b0a4fe9b17b34a16fd9c37f"
    ]
  }
}
```

`Cmd` is `/bin/sh`, so `docker run -it alpine:3.22` with no command opens a shell. `Env` sets the
`PATH`. And `rootfs.diff_ids` is the hash of the layer **uncompressed**, which is why it differs
from the digest in the manifest: one names the archive that travels, the other the files it
unpacks to.

The layer itself is nothing special, just a tar archive of files:

```
ana@vm:~$ tar -tzf alpine/blobs/sha256/53f8f5e03afd86ade91b7aa57a749f5a3d1419c113be5d8c10e7ee61bb5ab887 | head -8
bin/
bin/arch
bin/ash
bin/base64
bin/bbconfig
bin/busybox
bin/cat
bin/chattr
ana@vm:~$ tar -tzf alpine/blobs/sha256/53f8f5e03afd86ade91b7aa57a749f5a3d1419c113be5d8c10e7ee61bb5ab887 | wc -l
519
```

519 entries: Alpine's whole filesystem, from `bin/` down. An image with more layers has more of
these archives, each holding the files that one build step added or changed. Lesson 4 shows how
they are stacked into a single filesystem, and lesson 12 why their order matters.

## Every name is a hash

**A blob's file name is the SHA-256 of its bytes**, which anybody can check:

```
ana@vm:~$ sha256sum alpine/blobs/sha256/53f8f5e03afd86ade91b7aa57a749f5a3d1419c113be5d8c10e7ee61bb5ab887
53f8f5e03afd86ade91b7aa57a749f5a3d1419c113be5d8c10e7ee61bb5ab887  alpine/blobs/sha256/53f8f5e03afd86ade91b7aa57a749f5a3d1419c113be5d8c10e7ee61bb5ab887
```

The hash `sha256sum` computes is the name the file already had. This is called **content
addressing**, and it gives an image two properties that a version number cannot. Change one byte
and the name no longer matches; Ana appends a single character to a copy of the layer:

```
ana@vm:~$ printf x >> layer.tar.gz
ana@vm:~$ sha256sum layer.tar.gz
f447d55afdd3de928c1a9f4b3f11c855ad3f967b38852104c9ccf9b7ca3cef63  layer.tar.gz
```

A completely different hash. So a registry, a runtime or a person can check that a layer is
exactly the one the manifest named, and a manifest, which lists the digests of everything below
it, pins the whole image. **A digest names one exact image forever; a tag like `3.22` is a label
somebody can move.** Lesson 16 builds a deployment habit on that difference.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"The chain inside an OCI image. index.json points by digest to an image index for the tag alpine:3.22, which lists one manifest per platform: amd64, arm64, arm v7 and others. The amd64 manifest points to a config document and to one layer, a tar.gz of 3792075 bytes. Every arrow is a sha256 digest, and every blob is stored under the digest of its own bytes.\"><defs><marker id=\"l3chain-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l3chain-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"110\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">index.json</text><rect x=\"170\" y=\"100\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"235\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">image index</text><text x=\"235\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">alpine:3.22</text><text x=\"235\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sha256:5291…</text><rect x=\"340\" y=\"30\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"400\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">amd64</text><path d=\"M302 135 L336 50\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3chain-ah-wire)\"></path><rect x=\"340\" y=\"86\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">arm64 v8</text><path d=\"M302 135 L336 106\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3chain-ah-wire)\"></path><rect x=\"340\" y=\"142\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">arm v7</text><path d=\"M302 135 L336 162\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3chain-ah-wire)\"></path><rect x=\"340\" y=\"198\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">… and 5 more</text><path d=\"M302 135 L336 218\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3chain-ah-wire)\"></path><text x=\"400\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one manifest per platform</text><rect x=\"520\" y=\"20\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">config</text><text x=\"610\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Cmd, Env, diff_ids</text><rect x=\"520\" y=\"96\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">layer, tar.gz</text><text x=\"610\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3792075 bytes</text><path d=\"M462 50 L516 48\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3chain-ah-amber)\"></path><path d=\"M462 50 L516 122\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3chain-ah-amber)\"></path><path d=\"M132 135 L166 135\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3chain-ah-wire)\"></path><text x=\"610\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">every arrow is a sha256 digest</text></svg>", "caption": "Read from left to right, every arrow is a digest. Changing any byte on the right changes its digest, which changes the document pointing to it, all the way back to the index."}
```
