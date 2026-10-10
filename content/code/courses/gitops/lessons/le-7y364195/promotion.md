---
title: Promotion is a pull request
version: 1
---

**A release reaches production by being promoted, and in this layout promotion is a pull request
that makes production's directory say what staging's already says** about the thing being
promoted, and nothing else.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"Promotion. The application repository is tagged v1.1 and CI pushes the image bulletin:1.1. A pull request changes the staging directory to 1.1, and staging runs it. A second pull request changes only the image line in the production directory, and production runs it.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"270\" fill=\"var(--ink)\"/><rect x=\"20\" y=\"40\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"95.0\" y=\"60.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">bulletin repo</text><text x=\"95.0\" y=\"78.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">tag v1.1</text><rect x=\"20\" y=\"170\" width=\"150\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"95.0\" y=\"190.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">registry</text><text x=\"95.0\" y=\"208.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">bulletin:1.1</text><line x1=\"95\" y1=\"90\" x2=\"95.0\" y2=\"158.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"95,166 99.5,158.0 90.5,158.0\" fill=\"var(--paper-dim)\"/><text x=\"105\" y=\"134\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">CI builds</text><rect x=\"260\" y=\"40\" width=\"190\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"355.0\" y=\"60.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">pull request 1</text><text x=\"355.0\" y=\"78.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">staging: 1.1</text><rect x=\"260\" y=\"170\" width=\"190\" height=\"50\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"355.0\" y=\"190.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">pull request 2</text><text x=\"355.0\" y=\"208.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">production: 1.1</text><rect x=\"540\" y=\"40\" width=\"160\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"620.0\" y=\"60.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">staging</text><text x=\"620.0\" y=\"78.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">runs 1.1</text><rect x=\"540\" y=\"170\" width=\"160\" height=\"50\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"620.0\" y=\"190.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">production</text><text x=\"620.0\" y=\"208.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--paper-dim)\">runs 1.1</text><line x1=\"170\" y1=\"195\" x2=\"251.3\" y2=\"81.5\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"/><polygon points=\"256,75 247.7,78.9 255.0,84.1\" fill=\"var(--paper-dim)\"/><line x1=\"450\" y1=\"65\" x2=\"528.0\" y2=\"65.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"/><polygon points=\"536,65 528.0,60.5 528.0,69.5\" fill=\"var(--phosphor)\"/><line x1=\"450\" y1=\"195\" x2=\"528.0\" y2=\"195.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"/><polygon points=\"536,195 528.0,190.5 528.0,199.5\" fill=\"var(--phosphor)\"/><line x1=\"355\" y1=\"90\" x2=\"355.0\" y2=\"158.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"/><polygon points=\"355,166 359.5,158.0 350.5,158.0\" fill=\"var(--paper-dim)\"/><text x=\"365\" y=\"134\" text-anchor=\"start\" font-family=\"IBM Plex Sans\" font-size=\"12\" fill=\"var(--amber)\">checked in staging</text></svg>", "caption": "The image is built once and promoted by reference: two pull requests to fleet, each changing one environment's directory."}
```

## A new release, from the application's side

Version 1.1 adds one line to the page, the name of the pod that answered, which makes the rollouts
of the next lessons visible. This is `~/bulletin/index.cgi` for 1.1:

```sh
#!/bin/sh
# Answers every request with what this copy of bulletin was given.
echo "Content-Type: text/plain"
echo
echo "bulletin $VERSION"
echo "message: ${MESSAGE:-none}"
echo "pod: $(hostname)"
if [ -r /secrets/token ]; then
  echo "token: sha256:$(sha256sum /secrets/token | cut -c1-12)"
else
  echo "token: none"
fi
```

The application's CI would do the rest on a tag. Here you are its CI: commit, tag, build from the
tagged commit, push the image.

```
ana@laptop:~/bulletin$ git diff | grep '^+[^+]'
+echo "pod: $(hostname)"
ana@laptop:~/bulletin$ git commit --quiet -am "Show the pod that answered"
ana@laptop:~/bulletin$ git tag v1.1
ana@laptop:~/bulletin$ git push --quiet origin main v1.1
ana@laptop:~/bulletin$ docker build --quiet --build-arg VERSION=1.1 -t localhost:5001/bulletin:1.1 .
sha256:c779be3c44cc237f479a70963539914e714a33f64bbbefa9dcbbcb145d415d57
ana@laptop:~/bulletin$ docker push --quiet localhost:5001/bulletin:1.1
localhost:5001/bulletin:1.1
ana@laptop:~/bulletin$ curl -s localhost:5001/v2/bulletin/tags/list
{"name":"bulletin","tags":["1.0","1.1"]}
```

## Staging first

The image exists, and nothing runs it: a registry is not a deployment. The first pull request moves
staging to 1.1, and the webhook from lesson 4 delivers it:

```
ana@laptop:~/fleet$ git switch --quiet -c staging-1.1
ana@laptop:~/fleet$ git commit --quiet -am "staging: bulletin 1.1"
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.1
message: Staging is updated by a webhook.
pod: bulletin-5c6966849-qs8ph
token: none
ana@laptop:~/fleet$ curl -s localhost:8081
bulletin 1.0
message: Welcome to the bulletin.
token: none
```

Staging answers as 1.1, with the pod's name. Production still answers as 1.0, because nothing told
it otherwise.

## Then production

Before the promotion, the two directories differ in everything that makes them two environments,
and in one more line:

```
ana@laptop:~/fleet$ diff apps/bulletin/staging/bulletin.yaml apps/bulletin/production/bulletin.yaml
4c4
<   name: staging
---
>   name: production
10c10
<   namespace: staging
---
>   namespace: production
12c12
<   replicas: 3
---
>   replicas: 2
23c23
<         image: localhost:5001/bulletin:1.1
---
>         image: localhost:5001/bulletin:1.0
26c26
<           value: Staging is updated by a webhook.
---
>           value: Welcome to the bulletin.
38c38
<   namespace: staging
---
>   namespace: production
46c46
<     nodePort: 30080
---
>     nodePort: 30081
```

The namespace, the replica count, the message and the port are meant to differ. **The image is the
one difference that is a release in transit**, and the promotion changes exactly that line:

```
ana@laptop:~/fleet$ git switch --quiet -c production-1.1
ana@laptop:~/fleet$ git diff | grep '^[-+] '
-        image: localhost:5001/bulletin:1.0
+        image: localhost:5001/bulletin:1.1
ana@laptop:~/fleet$ git commit --quiet -am "production: bulletin 1.1"
ana@laptop:~/fleet$ curl -s localhost:8081
bulletin 1.1
message: Welcome to the bulletin.
pod: bulletin-86887c69f-vd55h
token: none
```

The pull request's diff is one line, and that is the property worth protecting: a reviewer of a
promotion reads the release being promoted, not a merge of two branches' histories. Lesson 6 makes
that even sharper, by removing every line the two files share.
