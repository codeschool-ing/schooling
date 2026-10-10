---
title: Projects: what an Application may touch
version: 1
---

**Every Application so far belongs to the project `default`, which allows any repository, any
cluster, any namespace and any kind of object.** With the app of apps, anybody whose pull request
to `argocd/` is merged can create an Application, and an Application in `default` can deploy
anything anywhere, including into `kube-system`. A project narrows that. Save this as
`fleet/argocd/project-bulletin.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: bulletin
  namespace: argocd
spec:
  description: The bulletin application, in every environment
  sourceRepos:
  - http://gitea:3000/ana/fleet.git
  destinations:
  - server: https://kubernetes.default.svc
    namespace: staging
  - server: https://kubernetes.default.svc
    namespace: production
  clusterResourceWhitelist:
  - group: ""
    kind: Namespace
```

Three lists, each an allow-list. **`sourceRepos`**: only `fleet` may be read. **`destinations`**:
only the `staging` and `production` namespaces of this cluster. **`clusterResourceWhitelist`**: of
the objects that live outside a namespace, only a Namespace; a ClusterRole, a CRD or a webhook is
refused. Objects inside the allowed namespaces are allowed unless a `namespaceResourceBlacklist`
says otherwise.

In the same pull request, `argocd/bulletin-staging.yaml` changes `project: default` to
`project: bulletin`:

@@capture project

## The rule at work

An Application in that project that tries to deploy into `kube-system` never gets as far as a sync.
This one is applied by hand, as a test, and deleted afterwards:

@@capture denied

The controller refused the Application itself, with a message naming the project and the rule. **A
project is the line between "may merge a file into `argocd/`" and "may change anything in the
cluster"**, and lesson 11 draws it tighter, together with the permissions of Argo CD's own service
account.
