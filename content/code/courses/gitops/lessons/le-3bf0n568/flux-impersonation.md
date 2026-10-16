---
title: Flux, with less than cluster-admin
version: 1
---

**Flux can apply a Kustomization as a ServiceAccount instead of as itself.** The field is
`serviceAccountName`, and with it set the kustomize controller impersonates that account for every
object it creates, changes or prunes: whatever the account may not do, Flux may not do on behalf of
that path of the repository. The controller keeps its own power for the Kustomizations that do not
name one.

First, how much Flux holds today:

```
ana@laptop:~/fleet$ kubectl get clusterrolebinding cluster-reconciler-flux-system -o custom-columns=ROLE:.roleRef.name,SUBJECTS:.subjects[*].name
ROLE            SUBJECTS
cluster-admin   kustomize-controller,helm-controller
ana@laptop:~/fleet$ kubectl auth can-i create clusterrolebindings --all-namespaces --as=system:serviceaccount:flux-system:kustomize-controller
yes
```

The binding `cluster-reconciler-flux-system` gives `cluster-admin` to the kustomize and helm
controllers, and `kubectl auth can-i` says what that means in one word: Flux may create a
ClusterRoleBinding, which is the permission that grants every other permission.

Staging gets an account of its own, in `flux-system` beside the Kustomization that uses it, allowed
to administer the `staging` namespace and nothing else. The ClusterRole `admin` is Kubernetes' own:
most of what sits inside a namespace, nothing outside it. This is
`clusters/lab/staging-applier.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: staging-applier
  namespace: flux-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: staging-applier
  namespace: staging
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin
subjects:
- kind: ServiceAccount
  name: staging-applier
  namespace: flux-system
```

and `clusters/lab/staging.yaml` names it, under `spec`:

```yaml
  serviceAccountName: staging-applier
```

```
ana@laptop:~/fleet$ git switch --quiet -c staging-applier
ana@laptop:~/fleet$ git diff | grep '^[-+] '
+  serviceAccountName: staging-applier
ana@laptop:~/fleet$ git add clusters && git commit --quiet -m "staging: applied as staging-applier"
ana@laptop:~/fleet$ flux get kustomizations staging
NAME   	REVISION          	SUSPENDED	READY	MESSAGE                                                                                                                                                                                                                 
staging	main@sha1:db03e43c	False    	False	Namespace/staging dry-run failed (Forbidden): namespaces "staging" is forbidden: User "system:serviceaccount:flux-system:staging-applier" cannot patch resource "namespaces" in API group "" in the namespace "staging"	
       	                  	         	     	                                                                                                                                                                                                                       	
```

Merged, and staging stopped: `READY False`, with the reason. The account may not `patch` the
Namespace `staging`, because a namespace is not inside itself and `admin` covers what is inside. The
`REVISION` column still names the commit before this one: Flux checks the whole path with a dry run
first, and here it applied none of it.

**Flux stops at the first refusal**, so its message names one problem and not all of them. To see
the whole list before the next pull request, ask the API server the same question Flux asks, as the
same account: build the directory and apply it with a server-side dry run, impersonating
`staging-applier`. Nothing is changed, and every object gets its own answer:

```
ana@laptop:~/fleet$ kubectl kustomize apps/bulletin/staging | kubectl apply --server-side --dry-run=server --as=system:serviceaccount:flux-system:staging-applier -f -
configmap/bulletin-bgc7c2mm85 serverside-applied (server dry run)
service/bulletin serverside-applied (server dry run)
deployment.apps/bulletin serverside-applied (server dry run)
Error from server (Forbidden): namespaces "staging" is forbidden: User "system:serviceaccount:flux-system:staging-applier" cannot patch resource "namespaces" in API group "" in the namespace "staging"
Error from server (Forbidden): sealedsecrets.bitnami.com "bulletin-token" is forbidden: User "system:serviceaccount:flux-system:staging-applier" cannot patch resource "sealedsecrets" in API group "bitnami.com" in the namespace "staging"
```

Three objects pass and two are refused: the Namespace, as Flux said, and the SealedSecret, which
Flux never reached. `admin` covers the kinds Kubernetes ships and the custom kinds whose own
ClusterRoles say they belong in it; Sealed Secrets' do not.

Two things the `admin` role does not include, and the narrowest answer for each is a rule naming
exactly that. This is `clusters/lab/staging-applier-extra.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: staging-applier
rules:
- apiGroups: [""]
  resources: ["namespaces"]
  resourceNames: ["staging"]
  verbs: ["get", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: staging-applier
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: staging-applier
subjects:
- kind: ServiceAccount
  name: staging-applier
  namespace: flux-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: staging-applier-sealed
  namespace: staging
rules:
- apiGroups: ["bitnami.com"]
  resources: ["sealedsecrets"]
  verbs: ["get", "list", "watch", "create", "patch", "update", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: staging-applier-sealed
  namespace: staging
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: staging-applier-sealed
subjects:
- kind: ServiceAccount
  name: staging-applier
  namespace: flux-system
```

```
ana@laptop:~/fleet$ git switch --quiet main && git pull --quiet && git switch --quiet -c staging-applier-extra
ana@laptop:~/fleet$ git add clusters && git commit --quiet -m "staging-applier: its namespace and its sealed secrets"
ana@laptop:~/fleet$ flux get kustomizations staging
NAME   	REVISION          	SUSPENDED	READY	MESSAGE                              
staging	main@sha1:79a931a1	False    	True 	Applied revision: main@sha1:79a931a1	
```

`READY True`, and this time every object was applied as `staging-applier`.

## What it buys

A pull request to staging's directory that reaches past staging: valid YAML that `kubeconform`
passes, and that a tired reviewer might pass too, because the name sounds harmless and it sits in an
application's folder. It is listed in the directory's `kustomization.yaml`, and this is
`apps/bulletin/staging/debug.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: staging-debug
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: default
  namespace: staging
```

It is merged, and Flux tries:

```
ana@laptop:~/fleet$ git switch --quiet main && git pull --quiet && git switch --quiet -c staging-debug
ana@laptop:~/fleet$ git add apps && git commit --quiet -m "staging: a debugging account"
ana@laptop:~/fleet$ flux get kustomizations staging
NAME   	REVISION          	SUSPENDED	READY	MESSAGE                                                                                                                                                                                                                                                                                                     
staging	main@sha1:79a931a1	False    	False	ClusterRoleBinding/staging-debug dry-run failed (Forbidden): clusterrolebindings.rbac.authorization.k8s.io "staging-debug" is forbidden: User "system:serviceaccount:flux-system:staging-applier" cannot patch resource "clusterrolebindings" in API group "rbac.authorization.k8s.io" at the cluster scope	
       	                  	         	     	                                                                                                                                                                                                                                                                                                           	
ana@laptop:~/fleet$ kubectl get clusterrolebinding staging-debug
Error from server (NotFound): clusterrolebindings.rbac.authorization.k8s.io "staging-debug" not found
ana@laptop:~/fleet$ git switch --quiet main && git pull --quiet && git switch --quiet -c revert-staging-debug
ana@laptop:~/fleet$ git revert --no-edit HEAD^2 >/dev/null && git log -1 --format=%s
Revert "staging: a debugging account"
ana@laptop:~/fleet$ flux get kustomizations staging
NAME   	REVISION          	SUSPENDED	READY	MESSAGE                              
staging	main@sha1:dbee7f14	False    	True 	Applied revision: main@sha1:dbee7f14	
```

Flux refused the revision at the dry run, naming the ClusterRoleBinding and the account, and
`kubectl get` confirms nothing was created. **The review missed it; the permission did not.** The
way back is the way back from any bad merge, a revert through a pull request, after which staging is
ready again on a commit that no longer asks for anything outside it.
