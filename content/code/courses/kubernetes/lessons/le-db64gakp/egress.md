---
title: Egress, and the DNS everybody forgets
version: 1
---

Ingress rules protect a pod from callers. **Egress rules limit what a pod may call**, which is what
contains a compromised pod: a front end that can reach only the shop cannot be used to reach the
database, the API server or the internet.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: front-egress
  namespace: shop
spec:
  podSelector:
    matchLabels:
      app: front
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: shop
    ports:
    - port: 8080
```

`front-egress` selects `front` and allows it one destination: pods labelled `app: shop`, port 8080.
Everything else going out of `front` is now refused, and that includes something the shop needs
before any packet reaches it:

```
ana@laptop:~/shop$ kubectl apply -f deny-egress.yaml
networkpolicy.networking.k8s.io/front-egress created
ana@laptop:~/shop$ kubectl -n shop exec front -- wget -qO- -T 3 shop
wget: bad address 'shop'
command terminated with exit code 1
ana@laptop:~/shop$ kubectl -n shop exec front -- wget -qO- -T 3 shop.shop.svc.cluster.local
wget: bad address 'shop.shop.svc.cluster.local'
command terminated with exit code 1
```

**`bad address 'shop'` is a DNS failure, not a connection failure.** Before `wget` can connect, it
asks CoreDNS what `shop` means, and CoreDNS is a pod in `kube-system` on port 53, which the policy did
not allow. The full name fails the same way, because it is the question, not the name, that is
blocked. This is the most common surprise with egress policies, and the fix is a policy every
namespace with egress rules ends up having:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: front-dns
  namespace: shop
spec:
  podSelector:
    matchLabels:
      app: front
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
```

Both selectors are inside one `to` entry, so they combine: pods labelled `k8s-app: kube-dns` **in**
the namespace named `kube-system`. Written as two separate entries, each with a leading dash, they
would mean any pod labelled `kube-dns` anywhere, **or** every pod in `kube-system`, which is much
wider. That one dash is the easiest way to get a NetworkPolicy wrong.

```
ana@laptop:~/shop$ kubectl apply -f allow-dns.yaml
networkpolicy.networking.k8s.io/front-dns created
ana@laptop:~/shop$ kubectl -n shop exec front -- wget -qO- -T 3 shop
shop 1.0 on shop-774b84ff8c-zmqss
ana@laptop:~/shop$ kubectl -n shop exec front -- wget -qO- -T 3 http://kubernetes.default:443
wget: download timed out
command terminated with exit code 1
```

Names resolve again and the shop answers. The API server, which `front` has no reason to call, does
not: `kubernetes.default` resolved to its address, and the connection then timed out. **Two policies,
and `front` can reach exactly two things.**

| policy | selects | allows |
|---|---|---|
| `deny-all` | every pod in `shop` | nothing in |
| `allow-front` | `app: shop` | in from `app: front`, port 8080 |
| `allow-monitoring` | `app: shop` | in from namespaces labelled `purpose: monitoring`, port 8080 |
| `front-egress` | `app: front` | out to `app: shop`, port 8080 |
| `front-dns` | `app: front` | out to `kube-dns` in `kube-system`, port 53 |
