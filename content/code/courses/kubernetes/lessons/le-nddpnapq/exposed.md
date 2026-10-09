---
title: What the cluster already exposes
version: 1
---

After `./up.sh`, this lesson gives the cluster something to measure: two copies of the shop behind a
Service, and a busybox pod that asks it twenty times and then waits.

```sh
kubectl create deployment shop --image=shop:1.0 --replicas=2
kubectl expose deployment shop --port 80 --target-port 8080
kubectl run probe --image=busybox:1.37 --restart=Never --command -- sh -c "for i in \$(seq 20); do wget -qO- shop >/dev/null; done; sleep 3600"
```

**Every component of Kubernetes publishes its own measurements**, as plain text in the Prometheus
format, at an address called `/metrics`. A monitoring system collects them; nothing has to be
installed in the components themselves. The API server's own, read through kubectl:

```
ana@laptop:~/shop$ kubectl get --raw /metrics | grep -c "^# HELP"
296
```

Close to three hundred metrics, each with a line of help. One of them counts every request the API
server has answered, split by its labels:

```
ana@laptop:~/shop$ kubectl get --raw /metrics | grep "^apiserver_request_total{" | grep "resource=\"pods\"" | head -n 4
apiserver_request_total{code="200",component="apiserver",dry_run="",group="",resource="pods",scope="cluster",subresource="",verb="WATCH",version="v1"} 1
apiserver_request_total{code="200",component="apiserver",dry_run="",group="",resource="pods",scope="namespace",subresource="",verb="WATCH",version="v1"} 1
apiserver_request_total{code="200",component="apiserver",dry_run="",group="",resource="pods",scope="resource",subresource="",verb="DELETE",version="v1"} 4
apiserver_request_total{code="200",component="apiserver",dry_run="",group="",resource="pods",scope="resource",subresource="",verb="GET",version="v1"} 75
```

**Each line is one combination of labels and a counter that only grows**: 75 successful `GET`s of a
single pod, 4 `DELETE`s, one long-lived `WATCH` at cluster scope. A monitoring system scrapes this every
few seconds and keeps the history, so that a question such as "how many requests failed per second
last Tuesday at three" has an answer. The labels are also the cost: every new combination is a new
series to store, which is why a label holding something unbounded, such as a user id, is a classic way
to make a monitoring bill explode.

The kubelet publishes per-container figures, which is where metrics-server got its numbers in lesson
21:

```
ana@laptop:~/shop$ kubectl get --raw /api/v1/nodes/shop-worker/proxy/metrics/resource | grep "^container_memory_working_set_bytes" | grep shop | head -n 2
container_memory_working_set_bytes{container="shop",namespace="default",pod="shop-774b84ff8c-stdpb"} 1.769472e+06 1791322744035
ana@laptop:~/shop$ kubectl get --raw /api/v1/nodes/shop-worker/proxy/metrics/cadvisor | grep -c "^container_"
1054
```

The `resource` endpoint is the small set metrics-server uses: working-set memory of the shop's
container, about 1.7 MB, with a timestamp in milliseconds. The `cadvisor` endpoint is the full set,
over a thousand series on one node, covering CPU, memory, file system and network for every container.
