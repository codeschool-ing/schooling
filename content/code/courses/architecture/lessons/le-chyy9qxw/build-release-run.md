---
title: V, build, release, run
version: 1
---

Three stages, kept apart on purpose.

| stage | what it does | what comes out |
| --- | --- | --- |
| **build** | turns one commit into something that can run: dependencies installed, code compiled or copied | an image |
| **release** | combines one build with one environment's config | a release, numbered, that never changes |
| **run** | starts processes from a release | the running program |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Three stages from left to right. Build turns one commit of the code into an image tagged 1.0.0. Release combines that image with the configuration of one environment into release 41, then the same image with new configuration into release 42. Run starts processes from a release. An arrow from release 42 back to release 41 is labelled rollback.\"><defs><marker id=\"l4-brr-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l4-brr-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l4-brr-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">build</text><text x=\"330\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">release</text><text x=\"610\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">run</text><rect x=\"30\" y=\"60\" width=\"80\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">commit</text><rect x=\"140\" y=\"60\" width=\"90\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">image 1.0.0</text><path d=\"M112 80 L138 80\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-brr-ah-wire)\"></path><rect x=\"270\" y=\"60\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">release 41</text><text x=\"370\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">image 1.0.0 + config A</text><path d=\"M232 80 L268 85\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-brr-ah-amber)\"></path><rect x=\"270\" y=\"150\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"370\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">release 42</text><text x=\"370\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">image 1.0.0 + config B</text><path d=\"M232 80 L268 175\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-brr-ah-amber)\"></path><rect x=\"540\" y=\"150\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">processes</text><path d=\"M472 175 L538 175\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-brr-ah-phosphor)\"></path><path d=\"M330 148 C 300 130, 300 125, 330 112\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l4-brr-ah-amber)\"></path><text x=\"345\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">rollback</text></svg>", "caption": "Build once, release many times, run what was released. A rollback is choosing an earlier release, not building anything again."}
```

The reason for the separation is what it forbids. **No change is made to running code**: a fix is a
new commit, a new build and a new release, never an edit made on a server, which would exist nowhere
else and be lost at the next deploy. And **a rollback never builds**: it starts the processes of an
earlier release, which still exists exactly as it was.

## In the lab

The image Compose built is `quitanda/catalogue:dev`. **Building again to make a version would break
the factor**: a second build is a second artefact, and nothing guarantees it matches the one that was
tested. Give the build you have a second name instead, and list the catalogue's images:

```
ana@vm:~/lab/twelve$ docker tag quitanda/catalogue:dev quitanda/catalogue:1.0.0
ana@vm:~/lab/twelve$ docker image ls quitanda/catalogue
IMAGE                      ID             DISK USAGE   CONTENT SIZE   EXTRA
quitanda/catalogue:1.0.0   54ee8d968ec5        220MB         53.1MB   U    
quitanda/catalogue:dev     54ee8d968ec5        220MB         53.1MB   U    
```

**Both tags point at the same image id**: a tag is a name for a build, and two names can share one. A
release in a real platform pins the build by its digest, `sha256:…`, rather than by a tag, because a
tag can be moved to another image later and a digest cannot.

`compose.yaml` names the image `quitanda/catalogue:${TAG:-dev}`, so running a particular release is
starting it with its tag:

```
ana@vm:~/lab/twelve$ TAG=1.0.0 docker compose up -d catalogue
 Container twelve-db-1 Running 
 Container twelve-catalogue-1 Recreate 
 Container twelve-catalogue-1 Recreated 
 Container twelve-db-1 Waiting 
 Container twelve-db-1 Healthy 
 Container twelve-catalogue-1 Starting 
 Container twelve-catalogue-1 Started 
ana@vm:~/lab/twelve$ docker compose ps catalogue --format "{{.Name}} {{.Image}} {{.Status}}"
twelve-catalogue-1 quitanda/catalogue:1.0.0 Up Less than a second
```

Compose recreated the container because the image name changed, from `:dev` to `:1.0.0`. A rollback
on a platform is the same operation with an earlier number. The platforms keep the list of releases
for you: Heroku numbers them, Kubernetes keeps a Deployment's revision history and
`kubectl rollout undo` returns to the previous one, and a pipeline that deploys by digest can redeploy any earlier
digest.
