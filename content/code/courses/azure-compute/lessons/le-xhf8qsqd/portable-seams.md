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

CAP:build

That long `sha256:` is the image's **digest**: a hash of the image's own description, which names
every layer by its hash in turn. Lesson 10 met it in a registry. Change one byte of `app.py` and
the digest changes; leave everything alone and it does not. Yours differs from this one, because
your base image is not byte for byte this machine's, and it stays the same through the three runs
below.

First, plain Docker, as lesson 7 ran it. `docker inspect` says which image the running container
was made from:

CAP:docker

Second, beside a Dapr sidecar, as lesson 9 ran it. The shop starts with the sidecar's port 3500
published as well, the sidecar joins its network, and the request goes to Dapr, which calls the
shop's `/version` on its behalf. No component files this time, because service invocation needs
none:

CAP:dapr

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

CAP:kind

CAP:digest-sentence

```schooling-figure
FIGURE-SEAMS
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
