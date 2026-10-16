---
title: Installing Argo CD
version: 1
---

**Argo CD is installed the way it installs everything else: by applying manifests.** The project
publishes one file per release with every object it needs, and a Kustomize file of three lines points
at it. Save this as `~/setup/argocd/kustomization.yaml`:

```yaml
namespace: argocd
resources:
- https://raw.githubusercontent.com/argoproj/argo-cd/v3.5.4/manifests/install.yaml
# The machine these transcripts were recorded on cannot reach quay.io or
# ghcr.io; it runs images built from Argo CD's released binary and from Dex's
# tagged source, from its own registry. Delete these five lines on yours.
images:
- name: quay.io/argoproj/argocd
  newName: localhost:5001/lab/argocd
- name: ghcr.io/dexidp/dex
  newName: localhost:5001/lab/dex
```

The release is pinned, `v3.5.4`, and that is the habit this course asks for everywhere: **a URL that
names a version always means the same bytes**, and upgrading Argo CD becomes a one-line change to
this file, reviewed like any other. Kustomize, which `kubectl` carries built in, fetches the file and
sets the namespace on every object in it. Lesson 6 is about Kustomize itself.

```
ana@laptop:~/setup$ kubectl create namespace argocd
namespace/argocd created
ana@laptop:~/setup$ kubectl apply --server-side -k argocd/ | tail -n 3
networkpolicy.networking.k8s.io/argocd-redis-network-policy serverside-applied
networkpolicy.networking.k8s.io/argocd-repo-server-network-policy serverside-applied
networkpolicy.networking.k8s.io/argocd-server-network-policy serverside-applied
ana@laptop:~/setup$ kubectl -n argocd wait --for=condition=Available deployment --all --timeout=300s
deployment.apps/argocd-applicationset-controller condition met
deployment.apps/argocd-dex-server condition met
deployment.apps/argocd-notifications-controller condition met
deployment.apps/argocd-redis condition met
deployment.apps/argocd-repo-server condition met
deployment.apps/argocd-server condition met
ana@laptop:~/setup$ kubectl -n argocd get statefulsets
NAME                            READY   AGE
argocd-application-controller   1/1     46s
```

`--server-side` is needed and not a style choice: Argo CD's own resource definitions are larger
than the annotation a client-side apply stores, and are refused without it. **Six deployments and
a statefulset**, each one of the parts in the last section, and the `wait` held the terminal until all
the deployments were available. The cluster now uses more memory than before:

```
ana@laptop:~/setup$ docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}" gitops-control-plane registry gitea
NAME                   MEM USAGE / LIMIT
gitops-control-plane   1.306GiB / 15.72GiB
registry               66.81MiB / 15.72GiB
gitea                  104.2MiB / 15.72GiB
```

## The command

The `argocd` command is one more single file, from the same release, checked the same way:

```
ana@laptop:~$ ARCH=$(dpkg --print-architecture)
ana@laptop:~$ curl -fsSLo argocd https://github.com/argoproj/argo-cd/releases/download/v3.5.4/argocd-linux-$ARCH
ana@laptop:~$ curl -fsSL https://github.com/argoproj/argo-cd/releases/download/v3.5.4/cli_checksums.txt | grep " argocd-linux-$ARCH$" | sed "s/argocd-linux-$ARCH/argocd/" | sha256sum --check
argocd: OK
ana@laptop:~$ sudo install -m 0755 argocd /usr/local/bin/ && rm argocd
ana@laptop:~$ argocd version --client --short
argocd: v3.5.4+d6d5b24
```

`argocd` normally talks to Argo CD's API server, which needs a login, a port-forward or an ingress,
and a password. **The `--core` mode skips all of that** and talks to the Kubernetes API directly,
with your kubeconfig, reading and writing Argo CD's objects in the namespace your context points at.
For a lab where you already hold the cluster's admin credentials it is the shortest path, and every
command in this course uses it:

```
ana@laptop:~$ kubectl config set-context --current --namespace=argocd
Context "kind-gitops" modified.
ana@laptop:~$ argocd login --core
Context 'kubernetes' updated
```

## The web interface

Argo CD's web interface draws every Application as a tree of the objects it owns, which is worth
seeing once. It is not needed for anything in this course, and these commands were not run for it:

```sh
argocd admin initial-password -n argocd
kubectl -n argocd port-forward svc/argocd-server 8443:443
```

The first prints the generated password of the `admin` user; the second makes the API server
answer on `https://localhost:8443`, with a self-signed certificate your browser warns about, until
you press `Ctrl+C`.
