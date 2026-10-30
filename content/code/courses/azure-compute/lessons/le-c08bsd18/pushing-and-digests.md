---
title: Pushing, and the digest that names an image
version: 1
---

A push looks like an upload of one thing called `shop:1.0`. **A registry stores blobs named by
their SHA-256, and a small JSON document, the manifest, that lists them.** The tag is a label put
on one manifest, and the manifest's own hash, its *digest*, is the name nothing can move. This
section pushes the shop, reads what arrived through the registry's API, pulls it back by digest,
and then moves a tag to show what a digest protects you from.

## A registry on your laptop

There is no Azure registry in this course. What stands in for one is the **distribution registry**,
the open-source registry that began at Docker and is now a CNCF project, published as the image
`registry:3`. It
speaks the OCI distribution API, the same HTTP API that `shopregistry.azurecr.io` speaks to Docker,
so every request below has the same shape against ACR. It is not ACR: there is no sign-in, no
tier, no replication and no scanning, and the sections that follow say where those come in.

Start it with its storage in a named volume, so the images survive the container. `-d` keeps the
terminal free, and the prompt comes back with the container's id:

```
ana@laptop:~/azure$ docker run -d --name registry -p 5000:5000 -v shop-registry:/var/lib/registry registry:3 | cut -c1-12
a840d6e4d1a6
ana@laptop:~/azure$ curl -s -i localhost:5000/v2/ | grep -i -E '^HTTP|^docker-distribution'
HTTP/1.1 200 OK
Docker-Distribution-Api-Version: registry/2.0
```

`/v2/` is the API's front door, and the header says which version of the protocol answers.

## The push

Build the shop from lesson 7's two files, `~/azure/shop/app.py` and `~/azure/shop/Dockerfile`, and
give it a second name. **Docker reads the part of a name before the first slash as the registry to
send it to**, so `localhost:5000/shop:1.0` means the repository `shop` on the registry at
`localhost:5000`. On Azure the same tag would be `shopregistry.azurecr.io/shop:1.0`:

```
ana@laptop:~/azure$ docker build --quiet --tag shop:1.0 shop | cut -c1-19
sha256:c7b466c1bab2
ana@laptop:~/azure$ docker tag shop:1.0 localhost:5000/shop:1.0
ana@laptop:~/azure$ docker push localhost:5000/shop:1.0
The push refers to repository [localhost:5000/shop]
acca7542dfc7: Waiting
c6e0519ecc17: Waiting
220d43390895: Pushed
44136fa355b3: Pushed
f574edac59d9: Waiting
acca7542dfc7: Pushed
c6e0519ecc17: Pushed
98de7320882b: Waiting
3eb771151506: Pushed
c7660dcffdbf: Pushed
868de9318199: Pushed
98de7320882b: Pushed
f574edac59d9: Pushed
6fc242d221a6: Pushed
1.0: digest: sha256:c7b466c1bab2f4401a74c49d0cdfe202f914762789445ec19fae68aef4322bf2 size: 856
```

Each line is one blob the image needs: its layers, its configuration, and the attestation that
Docker 29 attaches to a build, a record of how it was made. The ids are the first twelve characters of each
blob's digest, and yours will differ. The last line is the one that matters. **The digest it prints
is the image's name in the registry**, and `size: 856` is the length in bytes of the document that
digest is computed from.

## Reading it back

Everything a registry holds can be read with `curl`. The catalogue lists the repositories, a
repository lists its tags, and a manifest is fetched by tag or by digest. The `Accept` header says
which kinds of manifest the client understands:

```
ana@laptop:~/azure$ curl -s localhost:5000/v2/_catalog
{"repositories":["shop"]}
ana@laptop:~/azure$ curl -s localhost:5000/v2/shop/tags/list
{"name":"shop","tags":["1.0"]}
ana@laptop:~/azure$ curl -s -I -H 'Accept: application/vnd.oci.image.index.v1+json' localhost:5000/v2/shop/manifests/1.0 | grep -i -E '^content-type|^docker-content-digest'
Content-Type: application/vnd.oci.image.index.v1+json
Docker-Content-Digest: sha256:c7b466c1bab2f4401a74c49d0cdfe202f914762789445ec19fae68aef4322bf2
ana@laptop:~/azure$ curl -s -H 'Accept: application/vnd.oci.image.index.v1+json' localhost:5000/v2/shop/manifests/1.0 | jq -c '.manifests[] | {platform: (.platform.os + "/" + .platform.architecture), digest, size}'
{"platform":"linux/amd64","digest":"sha256:ef188112e7902124d910d0993669bfd411709d9473347c83bd88d05b98e0f72f","size":1812}
{"platform":"unknown/unknown","digest":"sha256:c60204436df1843d66055ae622806de1e0e34a457dc15ca30f160bef79cd82ad","size":837}
ana@laptop:~/azure$ curl -s -H 'Accept: application/vnd.oci.image.index.v1+json' localhost:5000/v2/shop/manifests/1.0 | sha256sum
c7b466c1bab2f4401a74c49d0cdfe202f914762789445ec19fae68aef4322bf2  -
```

The document behind the tag is not one manifest but an **index**, a list of manifests, one per
platform. This one names two: the image for `linux/amd64`, 1,812 bytes, and the build attestation,
which carries `unknown/unknown` because it runs nowhere. Fed through `sha256sum`, the index's bytes
give the same 64 characters as `Docker-Content-Digest` and as the push. **Nothing else goes into a
digest**: the same bytes always give the same name, and one changed byte anywhere gives another.

The image manifest is one step further down, fetched by the digest the index gave:

```
ana@laptop:~/azure$ M=$(curl -s -H 'Accept: application/vnd.oci.image.index.v1+json' localhost:5000/v2/shop/manifests/1.0 | jq -r '.manifests[0].digest')
ana@laptop:~/azure$ curl -s -H 'Accept: application/vnd.oci.image.manifest.v1+json' localhost:5000/v2/shop/manifests/$M | jq '{mediaType, config: .config.mediaType, last_layer: .layers[-1]}'
{
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": "application/vnd.oci.image.config.v1+json",
  "last_layer": {
    "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
    "digest": "sha256:98de7320882bbf6bbb4ab9e54d8ae97ad20e3bb00c9d8cca7c1c7568b0d02b5e",
    "size": 827
  }
}
```

Its last layer is the one `COPY app.py .` made, 827 bytes of compressed archive holding the
program; the layers before it are `python:3.12-slim`'s and the `WORKDIR` line's. Every media type
here begins `application/vnd.oci`, which is how Docker 29 writes an image. Section 04 needs that
detail, because one of ACR's clean-up features reads only the older Docker media types.

## Pulling by digest

Take the digest into a variable, remove both local names, and ask for the image by digest alone:

```
ana@laptop:~/azure$ D=$(curl -s -o /dev/null -w '%header{docker-content-digest}' -H 'Accept: application/vnd.oci.image.index.v1+json' localhost:5000/v2/shop/manifests/1.0)
ana@laptop:~/azure$ echo $D
sha256:c7b466c1bab2f4401a74c49d0cdfe202f914762789445ec19fae68aef4322bf2
ana@laptop:~/azure$ docker image rm shop:1.0 localhost:5000/shop:1.0
Untagged: shop:1.0
Untagged: localhost:5000/shop:1.0
Deleted: sha256:c7b466c1bab2f4401a74c49d0cdfe202f914762789445ec19fae68aef4322bf2
ana@laptop:~/azure$ docker pull localhost:5000/shop@$D
localhost:5000/shop@sha256:c7b466c1bab2f4401a74c49d0cdfe202f914762789445ec19fae68aef4322bf2: Pulling from shop
Digest: sha256:c7b466c1bab2f4401a74c49d0cdfe202f914762789445ec19fae68aef4322bf2
Status: Downloaded newer image for localhost:5000/shop@sha256:c7b466c1bab2f4401a74c49d0cdfe202f914762789445ec19fae68aef4322bf2
localhost:5000/shop@sha256:c7b466c1bab2f4401a74c49d0cdfe202f914762789445ec19fae68aef4322bf2
ana@laptop:~/azure$ docker image ls --digests --format "{{.Repository}}  {{.Tag}}  {{.Digest}}" localhost:5000/shop
localhost:5000/shop  <none>  sha256:c7b466c1bab2f4401a74c49d0cdfe202f914762789445ec19fae68aef4322bf2
```

The image came back, and `docker image ls` lists it with no tag at all: what you hold is identified
by what it is. A name with `@sha256:` in it is accepted everywhere an image is named. Lesson 7's
container group, lesson 8's Container App and lesson 11's pods would all take
`shopregistry.azurecr.io/shop@sha256:` followed by the 64 characters.

## A tag that moves

Put the same image under `latest` as well. Every layer is already in the registry, so the push
sends nothing new, and the digest is the one `1.0` has:

```
ana@laptop:~/azure$ docker tag localhost:5000/shop@$D localhost:5000/shop:latest
ana@laptop:~/azure$ docker push localhost:5000/shop:latest | tail -n 1
latest: digest: sha256:c7b466c1bab2f4401a74c49d0cdfe202f914762789445ec19fae68aef4322bf2 size: 856
```

Now the shop's next version. Version 1.1 differs from 1.0 only in the version `/version` reports, so
its Dockerfile, in a directory of its own, starts from the image in the registry and changes one
setting. Save it as `~/azure/shop-1.1/Dockerfile`:

```dockerfile
# shop-1.1/Dockerfile
FROM localhost:5000/shop:1.0
ENV SHOP_VERSION=1.1
```

Build it, give it the tags `1.1` and `latest`, push both, and ask the registry what each tag names:

```
ana@laptop:~/azure$ cat shop-1.1/Dockerfile
# shop-1.1/Dockerfile
FROM localhost:5000/shop:1.0
ENV SHOP_VERSION=1.1
ana@laptop:~/azure$ docker build --quiet --tag localhost:5000/shop:1.1 shop-1.1 | cut -c1-19
sha256:9fc79b3f4441
ana@laptop:~/azure$ docker tag localhost:5000/shop:1.1 localhost:5000/shop:latest
ana@laptop:~/azure$ docker push localhost:5000/shop:1.1
The push refers to repository [localhost:5000/shop]
f7c6185168c9: Pushed
6fc242d221a6: Layer already exists
c6e0519ecc17: Layer already exists
c7660dcffdbf: Layer already exists
868de9318199: Layer already exists
98de7320882b: Layer already exists
44136fa355b3: Already exists
f574edac59d9: Layer already exists
acca7542dfc7: Layer already exists
3eb771151506: Layer already exists
1.1: digest: sha256:9fc79b3f4441e15f35bcec6f680ef80c729c274559aa9d2c40aff77138f93e95 size: 856
ana@laptop:~/azure$ docker push localhost:5000/shop:latest | tail -n 1
latest: digest: sha256:9fc79b3f4441e15f35bcec6f680ef80c729c274559aa9d2c40aff77138f93e95 size: 856
ana@laptop:~/azure$ for t in 1.0 1.1 latest; do printf '%-7s' $t; curl -s -o /dev/null -w '%header{docker-content-digest}\n' -H 'Accept: application/vnd.oci.image.index.v1+json' localhost:5000/v2/shop/manifests/$t; done
1.0    sha256:c7b466c1bab2f4401a74c49d0cdfe202f914762789445ec19fae68aef4322bf2
1.1    sha256:9fc79b3f4441e15f35bcec6f680ef80c729c274559aa9d2c40aff77138f93e95
latest sha256:9fc79b3f4441e15f35bcec6f680ef80c729c274559aa9d2c40aff77138f93e95
```

**One blob was pushed**, the new configuration; every layer was already there, so a release that
changes a setting or a small file costs the registry almost nothing. Then the three lines at the
end. `latest` moved to the 1.1 build, as it was told to. `1.0` names the digest it named before, to
the character, and so does every copy of that image, anywhere.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Three tags, two indexes and the blobs they name. The tag 1.0 points at index A, the build of 1.0. The tag 1.1 points at index B. latest pointed at index A until the push of 1.1 and points at index B now. Each index lists an image for linux/amd64 and a build attestation. Both images share the same layers; only their configs differ, so the push of 1.1 sent one new blob.\"><defs><marker id=\"acr-tags-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"acr-tags-ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"85\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tags, which move</text><text x=\"330\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">indexes, named by digest</text><text x=\"600\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">blobs, named by digest</text><rect x=\"20\" y=\"52\" width=\"130\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1.0</text><rect x=\"20\" y=\"132\" width=\"130\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"85\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">latest</text><rect x=\"20\" y=\"212\" width=\"130\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">1.1</text><rect x=\"230\" y=\"40\" width=\"200\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"330\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">index A, built as 1.0</text><text x=\"330\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">image for linux/amd64</text><text x=\"330\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">build attestation</text><rect x=\"230\" y=\"190\" width=\"200\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"330\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">index B, built as 1.1</text><text x=\"330\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">image for linux/amd64</text><text x=\"330\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">build attestation</text><rect x=\"500\" y=\"36\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">config of A</text><text x=\"600\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SHOP_VERSION 1.0</text><rect x=\"500\" y=\"118\" width=\"200\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the same layers</text><text x=\"600\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">python:3.12-slim, then app.py</text><rect x=\"500\" y=\"210\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"600\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">config of B</text><text x=\"600\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">SHOP_VERSION 1.1</text><path d=\"M150 70 L228 76\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#acr-tags-ah)\"></path><path d=\"M150 156 L228 214\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#acr-tags-ah)\"></path><path d=\"M150 144 L228 104\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#acr-tags-ah2)\"></path><text x=\"150\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">before 1.1</text><path d=\"M150 230 L228 236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#acr-tags-ah)\"></path><path d=\"M430 64 L498 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#acr-tags-ah)\"></path><path d=\"M430 100 L498 136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#acr-tags-ah)\"></path><path d=\"M430 210 L498 154\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#acr-tags-ah)\"></path><path d=\"M430 246 L498 234\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#acr-tags-ah)\"></path><path d=\"M40 292 L680 292\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"360\" y=\"308\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the push of 1.1 uploaded one blob: every layer was already in the registry</text></svg>", "caption": "A tag names an index, the index names images, and the images name their blobs, all by digest. Moving latest changed one pointer; nothing that index A names was touched, so anything that asks for A by digest still gets the 1.0 build."}
```

Nothing announced the move. A pull of `latest` this morning and a pull of `latest` now give two
different programs, and a cluster whose nodes pulled at different moments runs both behind one
name. A digest cannot do that, because it is computed from the bytes rather than assigned to them.
**So a deployment should name the digest**, and keep the tag for people: `1.1` tells a reader which
release it is, the digest tells the machine exactly which bytes. Section 04 shows the price of that
choice. A registry that deletes images nobody tagged will delete one a deployment still names by
digest, unless the image keeps a tag of its own.

On Azure the commands are the same with the long name in front, after `az acr login` from the
previous section. The registry stays running for section 04, which deletes something from it.
