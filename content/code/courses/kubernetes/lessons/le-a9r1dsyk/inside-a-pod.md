---
title: What the containers of one pod share
version: 1
---

**A pod is not a container with a different name.** It is a small group of containers that the
kubelet always starts on the same node and wraps in the same namespaces, so that they behave like
processes on one small machine: one network interface, one address, one hostname, and any volumes
you give them. Most pods hold a single container, and then the difference is invisible. This one
holds three, to make it visible:

```schooling-example
{"language": "yaml", "file": "pod.yaml", "parts": [{"code": "apiVersion: v1\nkind: Pod\nmetadata:\n  name: web\n  labels:\n    app: web\n", "note": "**A bare Pod**, written by hand, with nothing above it. The rest of this lesson is about why that is unusual."}, {"code": "spec:\n  initContainers:\n  - name: greet\n    image: busybox:1.37\n    command: [\"sh\", \"-c\", \"echo 'hello from the init container' > /work/greeting\"]\n    volumeMounts:\n    - name: work\n      mountPath: /work\n", "note": "**An init container runs first, to completion, before any other starts.** This one writes a file into the shared volume and exits."}, {"code": "  containers:\n  - name: shop\n    image: shop:1.0\n    env:\n    - name: CONFIG_FILE\n      value: /work/greeting\n    volumeMounts:\n    - name: work\n      mountPath: /work\n", "note": "**The shop**, told by `CONFIG_FILE` to read its greeting from the file the init container left behind, at the same path in the same volume."}, {"code": "  - name: sidecar\n    image: busybox:1.37\n    command: [\"sh\", \"-c\", \"while true; do wget -qO- localhost:8080; sleep 5; done\"]\n", "note": "**A second container in the same pod.** It asks the shop for a page every five seconds, at `localhost`, because the two share one network namespace."}, {"code": "  volumes:\n  - name: work\n    emptyDir: {}\n", "note": "**The volume they share**, an `emptyDir`: created empty with the pod, on the node's disk, and deleted with it."}]}
```

```
ana@laptop:~/shop$ kubectl apply -f pod.yaml
pod/web created
ana@laptop:~/shop$ kubectl get pod web -o wide
NAME   READY   STATUS    RESTARTS   AGE   IP           NODE          NOMINATED NODE   READINESS GATES
web    2/2     Running   0          3s    10.244.1.2   shop-worker   <none>           <none>
```

`READY 2/2` counts the two long-running containers. The init container is not in the count,
because it is not supposed to be running any more; its own status says it finished:

```
ana@laptop:~/shop$ kubectl get pod web -o custom-columns=INIT:.status.initContainerStatuses[0].state.terminated.reason,IP:.status.podIP
INIT        IP
Completed   10.244.1.2
```

## One address, one hostname

The sidecar's log is the shop's answers, fetched from `localhost`:

```
ana@laptop:~/shop$ kubectl logs web -c sidecar
shop 1.0 on web
shop 1.0 on web
```

**`localhost` inside a pod is the pod, not the container**, so the sidecar reaches the shop's port
8080 without knowing any address. Both containers also report the same hostname, the pod's name:

```
ana@laptop:~/shop$ kubectl exec web -c sidecar -- hostname
web
```

The flip side is that two containers of one pod cannot both listen on the same port, exactly as two
programs on one machine cannot.

## One volume, two containers

```
ana@laptop:~/shop$ kubectl exec web -c sidecar -- wget -qO- localhost:8080/config
GREETING=
/work/greeting: hello from the init container
```

The shop read `/work/greeting`, a file it never wrote: the init container wrote it into the
`emptyDir` before the shop started. `GREETING=` is empty because this pod sets no such variable;
lesson 13 fills it from a ConfigMap.

## When a second container belongs in the pod

Put two containers in one pod **only when they must live and die together**: a helper that
prepares something before the application starts (an init container), or one that serves the
application from beside it, sharing its network or its files (a sidecar). A database and the web
application that uses it are not that: they scale differently, fail differently and are updated
at different times, so they are two Deployments, not two containers of one pod.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"The pod web, on node shop-worker, drawn as one box with one address, 10.244.1.2, and one hostname, web. Inside it, the init container greet runs first and exits, writing a file into the emptyDir volume work. Then shop and sidecar run side by side: sidecar reaches shop at localhost:8080, and shop reads the file from the same volume.\"><defs><marker id=\"pod-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"pod-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"40\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">pod web · on shop-worker</text><text x=\"680\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.244.1.2</text><text x=\"680\" y=\"56\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one address, one hostname</text><rect x=\"40\" y=\"80\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"115.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">greet</text><text x=\"115.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">runs first, then exits</text><rect x=\"270\" y=\"80\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"355.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><text x=\"355.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">:8080</text><rect x=\"510\" y=\"80\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sidecar</text><text x=\"595.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">wget</text><path d=\"M510 105 L442 105\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pod-ah-paper-dim)\"></path><text x=\"476\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">localhost:8080</text><rect x=\"200\" y=\"196\" width=\"320\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">work</text><text x=\"360.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">emptyDir, deleted with the pod</text><path d=\"M115 132 L115 218 L198 218\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pod-ah-amber)\"></path><text x=\"120\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">writes the greeting</text><path d=\"M355 194 L355 132\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pod-ah-amber)\"></path><text x=\"362\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">reads it</text></svg>", "caption": "Everything inside the dashed line is shared: the address, the hostname, the volume. The init container is finished before the other two start."}
```
