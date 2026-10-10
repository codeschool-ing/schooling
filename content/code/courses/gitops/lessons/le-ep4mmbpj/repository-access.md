---
title: A read-only key to the repository
version: 1
---

**Argo CD needs to read `fleet`, and it needs nothing else from Gitea.** It never pushes, never
opens a pull request, never approves. So it gets an account of its own with read access to that one
repository, and a token with a single scope, `read:repository`. If that token leaks, the damage is
that somebody can read the desired state, which is bad, and not that somebody can change it, which
would be the cluster.

@@capture account

`argocd` is a **collaborator with `read` permission**, the lowest Gitea has. Now Argo CD is told
about the repository, at the address that works from inside the cluster:

@@capture repo-add

`Successful` means the repo server cloned it with those credentials. They are not stored anywhere
mysterious: `argocd repo add` wrote a Kubernetes Secret in the `argocd` namespace, with a label that
tells Argo CD what it is,

@@capture repo-secret

and that is all a "repository" is to Argo CD. Writing that Secret as YAML and applying it does the
same thing, which is how a team adds repositories without anybody typing a token into a terminal.
**Keeping that YAML in Git is the one thing you must not do**: its `password` field is the token,
base64 encoded. Lesson 9 shows how to keep it in Git encrypted.
