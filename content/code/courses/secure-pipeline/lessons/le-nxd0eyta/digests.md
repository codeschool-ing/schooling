---
title: A tag is a name, a digest is the thing
version: 1
---

Since lesson 8 every run pushes linkbox's image to the registry twice over: once under the commit
it was built from, and on `main` also under the tag `main`, which is what lesson 10's cluster
deploys. It is tempting to read `linkbox:main` as the name of an image. **A tag is a pointer that
anybody with push rights can move**, and the registry keeps no record of where it pointed before.
What a tag points at, at one instant, is a **digest**: the SHA-256 of the bytes of a manifest, and
those bytes cannot change without the digest changing too.

This lesson signs images, and a signature is only worth as much as the name it is attached to.
So the name comes first.

### Two tags, one digest

The project as lesson 13 left it, with its last commit built and pushed by the CI server. The
registry answers a `HEAD` request for a manifest with the digest in a header:

```
ana@vm:~$ cd linkbox
ana@vm:~/linkbox$ git log --oneline -1
de3591e a bill of materials for every image pushed
ana@vm:~/linkbox$ curl -s localhost:5000/v2/linkbox/tags/list | jq -c .tags
["de3591e","main"]
ana@vm:~/linkbox$ for tag in $(git rev-parse --short HEAD) main; do curl -sI -H "Accept: application/vnd.oci.image.index.v1+json" localhost:5000/v2/linkbox/manifests/$tag | grep -i ^docker-content-digest; done
Docker-Content-Digest: sha256:a00617f09657ec3bfa468c269aef61dcb9ee1dee6f424afcde4ca495ee8f8179
Docker-Content-Digest: sha256:a00617f09657ec3bfa468c269aef61dcb9ee1dee6f424afcde4ca495ee8f8179
```

The commit's tag and `main` give the same digest, because the push stage tagged one image twice.
The `Accept` header asks for an image index, which is what Docker 29 pushes: a list of manifests,
one per platform, and the index is what the tag points at.

**The digest is not a label somebody chose; it is computed from the bytes.** Fetch the same index
and hash it yourself:

```
ana@vm:~/linkbox$ curl -s -H "Accept: application/vnd.oci.image.index.v1+json" localhost:5000/v2/linkbox/manifests/main | sha256sum
a00617f09657ec3bfa468c269aef61dcb9ee1dee6f424afcde4ca495ee8f8179  -
ana@vm:~/linkbox$ curl -s -H "Accept: application/vnd.oci.image.index.v1+json" localhost:5000/v2/linkbox/manifests/main | jq -c ".manifests[] | {digest, platform: .platform.architecture, type: .annotations.\"vnd.docker.reference.type\"}"
{"digest":"sha256:1c98740c230f087a55c270271387b9c5e11db7bc3ea7ebc1749ba87e9fc35531","platform":"amd64","type":null}
{"digest":"sha256:a7a320e7b331469e98190e3aa18738bb6e570c8ecbecb4164da064d9f25208a1","platform":"unknown","type":"attestation-manifest"}
```

The hash `sha256sum` prints is the digest the registry sent, character for character. Anybody can
recompute it, so a registry cannot serve different bytes under a digest without the client
noticing, and `docker pull` checks exactly that. The index lists two manifests: the image for
`amd64`, and an `attestation-manifest` that `docker build` adds on its own. That second one is a
statement about how the image was built, and the attestations section of this lesson comes back
to it.

### A tag that moves

Now somebody pushes something else under `main`. Here it is the same image with one label added,
which is the smallest change there is. In the incidents lesson 12 placed on the supply chain it
was an image, an action or a release that only looked the same:

```
ana@vm:~/linkbox$ printf "FROM localhost:5000/linkbox:main\nLABEL note=rebuilt\n" | docker build -q -t localhost:5000/linkbox:main -
sha256:3a884fa97362b06e3c870c27cc3c678cb6d7acf35a0406fe8254829f81d742d6
ana@vm:~/linkbox$ docker push -q localhost:5000/linkbox:main
localhost:5000/linkbox:main
ana@vm:~/linkbox$ for tag in $(git rev-parse --short HEAD) main; do curl -sI -H "Accept: application/vnd.oci.image.index.v1+json" localhost:5000/v2/linkbox/manifests/$tag | grep -i ^docker-content-digest; done
Docker-Content-Digest: sha256:a00617f09657ec3bfa468c269aef61dcb9ee1dee6f424afcde4ca495ee8f8179
Docker-Content-Digest: sha256:3a884fa97362b06e3c870c27cc3c678cb6d7acf35a0406fe8254829f81d742d6
```

The commit's tag still names the first index. **`main` names a different digest now, and nothing
in the registry says it ever named another.** A deployment that pulls `linkbox:main` tomorrow gets
the new bytes, and so does every check that asked about `main` yesterday and wrote down "fine".

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"sp-l14-names\" aria-label=\"Two tags in the registry. The commit's tag points at the index the CI pushed, and so did main, until a second push moved main to a rebuilt image with a different digest. The signature is over the first digest, so it stays with those bytes and does not follow the tag.\"><defs><marker id=\"sp-l14-names-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l14-names-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l14-names-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tags: names anybody with push rights moves</text><text x=\"330\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">digests: computed from the bytes</text><rect x=\"20\" y=\"50\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">linkbox:&lt;commit&gt;</text><rect x=\"20\" y=\"160\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">linkbox:main</text><rect x=\"330\" y=\"50\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sha256:…</text><text x=\"430.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the image the CI pushed</text><rect x=\"330\" y=\"160\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">sha256:…</text><text x=\"430.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rebuilt, one label added</text><path d=\"M170 72 L328 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-names-ah-paper-dim)\"></path><path d=\"M170 172 L250 172 L250 90 L328 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l14-names-ah-paper-dim)\"></path><text x=\"256\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">before the push</text><path d=\"M170 192 L328 192\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-names-ah-amber)\"></path><text x=\"250\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">after it</text><rect x=\"580\" y=\"50\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">signature</text><text x=\"640.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">over this digest</text><path d=\"M578 75 L532 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-names-ah-phosphor)\"></path></svg>", "caption": "A tag points at a digest, and a push can point it elsewhere. A signature belongs to the digest, so it stays where it was."}
```

That is the whole case for the rest of this lesson, and it fits in three rules:

| | name it by | because |
|---|---|---|
| signing | the digest | a signature over a tag would follow the tag to whatever it points at next |
| verifying | the digest, or a tag resolved to one at that moment | what is checked has to be what is deployed |
| deploying | the digest that was verified | the tag can move between the check and the pull |

A digest answers "which bytes", and nothing else. It does not say who built them, from what, or
whether anybody should run them. Anybody can compute the digest of the image above, including
whoever pushed it. **Saying who vouches for a digest is the job of a signature**, and the next
section makes one.
