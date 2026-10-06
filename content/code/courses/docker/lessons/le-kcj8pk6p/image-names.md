---
title: What an image name says
version: 1
---

**A registry is a server that stores images and hands them out, and an image's name says which
registry to ask, which repository to look in and which version to take.** Lesson 3 named the
specification registries speak; this lesson uses one. First, though, the names, because most of a
name is usually left out.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"The full name docker.io/library/alpine:3.22@sha256:5291… split into parts. docker.io is the registry, the server. library is the namespace, an account or organisation. alpine is the repository. 3.22 after the colon is the tag, a movable label. sha256:5291… after the at sign is the digest, the exact content. Below, the short name alpine:3.22 fills in docker.io and library by default.\"><rect x=\"20\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">docker.io</text><text x=\"80\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">registry</text><text x=\"80\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the server</text><text x=\"145\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">/</text><rect x=\"150\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">library</text><text x=\"210\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">namespace</text><text x=\"210\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">account or org</text><text x=\"275\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">/</text><rect x=\"280\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"340\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">alpine</text><text x=\"340\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">repository</text><text x=\"340\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the image's name</text><text x=\"405\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">:</text><rect x=\"410\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"470\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">3.22</text><text x=\"470\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">tag</text><text x=\"470\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a movable label</text><text x=\"535\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">@</text><rect x=\"540\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">sha256:5291…</text><text x=\"600\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">digest</text><text x=\"600\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the exact content</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what you usually type:</text><text x=\"200\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">alpine:3.22</text><text x=\"20\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">docker fills in docker.io and library, and the tag latest if none is given</text></svg>", "caption": "Five parts, two of them usually left out. A tag can be moved to another image; a digest cannot."}
```

`alpine:3.22` is short for **`docker.io/library/alpine:3.22`**: registry `docker.io`, Docker Hub;
namespace `library`, the official images; repository `alpine`; tag `3.22`. A name with no tag means
`latest`, which lesson 16 is about. Ana can ask for the image by either name and gets the same one:

```
ana@vm:~$ docker image ls alpine
IMAGE         ID             DISK USAGE   CONTENT SIZE   EXTRA
alpine:3.22   5291449c3df7       12.8MB         3.88MB        
ana@vm:~$ docker image inspect alpine:3.22 --format "{{json .RepoDigests}}"
["alpine@sha256:5291449c3df73caf6ed85e649dec1b9e818b39a5d8c871e97afc13e9cd5e8fa8"]
ana@vm:~$ docker image inspect docker.io/library/alpine:3.22 --format "{{.Id}}"
sha256:5291449c3df73caf6ed85e649dec1b9e818b39a5d8c871e97afc13e9cd5e8fa8
ana@vm:~$ docker image inspect alpine:3.22 --format "{{.Id}}"
sha256:5291449c3df73caf6ed85e649dec1b9e818b39a5d8c871e97afc13e9cd5e8fa8
```

Two things in that output are worth knowing. **The id is the digest**: `sha256:5291…`, the same
hash lesson 3 found naming the image index. And `RepoDigests` records the digest under the
repository it came from, which is how Docker remembers which content a tag pointed to when it was
pulled.

## Tag or digest

**A tag is a label in a registry, and whoever can push to the repository can move it.** `3.22`
points at a newer build every time Alpine publishes a fix, and it should; that is what a moving tag
is for. **A digest is the hash of the content, and nobody can move it**: `alpine@sha256:5291…` names
exactly the bytes Ana has, today and in five years, on any registry that holds them.

That makes the choice of which to write a choice about who decides when things change:

| you write | you get | who decides when it changes |
| --- | --- | --- |
| `alpine` | whatever `latest` is today | the publisher, without telling you |
| `alpine:3.22` | the newest 3.22 build | the publisher, within 3.22 |
| `alpine:3.22.6` | that release, rebuilt only for fixes | the publisher, rarely |
| `alpine@sha256:5291…` | exactly these bytes | you, when you change the line |

A Dockerfile's `FROM` and a deployment's image reference are where the choice matters most, and
lesson 16 makes a habit of it. The next section pushes `shelf` to a registry of Ana's own and pulls it
back by digest.
