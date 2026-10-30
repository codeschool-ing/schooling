---
title: Portable seams, and what portability costs
version: 1
---

The answer to API lock-in is usually put as a choice of service: pick the portable one. **The
better answer is a choice of where the provider is allowed to appear.** A seam is the line between
the part of a system that knows what the shop does and the part that knows where it runs. Draw it
once, keep Azure on one side of it, and moving means rewriting the thin side.

The shop already has one, and this course has been leaning on it since lesson 7.

## One image, three ways, one digest

The image is the seam for compute. Lesson 7 built `shop:1.0` from two files, and lessons 8, 11 and
18 described that image to three more Azure services. Here it runs three ways on the laptop, and
the question each time is the same: is it still the same image?

Build it from lesson 7's `app.py` and `Dockerfile`, in `~/azure/shop`, and ask Docker what it
built:

```
ana@laptop:~/azure$ docker build --quiet --tag shop:1.0 shop
sha256:25d8715c3057e69a6df3afaa336cd1ebbf4ae8ab7ff392bfad00fbfeb55d4382
ana@laptop:~/azure$ docker image inspect shop:1.0 --format '{{.Id}}'
sha256:25d8715c3057e69a6df3afaa336cd1ebbf4ae8ab7ff392bfad00fbfeb55d4382
ana@laptop:~/azure$ docker build --quiet --tag shop:again shop
sha256:0f51deba6e7940a87457019be876e963767de91583025a226f0b9fa16ce1a9eb
ana@laptop:~/azure$ docker image rm shop:again
Untagged: shop:again
Deleted: sha256:0f51deba6e7940a87457019be876e963767de91583025a226f0b9fa16ce1a9eb
```

The same `sha256:` twice: that is the image's **digest**. It is a hash of the document that
describes the image, which names every layer by its own hash in turn. A change of one byte anywhere gives a new digest, and lesson 10 met the same kind of name in a registry. It names one build
rather than one set of files. The same two files, built again a moment later as `shop:again`, came
out under a different digest. Yours will differ from both, and what matters is that one build
keeps one digest through the three runs below. The second build was removed because nothing needs
it.

First, plain Docker, as lesson 7 ran it. `docker inspect` says which image the running container
was made from:

```
ana@laptop:~/azure$ docker run -d --name shop -p 8080:8080 shop:1.0 > /dev/null
ana@laptop:~/azure$ curl -s -w '\n' localhost:8080/version
{"version": "1.0", "host": "48c72c33cffa", "up_s": 0.6}
ana@laptop:~/azure$ docker inspect shop --format '{{.Image}}'
sha256:25d8715c3057e69a6df3afaa336cd1ebbf4ae8ab7ff392bfad00fbfeb55d4382
ana@laptop:~/azure$ docker rm -f shop > /dev/null
```

Second, beside a Dapr sidecar, as lesson 9 ran it. The shop starts with the sidecar's port 3500
published as well, the sidecar joins its network, and the request goes to Dapr, which calls the
shop's `/version` on its behalf. No component files this time, because service invocation needs
none:

```
ana@laptop:~/azure$ docker run -d --name shop -p 8080:8080 -p 3500:3500 shop:1.0 > /dev/null
ana@laptop:~/azure$ docker run -d --name shop-dapr --network container:shop daprio/daprd:1.17.16 ./daprd --app-id shop --app-port 8080 > /dev/null
ana@laptop:~/azure$ curl -s -w '\n' localhost:3500/v1.0/invoke/shop/method/version
{"version": "1.0", "host": "6c1d643d6eb9", "up_s": 2.9}
ana@laptop:~/azure$ docker inspect shop --format '{{.Image}}'
sha256:25d8715c3057e69a6df3afaa336cd1ebbf4ae8ab7ff392bfad00fbfeb55d4382
ana@laptop:~/azure$ docker rm -f shop shop-dapr > /dev/null
```

Third, as a pod, as lesson 11 ran it. A cluster of one control plane and one worker is enough.
Save this as `~/azure/cluster.yaml`; the two patches near the top are needed on a machine with
cgroup v1, and on cgroup v2, which is every current distribution and Docker Desktop, they are
harmless:

```yaml
# cluster.yaml: one control plane and one worker, enough for one pod.
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri"]
    restrict_oom_score_adj = true
kubeadmConfigPatches:
- |
  kind: KubeletConfiguration
  failCgroupV1: false
nodes:
- role: control-plane
- role: worker
```

And the pod, as `~/azure/shop-pod.yaml`. `imagePullPolicy: IfNotPresent` makes the node use the
copy that `kind load` gives it rather than ask a registry, as in lesson 11:

```yaml
# shop-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: shop
spec:
  containers:
  - name: shop
    image: shop:1.0
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 8080
    readinessProbe:
      httpGet:
        path: /healthz
        port: 8080
      periodSeconds: 2
```

Create the cluster, give it the image and start the pod. Nothing publishes the pod's port on the
laptop, so `kubectl exec` asks the shop from inside its own container. Then ask where the pod ran
and what it ran, from Kubernetes and from the node itself. A kind node is a container called
`shop-worker`, and `ctr` is the command-line client of the containerd inside it, whose warning
about this machine's cgroup v1 is sent to `/dev/null`:

```
ana@laptop:~/azure$ kind create cluster --name shop --config cluster.yaml --quiet
ana@laptop:~/azure$ kind load docker-image shop:1.0 --name shop
Image: "shop:1.0" with ID "sha256:25d8715c3057e69a6df3afaa336cd1ebbf4ae8ab7ff392bfad00fbfeb55d4382" not yet present on node "shop-worker", loading...
Image: "shop:1.0" with ID "sha256:25d8715c3057e69a6df3afaa336cd1ebbf4ae8ab7ff392bfad00fbfeb55d4382" not yet present on node "shop-control-plane", loading...
ana@laptop:~/azure$ kubectl apply -f shop-pod.yaml
pod/shop created
ana@laptop:~/azure$ kubectl wait --for=condition=Ready pod/shop --timeout=120s
pod/shop condition met
ana@laptop:~/azure$ kubectl exec shop -- python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8080/version').read().decode())"
{"version": "1.0", "host": "shop", "up_s": 0.7}
ana@laptop:~/azure$ kubectl get pod shop -o jsonpath='{.spec.nodeName} {.status.containerStatuses[0].image}{"\n"}'
shop-worker docker.io/library/shop:1.0
ana@laptop:~/azure$ kubectl get pod shop -o jsonpath='{.status.containerStatuses[0].imageID}{"\n"}'
docker.io/library/import-2026-10-30@sha256:d17c4f32994b3474c254b9a18234b8f4301749c9f817f937f48049e982b947ff
ana@laptop:~/azure$ docker exec shop-worker ctr -n k8s.io images ls name==docker.io/library/shop:1.0 2> /dev/null | awk '{print $1, $3}'
REF DIGEST
docker.io/library/shop:1.0 sha256:25d8715c3057e69a6df3afaa336cd1ebbf4ae8ab7ff392bfad00fbfeb55d4382
ana@laptop:~/azure$ kind delete cluster --name shop
Deleting cluster "shop" ...
Deleted nodes: ["shop-worker" "shop-control-plane"]
```

Three runtimes, and version `1.0` from `/version` each time. The host name and the seconds up
changed, because they belong to the container or the pod. **And the same digest each time.** `docker inspect` gave it for
the two Docker runs. For the pod, `kind load` printed it as it copied the image to both nodes, and
the worker's containerd, asked for `shop:1.0`, holds the image under that digest. Kubernetes' own
`imageID` field shows something else here: a reference starting `import-` with the day's date,
which is a name made up during the import for the archive `kind load` sent, not for the image in
it. When the two seem to disagree, ask the runtime what it holds, as the last command did.

One caution for your own run. This machine's Docker keeps its images in containerd:

```
ana@laptop:~/azure$ docker info --format '{{.DriverStatus}}'
[[driver-type io.containerd.snapshotter.v1]]
```

A Docker with the older image store prints the hash of the image's configuration as its id
instead, and the node's list will not match it character for character. The image is still one
image; the two are hashes of two different documents about it.

None of the three runs needed a change to `app.py` or the `Dockerfile`, and neither did the four
Azure services that lessons 7, 8, 11 and 18 described. **What changed each time was the file
around the image**: a `docker run` line, a sidecar beside it, a pod manifest, and in Azure a
container group, a Container App, a Deployment and a web app. Those files are the part of compute
lock-in that remains, and each is a few dozen lines. The last command deleted the cluster, and each
Docker run ended with `docker rm -f`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"The image shop:1.0, with one digest, in the middle. On the left, three ways it ran on the laptop in this section: plain Docker, beside a Dapr sidecar, and as a pod in kind. On the right, four Azure services that run it, not run here: Container Instances from shop-aci.yaml in lesson 7, Container Apps as Microsoft.App/containerApps in lesson 8, AKS from shop.yaml in lesson 11, and App Service as Microsoft.Web/sites in lesson 18. A note says the image moves unchanged and the file around it is what stays behind.\"><defs><marker id=\"l22-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"120\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">on the laptop, run here</text><text x=\"600\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">in Azure, not run here</text><rect x=\"285\" y=\"115\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop:1.0</text><text x=\"360\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one digest</text><rect x=\"20\" y=\"40\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">plain Docker</text><text x=\"120\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">docker run</text><path d=\"M283 145 L222 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-ah)\"></path><rect x=\"20\" y=\"115\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">beside a Dapr sidecar</text><text x=\"120\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">daprd</text><path d=\"M283 145 L222 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-ah)\"></path><rect x=\"20\" y=\"190\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a pod in kind</text><text x=\"120\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop-pod.yaml</text><path d=\"M283 145 L222 215\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-ah)\"></path><rect x=\"500\" y=\"25\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Container Instances, lesson 7</text><text x=\"600\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop-aci.yaml</text><path d=\"M437 145 L498 50\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-ah)\"></path><rect x=\"500\" y=\"90\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Container Apps, lesson 8</text><text x=\"600\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Microsoft.App/containerApps</text><path d=\"M437 145 L498 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-ah)\"></path><rect x=\"500\" y=\"155\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">AKS, lesson 11</text><text x=\"600\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop.yaml</text><path d=\"M437 145 L498 180\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-ah)\"></path><rect x=\"500\" y=\"220\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">App Service, lesson 18</text><text x=\"600\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Microsoft.Web/sites</text><path d=\"M437 145 L498 245\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-ah)\"></path><text x=\"360\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the image moves unchanged; the file around it is what each platform reads, and what stays behind</text></svg>", "caption": "One image, seven ways to run it. Moving between them rewrites the file around the image, a few dozen lines, and never touches the image."}
```

## Seams worth having

The same idea applies wherever Azure would otherwise reach into the code or the files around it.
Each of these is a standard that Azure speaks, and each leaves something behind:

- **Kubernetes' API** is the seam for orchestration. The Deployment and the disruption budget of
  lesson 11 apply to any conformant cluster. What does not travel is what AKS adds: the node
  pools and upgrade settings in Bicep, the Application Gateway controller of lesson 14, the
  `azure.workload.identity` labels of lesson 13.
- **OpenTelemetry** is the seam for telemetry. Microsoft documents its own OpenTelemetry
  distribution for sending traces, metrics and logs to Application Insights, so code that is
  instrumented with the OpenTelemetry API names Azure only where the exporter is configured.
  `azure-operations` lessons 8 to 13 teach Azure Monitor.
- **CloudEvents** is the seam for events. Event Grid accepts and delivers CloudEvents 1.0, the
  CNCF's open specification, and lesson 20 set both schemas to `CloudEventSchemaV1_0`; a handler
  that reads that envelope reads it from any broker that speaks it.
- **AMQP 1.0** is the seam for messages. It is Service Bus's main protocol and an ISO and IEC
  standard. The protocol travels; sessions, dead-lettering and the `azure-servicebus` library of
  lesson 20 are Service Bus's, so put the client behind a function of your own, such as
  `send_export_request(order_day)`, and the day the queue moves, one function changes.
- **Infrastructure as code** is a seam only in part. Bicep declares Azure resources and nothing
  else; Terraform reaches many providers through its plugins, but a Terraform file for the shop
  names `azurerm` resources, and those do not run anywhere else. The language and the habits
  travel and the resource definitions are rewritten. `azure-operations` lessons 4 to 6 teach both.

## Dapr, the seam you install

Lesson 9 was a deliberate abstraction. The shop's code spoke Dapr's HTTP API and a component file
decided whether Redis or Service Bus answered, so the broker changed without a line of code. That
is a seam bought as a product, and lesson 9 measured its price on the laptop: a sidecar using
more memory than the program it served, an extra hop on every call, and a second log to read.
**And you depend on Dapr's API instead of the broker's**: the `/v1.0/` paths, the CloudEvent
envelope, the key layout in the state store. Dapr is lock-in moved to an open project rather than
lock-in removed, and lesson 9 said when that trade pays.

## What portability costs

**A seam is code, or a process, and both are paid for.** The image costs almost nothing, because
an image is how the shop is built anyway. The price grows with every feature of the platform you
decide not to use directly. A team that wraps Durable Functions in a workflow layer of its own,
so that it could move one day, has written a workflow engine, and maintains it on every day it
does not move.

The opposite mistake is just as real. Refusing every managed service in the name of portability
means running your own broker, your own scheduler and your own database on virtual machines,
which costs more every month than most exits ever would. **Portability is worth paying for where
leaving is likely or expensive, and nowhere else**, and the next section turns that sentence into
numbers.
