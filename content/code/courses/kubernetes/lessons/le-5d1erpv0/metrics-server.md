---
title: Where the numbers come from
version: 1
---

**Every kubelet measures the containers on its node all the time**, because it needs the numbers to
enforce limits and to decide evictions. What a cluster does not have by default is anything that
collects those numbers in one place. metrics-server is that collector: every fifteen seconds it asks
each kubelet for its latest figures, keeps only the newest set in memory, and serves it through the
Kubernetes API. It keeps no history, which is the first thing to know about it.

It is not part of a kind cluster, so this lesson starts with `./up.sh` and then installs it from the
project's own release manifest:

```sh
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.9.0/components.yaml
kubectl -n kube-system rollout status deployment/metrics-server
```

The second command waits until it is running. **That manifest is what every transcript below ran**,
with one difference you will not see. The machine this course was recorded on cannot reach the
registry its image comes from, so there the same version was built from its source and the manifest
pointed at that copy.

## The kubelet's certificate

metrics-server talks to each kubelet over HTTPS, so it has to trust the certificate the kubelet
presents. In a kind cluster the kubelets sign their own by default, and the common workaround is a
flag that turns the check off. This course does the other thing: each kubelet asks the cluster's
certificate authority for a proper one.

```
ana@laptop:~/shop$ kubectl get csr -o custom-columns=NAME:.metadata.name,SIGNER:.spec.signerName,REQUESTOR:.spec.username,CONDITION:.status.conditions[0].type
NAME        SIGNER                                        REQUESTOR                        CONDITION
csr-c8sb9   kubernetes.io/kubelet-serving                 system:node:shop-control-plane   Approved
csr-djvgq   kubernetes.io/kubelet-serving                 system:node:shop-worker          Approved
csr-hw8rp   kubernetes.io/kubelet-serving                 system:node:shop-control-plane   Approved
csr-wp6bj   kubernetes.io/kubelet-serving                 system:node:shop-worker2         Approved
csr-wqtcn   kubernetes.io/kube-apiserver-client-kubelet   system:bootstrap:abcdef          Approved
csr-zc5fw   kubernetes.io/kube-apiserver-client-kubelet   system:bootstrap:abcdef          Approved
```

The four `kubelet-serving` requests are those, one from each worker and two from the control-plane
node, each made by the node itself and approved by `up.sh` as it arrived (lesson 1). The two `kube-apiserver-client-kubelet` requests are
older; they are how the worker nodes got their client certificates when they joined, and the cluster
approves those on its own.

## Plugged into the API

metrics-server does not get a URL of its own. **It registers an API group, `metrics.k8s.io`, with
the API server**, which forwards those requests to it. That registration is an APIService object:

```
ana@laptop:~/shop$ kubectl get apiservice v1beta1.metrics.k8s.io
NAME                     SERVICE                      AVAILABLE   AGE
v1beta1.metrics.k8s.io   kube-system/metrics-server   True        22s
ana@laptop:~/shop$ kubectl -n kube-system get deployment metrics-server -o jsonpath="{.spec.template.spec.containers[0].args}"; echo
["--cert-dir=/tmp","--secure-port=10250","--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname","--kubelet-use-node-status-port","--metric-resolution=15s"]
```

`AVAILABLE True` means the API server can reach it. The arguments are the manifest's own, and none of
them is `--kubelet-insecure-tls`: the certificates above made that flag unnecessary. Lesson 45 comes
back to APIServices as a way to extend the cluster; this is the most common one in the wild.
