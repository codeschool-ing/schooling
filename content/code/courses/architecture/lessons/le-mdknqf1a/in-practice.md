---
title: Where you will meet these
version: 1
---

Few teams run Consul and a gateway by hand the way the lab does, because the platforms they deploy on
already contain both:

| platform | the registry | discovery | the gateway |
| --- | --- | --- | --- |
| Kubernetes | etcd, holding every pod and its readiness | a Service: a stable name and address in front of the ready pods, through the cluster's DNS | an Ingress or Gateway API controller: NGINX, Traefik, Envoy Gateway |
| a service mesh on Kubernetes | the same | the sidecar chooses an instance, client-side | an ingress gateway built on the mesh's proxy |
| AWS without Kubernetes | Cloud Map, or the load balancer's target groups | DNS, or the load balancer | API Gateway or an Application Load Balancer |
| virtual machines | Consul, as in the lab | Consul's DNS or HTTP API | any of the gateways above, reading Consul |

The ideas are the ones the lab built, under other names. A Kubernetes **readiness probe** is the lab's
`/health`; a pod failing it is removed from the Service's endpoints exactly as `stock-2` was removed from
the gateway's routes. A **Service** is server-side discovery with the load balancing done by the node
itself. And etcd is the Raft store that the whole arrangement trusts, which is why Kubernetes clusters
run three or five control-plane nodes.

For Quitanda, still a monolith with a stock service beside it, the useful part today is the gateway: one
door, with TLS, rate limits and request ids in one place. The registry arrives with the platform when
the instances start moving on their own.

When you are done, stop the lab:

```sh
docker compose down
```
