---
title: Mutual TLS, and the request that is refused
version: 1
---

The `connection_security_policy="mutual_tls"` above means the client's proxy and the server's proxy
authenticated each other with certificates and encrypted the connection. Neither application has a
line of TLS code. `istiod` issues each workload a certificate for its identity, the SPIFFE name in
`source_principal`, and rotates it.

By default Istio is **permissive**: it accepts mutual TLS from proxies and plain text from anything else,
so that a mesh can be adopted one service at a time. A pod outside the mesh shows it:

```
ana@obs:~/shop$ kubectl create namespace outside && kubectl -n outside run probe --image=shop:1.4.0 --image-pull-policy=Never --restart=Never --command -- sleep 600
namespace/outside created
pod/probe created
ana@obs:~/shop$ kubectl -n outside exec probe -- python -c "import urllib.request; print(urllib.request.urlopen('http://server.shop-mesh/', timeout=3).status)"
200
```

**200.** The pod in the `outside` namespace has no proxy and no certificate, and it was answered. A
policy makes the namespace strict:

```
ana@obs:~/shop$ cat k8s/strict.yaml
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata: {name: default, namespace: shop-mesh}
spec:
  mtls: {mode: STRICT}
ana@obs:~/shop$ kubectl apply -f k8s/strict.yaml
peerauthentication.security.istio.io/default created
```

The same request again:

```
ana@obs:~/shop$ kubectl -n outside exec probe -- python -c "import urllib.request; print(urllib.request.urlopen('http://server.shop-mesh/', timeout=3).status)" 2>&1 | tail -2
ConnectionResetError: [Errno 104] Connection reset by peer
command terminated with exit code 1
```

The connection was reset: the server's proxy asked for a certificate the probe did not have, and closed the connection before any HTTP was spoken. And the client inside the mesh, which has been requesting the server twice a second all
along, logged nothing in the last twenty seconds:

```
ana@obs:~/shop$ kubectl -n shop-mesh logs deploy/client -c client --since=20s | wc -l
0
```

**Zero lines: no error.** It never noticed the change, because its proxy already spoke mutual TLS.

Two observability notes. **Identity becomes a label**: `source_principal` says which workload made a
request, verified by a certificate rather than claimed in a header, which is what an audit of who
called a payments service wants. And **a refused connection has no HTTP status**: the outside pod's
request never became a request, so it appears in no request counter, only as a connection reset in the
proxy's statistics and in the caller's own error log.
