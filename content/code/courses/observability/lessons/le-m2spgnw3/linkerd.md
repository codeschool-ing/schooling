---
title: Linkerd, compared by design
version: 1
---

**Linkerd** is the other mesh in this lesson's title, and the oldest: it named the category in 2016.
Its second version replaced the JVM proxy of the first with a small one written in Rust for exactly this
job, `linkerd2-proxy`, rather than Envoy. That is its central bet: a proxy that does less, uses less and
needs almost no configuration.

**The machine this lesson was recorded on could not pull Linkerd's images**, which are published on its
own registry and on GitHub's, both refused by its network. So Linkerd is not running here. What its
command-line tool can do without a cluster is render what it would install:

```
ana@obs:~/shop$ linkerd version --client
Client version: edge-26.9.3
```

```
ana@obs:~/shop$ linkerd install --crds --set installGatewayAPI=true 2>/dev/null | grep '^kind:' | sort | uniq -c
     14 kind: CustomResourceDefinition
```

```
ana@obs:~/shop$ linkerd install --ignore-cluster | grep -E '^kind:|image:' | sort | uniq -c
      1             image: cr.l5d.io/linkerd/controller:edge-26.9.3
      5         image: cr.l5d.io/linkerd/controller:edge-26.9.3
      6         image: cr.l5d.io/linkerd/proxy:edge-26.9.3
      2       image:
      5 kind: ClusterRole
      5 kind: ClusterRoleBinding
      2 kind: ConfigMap
      1 kind: CronJob
      3 kind: Deployment
      1 kind: MutatingWebhookConfiguration
      1 kind: Namespace
      3 kind: Role
      2 kind: RoleBinding
      5 kind: Secret
      8 kind: Service
      4 kind: ServiceAccount
      2 kind: ValidatingWebhookConfiguration
```

The custom resource definitions come first, fourteen of them, the Gateway API's own included. Then the control plane: three Deployments, a webhook that adds the proxy to new pods (the `MutatingWebhookConfiguration`), and two images, `controller` and `proxy`, the `linkerd2-proxy` that would sit beside every meshed pod, the control plane's own included. The two bare `image:` lines are images written as a name and a version on separate lines. The shape is Istio's: a control plane, an injector and one proxy per pod.

The differences that matter when choosing, stated from each project's design rather than from a run:

| | Istio | Linkerd |
|---|---|---|
| proxy | Envoy, general purpose and very configurable | `linkerd2-proxy`, written for the mesh only |
| mutual TLS | on in permissive mode; strict by policy | on by default between meshed pods |
| telemetry | Envoy's statistics, labelled per source and destination | per-route metrics through its `viz` extension |
| traffic control | rich: routing rules, mirroring, fault injection | smaller, built on standard Gateway API resources |
| sidecar-free mode | ambient mode | none; the proxy stays per pod |

**Neither choice changes the observability argument of this lesson.** Both give request counts,
latencies and success rates per pair of services with no code, both secure traffic with workload
identity, and both stop at the same place: they see requests, not what the requests were for.
