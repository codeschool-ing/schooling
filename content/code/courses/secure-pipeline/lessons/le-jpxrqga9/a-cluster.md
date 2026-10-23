---
title: A cluster that pulls from your registry
version: 1
---

Lessons 8 and 9 hardened an image and the way it runs, and both still depend on somebody typing
the right `docker run`. **A cluster turns those flags into rules that hold for everybody who deploys
there**, which is what this lesson builds. The cluster is kind, Kubernetes in Docker containers, the
one `kubernetes` lesson 5 set up and used from then on; here it has one extra job, pulling linkbox
from the registry on your machine instead of from the internet.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"sp-l10-network\" aria-label=\"Your machine runs the registry container, published on 127.0.0.1:5000, where the pipeline pushes. The kind node is another container, on Docker's kind network. The registry container is joined to that network too. Inside the node, containerd reads hosts.toml, which says that the name localhost:5000 is reached at http://registry:5000, so the node pulls localhost:5000/linkbox:main from the registry container.\"><defs><marker id=\"sp-l10-network-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l10-network-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"270\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">your machine</text><rect x=\"30\" y=\"60\" width=\"190\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ci/push.sh</text><text x=\"125.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">localhost:5000/linkbox</text><rect x=\"270\" y=\"45\" width=\"425\" height=\"220\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"285\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">Docker network: kind</text><rect x=\"290\" y=\"80\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">registry container</text><text x=\"375.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">127.0.0.1:5000</text><rect x=\"500\" y=\"80\" width=\"180\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">kind node</text><text x=\"590.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">linkbox-control-plane</text><rect x=\"500\" y=\"170\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">hosts.toml</text><text x=\"590.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">localhost:5000 → registry:5000</text><path d=\"M220 88 L288 88\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-network-ah-phosphor)\"></path><path d=\"M498 108 L462 108\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-network-ah-amber)\"></path><text x=\"480\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">pulls</text><path d=\"M590 168 L590 138\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-network-ah-amber)\"></path><text x=\"375\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">docker network connect</text></svg>", "caption": "One name, localhost:5000/linkbox, on both sides. On the node, a file says where that name really is."}
```

### What is in the registry

The pipeline pushes on every run, and lesson 9's push left `main` pointing at the latest image:

```
ana@vm:~$ cd ~/linkbox
ana@vm:~/linkbox$ curl -s http://localhost:5000/v2/linkbox/tags/list
{"name":"linkbox","tags":["8bd2e60","main"]}
```

### The cluster's configuration

kind runs each Kubernetes node as a Docker container, and inside it `containerd` pulls the images.
Telling containerd where a registry lives is a file per registry in `/etc/containerd/certs.d`, and
kind's configuration only has to switch that directory on. Save it as `~/kind.yaml`:

```yaml
# The study cluster: one node, which pulls localhost:5000/... from the
# registry container on this machine.
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry]
    config_path = "/etc/containerd/certs.d"
# The next two patches are for the machine this was recorded on, which has
# cgroup v1 and forbids lowering a process's OOM score. Delete them on yours.
- |-
  [plugins."io.containerd.grpc.v1.cri"]
    restrict_oom_score_adj = true
kubeadmConfigPatches:
- |
  kind: KubeletConfiguration
  failCgroupV1: false
```

**The first patch is the one that matters**: it makes containerd read `certs.d`. The other two are
there because of the machine this course was recorded on, which has cgroup v1 and forbids a process
from lowering its out-of-memory score; `kubernetes` lesson 5 met the same two. On a current Linux
with cgroup v2, on Docker Desktop or in a Codespace, delete both, and if the cluster fails to start
with them deleted, `kind create cluster` prints the reason in its last lines.

```
ana@vm:~/linkbox$ kind create cluster --name linkbox --config ~/kind.yaml
cgroup v1 is deprecated in Kubernetes and will not be supported in a future kind release, please upgrade to cgroup v2
Creating cluster "linkbox" ...
 • Ensuring node image (kindest/node:v1.37.0) 🖼️  ...
 ✓ Ensuring node image (kindest/node:v1.37.0) 🖼️
 • Preparing nodes 📦   ...
 ✓ Preparing nodes 📦 
 • Writing configuration 📜  ...
 ✓ Writing configuration 📜
 • Starting control-plane 🕹️  ...
 ✓ Starting control-plane 🕹️
 • Installing CNI 🔌  ...
 ✓ Installing CNI 🔌
 • Installing StorageClass 💾  ...
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-linkbox"
You can now use your cluster with:

kubectl cluster-info --context kind-linkbox

Thanks for using kind! 😊
```

The first line is kind's own warning about cgroup v1, the reason for the third patch, and
everything after it is a cluster starting. The node needs a few seconds more to report itself
ready, which the next commands wait for.

### Teaching the node where `localhost:5000` is

Inside the node, `localhost` is the node itself, not your machine, so `localhost:5000` would point at
nothing. The fix is the one kind's documentation gives for a local registry, in two parts: a
`hosts.toml` that says "for `localhost:5000`, ask `http://registry:5000`", and the registry container
joined to the network the node is on, so that the name `registry` resolves:

```
ana@vm:~/linkbox$ docker exec linkbox-control-plane mkdir -p /etc/containerd/certs.d/localhost:5000
ana@vm:~/linkbox$ printf '[host."http://registry:5000"]\n' | docker exec -i linkbox-control-plane cp /dev/stdin /etc/containerd/certs.d/localhost:5000/hosts.toml
ana@vm:~/linkbox$ docker network connect kind registry
ana@vm:~/linkbox$ kubectl wait --for=condition=Ready node --all --timeout=180s
node/linkbox-control-plane condition met
ana@vm:~/linkbox$ kubectl get nodes
NAME                    STATUS   ROLES           AGE   VERSION
linkbox-control-plane   Ready    control-plane   21s   v1.37.0
```

**The image keeps the name it was pushed under**, `localhost:5000/linkbox:main`, on your machine
and in the cluster alike, and only the node knows that, for it, the name means a container called
`registry`. That matters for the admission rule of this lesson, which checks image names: the name is the
same everywhere it appears. `http://` is acceptable for the same reason as in lesson 8; the traffic
never leaves this machine.

A cluster that pulls from a registry elsewhere needs the same two facts, an address and a way to
trust it, and a real one adds credentials: a pull secret, or a node identity the registry accepts.
That part is not run here, because this registry asks for none.

### When the cluster is not needed

The cluster is the heaviest thing the course runs after ZAP.
`kind delete cluster --name linkbox` removes it, the registry and its images stay, and the commands
of this section build it again in a minute.
