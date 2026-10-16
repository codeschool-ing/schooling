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

```
ana@laptop:~/fleet$ git switch --quiet -c project
ana@laptop:~/fleet$ git add argocd
ana@laptop:~/fleet$ git diff --cached --stat
 argocd/bulletin-staging.yaml |  2 +-
 argocd/project-bulletin.yaml | 17 +++++++++++++++++
 2 files changed, 18 insertions(+), 1 deletion(-)
ana@laptop:~/fleet$ git commit --quiet -m "argocd: the bulletin project"
ana@laptop:~/fleet$ argocd proj list
NAME      DESCRIPTION                                     DESTINATIONS    SOURCES                          CLUSTER-RESOURCE-WHITELIST  NAMESPACE-RESOURCE-BLACKLIST  SIGNATURE-KEYS  ORPHANED-RESOURCES  DESTINATION-SERVICE-ACCOUNTS
bulletin  The bulletin application, in every environment  2 destinations  http://gitea:3000/ana/fleet.git  /Namespace                  <none>                        <none>          disabled            <none>
default                                                   *,*             *                                */*                         <none>                        <none>          disabled            <none>
ana@laptop:~/fleet$ argocd app list
NAME                     CLUSTER                         NAMESPACE  PROJECT   STATUS  HEALTH   SYNCPOLICY  CONDITIONS  REPO                             PATH     TARGET
argocd/bulletin-staging  https://kubernetes.default.svc  staging    bulletin  Synced  Healthy  Auto-Prune  <none>      http://gitea:3000/ana/fleet.git  staging  main
argocd/root              https://kubernetes.default.svc  argocd     default   Synced  Healthy  Auto-Prune  <none>      http://gitea:3000/ana/fleet.git  argocd   main
```

## The rule at work

An Application in that project that tries to deploy into `kube-system` never gets as far as a sync.
This one is applied by hand, as a test, and deleted afterwards:

```
ana@laptop:~/setup$ kubectl apply -f probe-system.yaml
application.argoproj.io/probe-system created
ana@laptop:~/setup$ argocd app get probe-system | sed -n '/^CONDITION/,/^$/p'
CONDITION         MESSAGE                                                                                                                                                         LAST TRANSITION
InvalidSpecError  application destination server 'https://kubernetes.default.svc' and namespace 'kube-system' do not match any of the allowed destinations in project 'bulletin'  2026-10-10 02:20:53 -0300 -03

ana@laptop:~/setup$ kubectl delete -f probe-system.yaml
application.argoproj.io "probe-system" deleted from argocd namespace
```

The controller refused the Application itself, with a message naming the project and the rule. **A
project is the line between "may merge a file into `argocd/`" and "may change anything in the
cluster"**, and lesson 11 draws it tighter, together with the permissions of Argo CD's own service
account.
