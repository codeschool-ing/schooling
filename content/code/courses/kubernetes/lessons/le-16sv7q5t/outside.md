---
title: From outside the cluster: NodePort and LoadBalancer
version: 1
---

A ClusterIP exists only inside the cluster. **The two other types do not replace it; they add a way
in on top of it**, and each one is the type before it plus one more thing.

## NodePort: the same port on every node

```yaml
apiVersion: v1
kind: Service
metadata:
  name: shop-nodeport
spec:
  type: NodePort
  selector:
    app: shop
  ports:
  - port: 80
    targetPort: http
    nodePort: 30080
```

```
ana@laptop:~/shop$ kubectl apply -f shop-nodeport.yaml
service/shop-nodeport created
ana@laptop:~/shop$ kubectl get service shop-nodeport
NAME            TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
shop-nodeport   NodePort   10.96.233.128   <none>        80:30080/TCP   0s
ana@laptop:~/shop$ kubectl get nodes -o custom-columns=NAME:.metadata.name,ADDRESS:.status.addresses[0].address
NAME                 ADDRESS
shop-control-plane   172.18.0.2
shop-worker          172.18.0.3
shop-worker2         172.18.0.4
ana@laptop:~/shop$ curl -s 172.18.0.3:30080; curl -s localhost:8080
shop 1.0 on shop-59d88b64fd-h8h2m
shop 1.0 on shop-59d88b64fd-cp8t7
```

`80:30080/TCP`: port 80 on the Service's own cluster address, as before, plus 30080 on every node.
The first `curl` asked `shop-worker` directly by its address; the second went to the laptop's 8080,
which this cluster maps to the control-plane node's 30080. **Any node answers for every NodePort
Service**, whether a pod of it runs there or not. NodePorts come from a fixed range, 30000 to 32767 by
default, which is why nothing public is ever served on one directly: something in front translates a
normal port to it.

## LoadBalancer: an address of its own

That something is what a LoadBalancer Service asks for. Kubernetes does not provide the load
balancer: **it asks the cloud for one**, through a component called the cloud controller manager, and
writes the address it gets into the Service. On this laptop the kind project's `cloud-provider-kind`
plays the cloud, answering each LoadBalancer Service with a small Envoy proxy on Docker's network.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: shop-lb
spec:
  type: LoadBalancer
  selector:
    app: shop
  ports:
  - port: 80
    targetPort: http
```

```
ana@laptop:~/shop$ kubectl apply -f shop-lb.yaml
service/shop-lb created
ana@laptop:~/shop$ kubectl get service shop-lb
NAME      TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
shop-lb   LoadBalancer   10.96.228.208   172.18.0.5    80:31269/TCP   7s
ana@laptop:~/shop$ curl -s 172.18.0.5
shop 1.0 on shop-59d88b64fd-cp8t7
ana@laptop:~/shop$ docker ps --filter label=io.x-k8s.cloud-provider-kind.cluster=shop --format "{{.Names}}\t{{.Image}}"
kindccm-698a25f42e67	envoyproxy/envoy:v1.33.2
ana@laptop:~/shop$ kubectl delete service shop-lb
service "shop-lb" deleted from default namespace
```

`EXTERNAL-IP` is `172.18.0.5`, an address on Docker's network that belongs to no node, and the shop
answers on it at port 80, with no NodePort in the URL. Underneath, the Service also got a NodePort,
`31269`, which is what the balancer sends traffic to: a LoadBalancer is a NodePort with a machine in
front. The `docker ps` line is that machine. On a cloud it would be the provider's balancer, billed by
the hour, which is why a cluster with fifty Services usually has one balancer in front of one ingress
controller (lesson 16) rather than fifty.

| type | reachable from | built on |
|---|---|---|
| ClusterIP | inside the cluster | an address from the service range and an endpoint list |
| NodePort | anything that can reach a node | a ClusterIP, plus one port on every node |
| LoadBalancer | the address a provider assigns | a NodePort, plus a balancer in front of the nodes |
