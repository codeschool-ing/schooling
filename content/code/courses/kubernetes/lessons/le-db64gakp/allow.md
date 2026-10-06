---
title: Opening one path at a time
version: 1
---

With `deny-all` in place, the namespace accepts nothing. **Policies only ever add permissions**: a
second policy cannot take anything away from the first, it can only allow more. So the shop's paths
are opened by adding one small policy per path.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-front
  namespace: shop
spec:
  podSelector:
    matchLabels:
      app: shop
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: front
    ports:
    - port: 8080
```

Read it from the top. `podSelector` picks the pods the policy protects: those labelled `app: shop`.
The `ingress` rule says who may connect to them: pods labelled `app: front`, in the same namespace,
and only on port 8080, the port the shop's container listens on (not the Service's port 80, because
the policy is checked against the packet that reaches the pod).

```
ana@laptop:~/shop$ kubectl apply -f allow-front.yaml
networkpolicy.networking.k8s.io/allow-front created
ana@laptop:~/shop$ kubectl -n shop exec front -- wget -qO- -T 3 shop
shop 1.0 on shop-774b84ff8c-4zxcl
ana@laptop:~/shop$ kubectl -n other exec stranger -- wget -qO- -T 3 shop.shop
wget: download timed out
command terminated with exit code 1
```

`front` gets through and `stranger` still does not. A `podSelector` inside `from` only ever matches
pods in the policy's own namespace, so `stranger`, in `other`, is not one of them whatever its labels.

```
ana@laptop:~/shop$ kubectl get networkpolicies -n shop
NAME          POD-SELECTOR   AGE
allow-front   app=shop       8s
deny-all      <none>         20s
```

Two policies now select the shop's pods, and a connection is allowed if **any** of them allows it.
That is why the order in which they were applied does not matter, and why there is no "deny" rule to
write: anything that no policy allows, on a pod that some policy selects, is refused.

## A whole namespace as the source

Suppose `other` is the monitoring team's namespace, and its probes need to reach the shop. Listing
their pods by label would tie the shop's policy to how another team labels its pods. **Selecting
their namespace by its labels** ties it to something the cluster's operators control instead:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-monitoring
  namespace: shop
spec:
  podSelector:
    matchLabels:
      app: shop
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          purpose: monitoring
    ports:
    - port: 8080
```

```
ana@laptop:~/shop$ kubectl apply -f allow-monitoring.yaml
networkpolicy.networking.k8s.io/allow-monitoring created
ana@laptop:~/shop$ kubectl label namespace other purpose=monitoring
namespace/other labeled
ana@laptop:~/shop$ kubectl -n other exec stranger -- wget -qO- -T 3 shop.shop
shop 1.0 on shop-774b84ff8c-4zxcl
```

The policy was applied first and matched nothing, because no namespace had the label. The moment
`other` was labelled `purpose=monitoring`, every pod in it could reach the shop on port 8080, and the
policy did not change. That is also the risk: whoever may label namespaces may now open this path.
Kubernetes labels every namespace with `kubernetes.io/metadata.name` and its own name, a label nobody
can change, and selecting on that one is the safer choice when the source is one particular
namespace.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Two namespaces. In shop, the pod front and the pods of shop, port 8080. In other, labelled purpose monitoring, the pod stranger. Under deny-all, every arrow into shop is cut. allow-front opens the arrow from front to shop on 8080. allow-monitoring opens the arrow from any pod in a namespace labelled purpose monitoring to shop on 8080. Out of front, front-egress allows only shop on 8080, and front-dns allows kube-dns on port 53.\"><defs><marker id=\"np-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"np-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"420\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"36\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">namespace: shop</text><rect x=\"470\" y=\"20\" width=\"230\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"486\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">namespace: other</text><text x=\"486\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">purpose=monitoring</text><text x=\"585\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">namespace: kube-system</text><rect x=\"50\" y=\"90\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">front</text><text x=\"110.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app=front</text><rect x=\"290\" y=\"90\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><text x=\"350.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">app=shop :8080</text><rect x=\"525\" y=\"70\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">stranger</text><rect x=\"525\" y=\"196\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">kube-dns</text><text x=\"585.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">:53</text><path d=\"M172 115 L288 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#np-ah-phosphor)\"></path><text x=\"230\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">allow-front</text><path d=\"M523 92 L412 108\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#np-ah-phosphor)\"></path><text x=\"585\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">allow-monitoring</text><path d=\"M110 142 L110 218 L523 218\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#np-ah-amber)\"></path><text x=\"300\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">front-dns</text><text x=\"230\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">front-egress</text></svg>", "caption": "Each arrow is a rule somebody wrote. Everything that has no arrow is refused, once a policy selects the pod at that end."}
```
