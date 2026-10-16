---
title: A read-only key to the repository
version: 1
---

**Argo CD needs to read `fleet`, and it needs nothing else from Gitea.** It never pushes, never
opens a pull request, never approves. So it gets an account of its own with read access to that one
repository, and a token with a single scope, `read:repository`. If that token leaks, the damage is
that somebody can read the desired state, which is bad, and not that somebody can change it, which
would be the cluster.

```
ana@laptop:~$ docker exec gitea gitea admin user create --username argocd --password 'change-me-please' --email argocd@example.org --must-change-password=false
New user 'argocd' has been successfully created!
ana@laptop:~$ docker exec gitea gitea admin user generate-access-token --username argocd --token-name cluster --scopes read:repository --raw > ~/argocd.token
ana@laptop:~$ chmod 600 ~/argocd.token
ana@laptop:~$ curl -s -o /dev/null -w "%{http_code}\n" -X PUT -H "$AS_ANA" -H "$JSON" -d '{"permission": "read"}' $API/collaborators/argocd
204
```

`argocd` is a **collaborator with `read` permission**, the lowest Gitea has. Now Argo CD is told
about the repository, at the address that works from inside the cluster:

```
ana@laptop:~$ argocd repo add http://gitea:3000/ana/fleet.git --username argocd --password "$(cat ~/argocd.token)"
Repository 'http://gitea:3000/ana/fleet.git' added
ana@laptop:~$ argocd repo list
TYPE  NAME  REPO                             INSECURE  OCI    LFS    CREDS  STATUS      MESSAGE  PROJECT
git         http://gitea:3000/ana/fleet.git  false     false  false  false  Successful           
```

`Successful` means the repo server cloned it with those credentials. They are not stored anywhere
mysterious: `argocd repo add` wrote a Kubernetes Secret in the `argocd` namespace, with a label that
tells Argo CD what it is,

```
ana@laptop:~$ kubectl -n argocd get secrets -l argocd.argoproj.io/secret-type=repository
NAME              TYPE     DATA   AGE
repo-2788178720   Opaque   4      1s
ana@laptop:~$ kubectl -n argocd get secrets -l argocd.argoproj.io/secret-type=repository -o jsonpath='{.items[0].data.url}' | base64 -d; echo
http://gitea:3000/ana/fleet.git
```

and that is all a "repository" is to Argo CD. Writing that Secret as YAML and applying it does the
same thing, which is how a team adds repositories without anybody typing a token into a terminal.
**Keeping that YAML in Git is the one thing you must not do**: its `password` field is the token,
base64 encoded. Lesson 9 shows how to keep it in Git encrypted.
