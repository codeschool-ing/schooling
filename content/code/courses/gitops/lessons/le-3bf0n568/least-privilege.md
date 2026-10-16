---
title: What each identity may do
version: 1
---

**Rotation shortens how long a stolen credential works. Least privilege shrinks what it works for.**
The two are independent, and the second is usually the cheaper: an identity that may read one path
of Vault, or write one namespace of the cluster, is a small loss when it leaks, whatever its
lifetime.

Every identity in this course can be asked the same question, *what is the most it could do?*, and
the answers are uneven:

| identity | may | the most it could do |
|---|---|---|
| `bulletin` in production, through Vault's role | read `secret/data/bulletin/production` | read one token |
| Flux's Gitea account | read `fleet` | read the desired state |
| `image-bot` | write `fleet`, never merge to `main` | open a misleading pull request |
| Flux's controllers | everything in the cluster, as `cluster-admin` | anything a merged commit asks |
| the Vault root token | everything in Vault | anything |

The first three were made narrow on purpose in earlier lessons. **The fourth is Flux's default**:
its kustomize and helm controllers run with a ClusterRoleBinding to `cluster-admin`, so a commit to
any path Flux applies can create anything anywhere, a ClusterRole, a webhook, a pod in
`kube-system`. Review is the only thing standing between a pull request and the whole cluster.

That is reasonable for the platform's own Kustomization, `flux-system`, which installs controllers
and CRDs and needs the power. It is not reasonable for an application's environments, which should
be able to change their own namespace and nothing else, and the next section narrows them. The fifth
is lesson 12's last step: the root token is for setting Vault up, and a Vault in use does not keep
one lying around.
