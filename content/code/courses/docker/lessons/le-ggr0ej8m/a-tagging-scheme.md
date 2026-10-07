---
title: A scheme for tags
version: 1
---

**A good set of tags answers two questions: which release is this, and which commit was it built
from.** One build can carry several tags, so it can answer both at once. Ana's convention is the
common one:

| tag | names | moves when |
| --- | --- | --- |
| `1.2.3` | one release | never, by agreement |
| `1.2` | the newest `1.2.x` | a patch is released |
| `1` | the newest `1.x.y` | a minor or patch release |
| `sha-12d9616` | the commit it was built from | never |

The first and the last name one build. The two in the middle are moving tags on purpose, like
`alpine:3.22` in lesson 15: someone who writes `shelf:1.2` asks for fixes without new features.

## Labels: what the image says about itself

**Tags live in the registry; labels live in the image.** A tag can be removed or moved, and an image
copied to another registry arrives with none of its old tags, but its labels travel with it.
The Open Container Initiative names a standard set, `org.opencontainers.image.*`, and Ana's final
stage now carries five of them, filled from build arguments:

```dockerfile
FROM golang:1.25 AS build
WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ vendor/
RUN go build net/http github.com/jackc/pgx/v5/pgxpool
COPY *.go ./
ARG VERSION=dev
RUN CGO_ENABLED=0 go build -ldflags "-X main.version=${VERSION}" -o /out/shelf .

FROM gcr.io/distroless/static-debian12:nonroot
ARG VERSION=dev
ARG REVISION=unknown
ARG CREATED
LABEL org.opencontainers.image.title="shelf" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.created="${CREATED}" \
      org.opencontainers.image.source="https://git.example.com/ana/shelf"
COPY --from=build /out/shelf /shelf
USER 65532:65532
CMD ["/shelf"]
```

**The labels are in the final stage**, after its `FROM`, because labels written in the build stage
stay in the build stage. The `ARG` lines are repeated there for the same reason: an argument is
visible only in the stage that declares it.

## One build, four tags

The revision and the date come from git, so they describe the commit rather than the moment of the
build:

```
ana@vm:~/shelf$ git log -1 --format="%h %cI %s"
12d9616 2026-09-01T10:00:00-03:00 shelf: the catalogue over HTTP
ana@vm:~/shelf$ REV=$(git rev-parse --short HEAD); CREATED=$(git log -1 --format=%cI)
ana@vm:~/shelf$ docker build -q --build-arg VERSION=1.2.3 --build-arg REVISION=$REV --build-arg CREATED=$CREATED -t localhost:5000/shelf:1.2.3 -t localhost:5000/shelf:1.2 -t localhost:5000/shelf:1 -t localhost:5000/shelf:sha-$REV .
sha256:7c24c08ea6d316d91b9349afaeba3ba36fc6ac1873f06bba05ba947cd3f8fabf
ana@vm:~/shelf$ docker image inspect localhost:5000/shelf:1.2.3 --format "{{json .Config.Labels}}" | jq .
{
  "org.opencontainers.image.created": "2026-09-01T10:00:00-03:00",
  "org.opencontainers.image.revision": "12d9616",
  "org.opencontainers.image.source": "https://git.example.com/ana/shelf",
  "org.opencontainers.image.title": "shelf",
  "org.opencontainers.image.version": "1.2.3"
}
```

Four `-t` flags, one build, one id. `docker push --all-tags` sends every tag of the repository, and the
registry lists them:

```
ana@vm:~/shelf$ docker push -q --all-tags localhost:5000/shelf
localhost:5000/shelf
ana@vm:~/shelf$ curl -s localhost:5000/v2/shelf/tags/list
{"name":"shelf","tags":["1","1.2","1.2.3","latest","sha-12d9616"]}
```

`latest` is still there from the previous section, pointing at 1.1.0, because nothing since has
named it. That is the honest state of a `latest` nobody maintains.

## A patch release moves the right tags

A fix ships as 1.2.4. Ana tags the new build `1.2.4`, `1.2` and `1`, and not `1.2.3`:

```
ana@vm:~/shelf$ docker build -q --build-arg VERSION=1.2.4 --build-arg REVISION=$REV --build-arg CREATED=$CREATED -t localhost:5000/shelf:1.2.4 -t localhost:5000/shelf:1.2 -t localhost:5000/shelf:1 .
sha256:9b514dcad08cf5896925b29f3f2fa0f9fcb25bedf6cb9ffeb1b28b9da1f8c2e4
ana@vm:~/shelf$ docker push -q --all-tags localhost:5000/shelf
localhost:5000/shelf
ana@vm:~/shelf$ for t in 1.2.3 1.2.4 1.2 1 sha-$REV latest; do printf "%-12s %s\n" $t $(digest $t); done
1.2.3        sha256:7c24c08ea6d3
1.2.4        sha256:9b514dcad08c
1.2          sha256:9b514dcad08c
1            sha256:9b514dcad08c
sha-12d9616  sha256:7c24c08ea6d3
latest       sha256:613066b36b4c
```

The function `digest` asks the registry what each tag points at, the way lesson 15 did with `curl`,
and prints the first characters. **`1.2.3` and `sha-12d9616` still name the old build; `1.2` and
`1` moved to the new one.** Everything that asked for `1.2` gets the fix on its next pull, and
everything that pinned `1.2.3` keeps exactly what it tested.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"Six tags in Ana&#x27;s registry and the three images they point to. 1.2.3 and sha-12d9616 point to sha256:7c24c08ea6d3, shelf 1.2.3. 1.2.4, 1.2 and 1 point to sha256:9b514dcad08c, shelf 1.2.4; before the patch release, 1.2 and 1 pointed to the 1.2.3 image. latest points to sha256:613066b36b4c, shelf 1.1.0, because nothing pushed since named it. 1.2.3, 1.2.4 and sha-12d9616 are drawn as fixed tags, 1.2, 1 and latest as moving ones.\"><defs><marker id=\"l16tags-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l16tags-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40\" y=\"30\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">1.2.3</text><path d=\"M180 45 L420 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16tags-ah-phosphor)\"></path><rect x=\"40\" y=\"70\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">sha-12d9616</text><path d=\"M180 85 L420 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16tags-ah-phosphor)\"></path><rect x=\"40\" y=\"130\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">1.2.4</text><path d=\"M180 145 L420 185\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16tags-ah-phosphor)\"></path><rect x=\"40\" y=\"170\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"110\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">1.2</text><path d=\"M180 185 L420 185\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16tags-ah-amber)\"></path><rect x=\"40\" y=\"210\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"110\" y=\"229\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">1</text><path d=\"M180 225 L420 185\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16tags-ah-amber)\"></path><rect x=\"40\" y=\"260\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"110\" y=\"279\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">latest</text><path d=\"M180 275 L420 275\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l16tags-ah-amber)\"></path><path d=\"M180 185 L420 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><path d=\"M180 225 L420 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><rect x=\"420\" y=\"43\" width=\"260\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"440\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sha256:7c24c08ea6d3</text><text x=\"440\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shelf 1.2.3</text><rect x=\"420\" y=\"163\" width=\"260\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"440\" y=\"181\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sha256:9b514dcad08c</text><text x=\"440\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shelf 1.2.4</text><rect x=\"420\" y=\"253\" width=\"260\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"440\" y=\"271\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sha256:613066b36b4c</text><text x=\"440\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shelf 1.1.0</text><rect x=\"40\" y=\"312\" width=\"24\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"72\" y=\"323\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fixed: names one build</text><rect x=\"260\" y=\"312\" width=\"24\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"292\" y=\"323\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">moving: follows the newest</text><path d=\"M480 319 L510 319\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"518\" y=\"323\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">before the 1.2.4 push</text></svg>", "caption": "After the 1.2.4 push. A fixed tag is fixed by habit: the registry let Ana push over 1.2.3 as well."}
```

## A fixed tag is fixed by convention

Nothing above stopped anybody. Ana builds something else and pushes it as `1.2.3`:

```
ana@vm:~/shelf$ docker build -q --build-arg VERSION=9.9.9 -t localhost:5000/shelf:1.2.3 .
sha256:f8c6d16d0587c47ffb43bcb07c1c119bc983bdd81a51b0bdc4a2ff229fbfac14
ana@vm:~/shelf$ docker push -q localhost:5000/shelf:1.2.3
localhost:5000/shelf:1.2.3
ana@vm:~/shelf$ printf "%-12s %s\n" 1.2.3 $(digest 1.2.3)
1.2.3        sha256:f8c6d16d0587
```

**The registry accepted it.** `1.2.3` now names a build that reports itself as 9.9.9, and every
machine that pulls `shelf:1.2.3` from today gets it. Hosted registries can refuse this: Amazon ECR
and Google Artifact Registry both have a setting that makes tags immutable, and it is worth turning
on for release tags. Even then, **a tag is a promise the registry keeps; a digest is a fact about
the bytes**. That is the subject of the next section.

One more fact from the captures: the 1.0.0 built at the start of this lesson has the id
`acc588659f39`, and the 1.0.0 built from the same source in lesson 15 had `f13bb63f689b`. **Building
the same commit again does not give the same image**, since the image's configuration records, among
other things, when it was built. A release is the image that was pushed, not a recipe for making it
again, which is why the tag is never re-pushed from a rebuild.
