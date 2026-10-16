---
title: The flux command
version: 1
---

**Flux's command does two jobs: it writes Flux's manifests for you, and it reads Flux's objects
back in a form a person can follow.** It is one file in a tarball, from the same release as the
controllers it installs, checked like every download in this course:

```
ana@laptop:~$ ARCH=$(dpkg --print-architecture)
ana@laptop:~$ curl -fsSLO https://github.com/fluxcd/flux2/releases/download/v2.9.6/flux_2.9.6_linux_$ARCH.tar.gz
ana@laptop:~$ curl -fsSL https://github.com/fluxcd/flux2/releases/download/v2.9.6/flux_2.9.6_checksums.txt | grep " flux_2.9.6_linux_$ARCH.tar.gz$" | sha256sum --check
flux_2.9.6_linux_amd64.tar.gz: OK
ana@laptop:~$ tar -xzf flux_2.9.6_linux_$ARCH.tar.gz flux && sudo install -m 0755 flux /usr/local/bin/ && rm flux flux_2.9.6_linux_$ARCH.tar.gz
ana@laptop:~$ flux --version
flux version 2.9.6
```

`flux check --pre` asks the cluster whether Flux can run there at all, before anything is
installed:

```
ana@laptop:~$ flux check --pre
► checking prerequisites
✔ Kubernetes 1.37.0 >=1.33.0-0
✔ prerequisites checks passed
```

A version of Kubernetes new enough, and a `kubectl` that can talk to it. The second thing Flux
needs is what Argo CD needed: a read-only way into `fleet`. Same arrangement, a Gitea account of its
own with `read` permission and a token with one scope:

```
ana@laptop:~$ docker exec gitea gitea admin user create --username flux --password 'change-me-please' --email flux@example.org --must-change-password=false
New user 'flux' has been successfully created!
ana@laptop:~$ docker exec gitea gitea admin user generate-access-token --username flux --token-name cluster --scopes read:repository --raw > ~/flux.token
ana@laptop:~$ chmod 600 ~/flux.token
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" -X PUT -H "$AS_ANA" -H "$JSON" -d '{"permission": "read"}' $API/collaborators/flux
204
```
