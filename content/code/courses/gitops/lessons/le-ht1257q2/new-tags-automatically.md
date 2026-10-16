---
title: New tags, proposed automatically
version: 1
---

**Every release so far reached `fleet` because a person edited a tag.** For staging, where every
release should land as soon as it is built, that is a chore, and Flux can do it: its image
controllers watch a registry for new tags, pick the newest by a policy, and commit the new tag back
into Git. Which raises the question lesson 2 settled: **commit where?** Not to `main`, which nobody
pushes to. To a branch, from which a pull request goes through the usual checks and review.

## The controllers

The image controllers are optional parts of Flux, so they are a change to Flux's own components:

```sh
flux install --export --components-extra=image-reflector-controller,image-automation-controller \
  > clusters/lab/flux-system/gotk-components.yaml
```

That pull request makes Flux install two more controllers into itself, as lesson 4 promised
upgrading Flux would work.

## Something that may push

The automation needs to push a branch, which Flux's read-only token cannot do. It gets its own
account, `image-bot`, with `write` permission, a token in a Secret, and further down a
`GitRepository` of its own that uses it, so that only the automation holds a credential that can
write:

```
ana@laptop:~/fleet$ docker exec gitea gitea admin user create --username image-bot --password 'change-me-please' --email image-bot@example.org --must-change-password=false
2026/10/10 07:12:30 modules/setting/setting.go:133:loadCommonSettingsFrom() [W] [security] ALLOWED_HOST_LIST only restricts private hosts in the default lax mode, set EGRESS_MODE = strict to allow only the listed hosts, or lax to keep this
New user 'image-bot' has been successfully created!
ana@laptop:~/fleet$ docker exec gitea gitea admin user generate-access-token --username image-bot --token-name automation --scopes write:repository --raw > ~/image-bot.token
2026/10/10 07:12:30 modules/setting/setting.go:133:loadCommonSettingsFrom() [W] [security] ALLOWED_HOST_LIST only restricts private hosts in the default lax mode, set EGRESS_MODE = strict to allow only the listed hosts, or lax to keep this
ana@laptop:~/fleet$ chmod 600 ~/image-bot.token
ana@laptop:~/fleet$ curl -s -o /dev/null -w "%{http_code}\n" -X PUT -H "$AS_ANA" -H "$JSON" -d '{"permission": "write"}' $API/collaborators/image-bot
204
ana@laptop:~/fleet$ flux create secret git fleet-writer-auth --url=http://gitea:3000/ana/fleet.git --username=image-bot --password="$(cat ~/image-bot.token)"
► git secret 'fleet-writer-auth' created in 'flux-system' namespace
```

The `[W]` line before each answer from Gitea is a warning about the `ALLOWED_HOST_LIST` that lesson 4
set for webhooks: in Gitea's default mode the list governs private addresses only, which is all this
laptop needs. `204` is Gitea's answer to the permission: done, nothing to say.

## What to watch, which tag to pick, where to write

Four objects, the first being the `GitRepository` the automation writes through. Save them as
`clusters/lab/image-automation.yaml`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: fleet-writer
  namespace: flux-system
spec:
  interval: 1m
  url: http://gitea:3000/ana/fleet.git
  ref:
    branch: main
  secretRef:
    name: fleet-writer-auth
---
apiVersion: image.toolkit.fluxcd.io/v1
kind: ImageRepository
metadata:
  name: bulletin
  namespace: flux-system
spec:
  image: registry:5000/bulletin
  insecure: true
  interval: 1m
---
apiVersion: image.toolkit.fluxcd.io/v1
kind: ImagePolicy
metadata:
  name: bulletin
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: bulletin
  filterTags:
    pattern: '^1\.(?P<minor>[0-9]+)$'
    extract: '$minor'
  policy:
    numerical:
      order: asc
---
apiVersion: image.toolkit.fluxcd.io/v1
kind: ImageUpdateAutomation
metadata:
  name: staging
  namespace: flux-system
spec:
  interval: 1m
  sourceRef:
    kind: GitRepository
    name: fleet-writer
  git:
    checkout:
      ref:
        branch: main
    push:
      branch: image-updates
    commit:
      author:
        name: image-bot
        email: image-bot@example.org
      messageTemplate: "staging: bulletin {{range .Changed.Changes}}{{.NewValue}}{{end}}"
  update:
    path: ./apps/bulletin/staging
    strategy: Setters
```

The `ImageRepository` lists the tags of `bulletin`; the `ImagePolicy` keeps the tags shaped `1.N`,
takes the `N` out of each, and picks the highest; the `ImageUpdateAutomation` checks out `main`, rewrites what the policy picked into
`apps/bulletin/staging`, and pushes the commit to the branch `image-updates`. **What it rewrites is
marked in the file**: one comment, after the tag in staging's overlay, naming the policy:

```yaml
  newTag: "1.1" # {"$imagepolicy": "flux-system:bulletin:tag"}
```

**Why not a version range?** Flux's `semver` policy reads versions of three numbers, and this
course has tagged `bulletin` with two since lesson 1: `1.2`, not `1.2.0`. A range such as
`>=1.0.0 <2.0.0` matches none of them, and the policy says `unable to determine latest version from
provided list` and picks nothing. The filter also drops `stable`, the tag moved by hand earlier in
this lesson,
which is no version at all. A team that tags with three numbers from the start can use the range.

`:tag` means only the tag is rewritten; the image's name stays `localhost:5001/bulletin`, the name the
node pulls by, while the controller watches the same registry under its in-cluster name.

The components, the four objects and the marker go into one pull request, and after the merge Flux
runs six controllers instead of four:

```
ana@laptop:~/fleet$ git switch --quiet -c image-automation
ana@laptop:~/fleet$ flux install --export --components-extra=image-reflector-controller,image-automation-controller > clusters/lab/flux-system/gotk-components.yaml
ana@laptop:~/fleet$ git add clusters apps
ana@laptop:~/fleet$ git diff --cached --stat
 apps/bulletin/staging/kustomization.yaml      |    2 +-
 clusters/lab/flux-system/gotk-components.yaml | 1300 ++++++++++++++++++++++++-
 clusters/lab/image-automation.yaml            |   62 ++
 3 files changed, 1362 insertions(+), 2 deletions(-)
ana@laptop:~/fleet$ git commit --quiet -m "flux: propose new staging releases from the registry"
ana@laptop:~/fleet$ kubectl -n flux-system get deployments
NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
helm-controller               1/1     1            1           4m4s
image-automation-controller   1/1     1            1           4s
image-reflector-controller    1/1     1            1           4s
kustomize-controller          1/1     1            1           4m4s
notification-controller       1/1     1            1           4m4s
source-controller             1/1     1            1           4m5s
```

## A release that proposes itself

```
ana@laptop:~/bulletin$ git tag v1.2
ana@laptop:~/bulletin$ git push --quiet origin v1.2
ana@laptop:~/bulletin$ docker build --quiet --build-arg VERSION=1.2 -t localhost:5001/bulletin:1.2 .
sha256:484d38fbf937d15e5e1cad296ded20756581c2b36129206c9c659f73228a8cbb
ana@laptop:~/bulletin$ docker push --quiet localhost:5001/bulletin:1.2
localhost:5001/bulletin:1.2
ana@laptop:~/fleet$ flux get image policy bulletin
NAME    	IMAGE                 	TAG	READY	MESSAGE                                                                                             
bulletin	registry:5000/bulletin	1.2	True 	Latest image tag for registry:5000/bulletin resolved to 1.2 (previously registry:5000/bulletin:1.1)	
ana@laptop:~/fleet$ git fetch --quiet && git log --oneline -1 origin/image-updates
3c3a61e staging: bulletin 1.2
ana@laptop:~/fleet$ git diff main origin/image-updates | grep '^[-+] '
-  newTag: "1.1" # {"$imagepolicy": "flux-system:bulletin:tag"}
+  newTag: "1.2" # {"$imagepolicy": "flux-system:bulletin:tag"}
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.2
message: Staging is built by Kustomize.
pod: bulletin-cfd6f4744-hf4cv
token: none
```

Version 1.2 was pushed to the registry, and nothing else was done by hand. Within a minute the policy
picked it, the automation committed `staging: bulletin 1.2` to `image-updates`, and pushed. **The
branch is the proposal**: it goes through the check and Bruno's review as a pull request, and only
the merge changes staging. Production has no marker, so nothing ever proposes a release to it.
