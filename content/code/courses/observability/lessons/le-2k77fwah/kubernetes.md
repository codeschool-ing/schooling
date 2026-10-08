---
title: Readiness and liveness on Kubernetes
version: 2
---

Kubernetes is where the three questions get their consequences, and this lesson needs a cluster of
its own. **kind** runs one inside Docker, a whole Kubernetes in one container, which is all a probe
needs. These lines install kind and `kubectl` from their official releases, at the versions this
lesson was recorded with, and create the cluster. The last one copies the shop's image into it:
the manifests below run that image, and the cluster cannot build it:

```sh
ARCH=$(dpkg --print-architecture)
curl -Lo kind https://github.com/kubernetes-sigs/kind/releases/download/v0.33.0/kind-linux-$ARCH
curl -Lo kubectl https://dl.k8s.io/release/v1.37.0/bin/linux/$ARCH/kubectl
sudo install kind kubectl /usr/local/bin/
rm kind kubectl
kind create cluster --name lab
kind load docker-image shop:1.4.0 --name lab
mkdir -p ~/shop/k8s
```

The cluster is one more container on the same machine, and one command deletes it at the end of
the lesson. The machine this course was
recorded on is a computer nested inside another, and its cluster needed two settings that an
ordinary Linux machine does not; on yours, these lines are the whole of it.

The cluster runs two copies of a small web server whose probes can be broken on purpose. Save the
file as `~/shop/k8s/probe-demo.yaml`, with the copy button:

```schooling-example
{
  "language": "yaml",
  "file": "k8s/probe-demo.yaml",
  "parts": [
    {
      "code": "# Two copies of a small web server whose probes a test can break on purpose:\n# /ready fails while /tmp/unready exists, /live while /tmp/stuck does.\napiVersion: v1\nkind: ConfigMap\nmetadata: {name: web}\ndata:\n  web.py: |\n    import os\n    from http.server import BaseHTTPRequestHandler, HTTPServer\n\n    FAILS_IF = {\"/live\": \"/tmp/stuck\", \"/ready\": \"/tmp/unready\"}\n\n    class Handler(BaseHTTPRequestHandler):\n        def do_GET(self):\n            marker = FAILS_IF.get(self.path)\n            ok = not (marker and os.path.exists(marker))\n            self.send_response(200 if ok else 503)\n            self.end_headers()\n            self.wfile.write(os.environ[\"HOSTNAME\"].encode() + b\"\\n\")\n\n        def log_message(self, *args):\n            pass\n\n    HTTPServer((\"\", 8000), Handler).serve_forever()\n---\n",
      "note": "The program, in a ConfigMap so the lab's image can run it. `/live` fails while `/tmp/stuck` exists and `/ready` while `/tmp/unready` does, so a test can break either probe with one `touch`."
    },
    {
      "code": "apiVersion: apps/v1\nkind: Deployment\nmetadata: {name: web}\nspec:\n  replicas: 2\n  selector: {matchLabels: {app: web}}\n  template:\n    metadata: {labels: {app: web}}\n    spec:\n      containers:\n        - name: web\n          image: shop:1.4.0\n          imagePullPolicy: Never\n          command: [python, /web/web.py]\n          volumeMounts: [{name: code, mountPath: /web}]\n"
    },
    {
      "code": "          readinessProbe:\n            httpGet: {path: /ready, port: 8000}\n            periodSeconds: 2\n            failureThreshold: 2\n",
      "note": "**Readiness**, every two seconds; two failures in a row take the pod out of the Service."
    },
    {
      "code": "          livenessProbe:\n            httpGet: {path: /live, port: 8000}\n            periodSeconds: 3\n            failureThreshold: 3\n",
      "note": "**Liveness**, every three seconds; three failures in a row and the container is killed and started again."
    },
    {
      "code": "      volumes: [{name: code, configMap: {name: web}}]\n---\napiVersion: v1\nkind: Service\nmetadata: {name: web}\nspec:\n  selector: {app: web}\n  ports: [{port: 80, targetPort: 8000}]\n",
      "note": "Two copies behind one Service, so that taking one out leaves somewhere for traffic to go."
    }
  ]
}
```

```
ana@obs:~/shop$ kubectl apply -f k8s/probe-demo.yaml
configmap/web created
deployment.apps/web created
service/web created
ana@obs:~/shop$ kubectl get pods
NAME                  READY   STATUS    RESTARTS   AGE
web-b874f8dc4-nwb5g   1/1     Running   0          3s
web-b874f8dc4-ssql6   1/1     Running   0          3s
```

Both copies are `1/1` ready. **Readiness first**: one copy is told to fail it.

```
ana@obs:~/shop$ kubectl exec web-b874f8dc4-nwb5g -- touch /tmp/unready
ana@obs:~/shop$ kubectl get pods
NAME                  READY   STATUS    RESTARTS   AGE
web-b874f8dc4-nwb5g   0/1     Running   0          12s
web-b874f8dc4-ssql6   1/1     Running   0          12s
```

The pod is `0/1`: running, not restarted, and not ready. What that changes is in the Service's
endpoint slice, the list a Service sends traffic to:

```
ana@obs:~/shop$ kubectl get endpointslice -l kubernetes.io/service-name=web -o json | jq -r '.items[].endpoints[] | [.targetRef.name, .conditions.ready] | @tsv'
web-b874f8dc4-nwb5g	false
web-b874f8dc4-ssql6	true
```

**The Service now sends everything to the other copy.** Nothing was killed, and when the file is
removed the pod is put back without anybody doing anything. This is the right response to *I cannot
serve right now*: a pod that has lost its database, is warming a cache, or is draining before a
shutdown.

**Then liveness**, on the other copy:

```
ana@obs:~/shop$ kubectl exec web-b874f8dc4-ssql6 -- touch /tmp/stuck
ana@obs:~/shop$ kubectl get pods
NAME                  READY   STATUS    RESTARTS     AGE
web-b874f8dc4-nwb5g   1/1     Running   0            53s
web-b874f8dc4-ssql6   1/1     Running   1 (2s ago)   53s
```

One restart, a few seconds ago. The events say why, in Kubernetes' own words:

```
ana@obs:~/shop$ kubectl get events --field-selector involvedObject.name=web-b874f8dc4-ssql6 --sort-by=.lastTimestamp -o custom-columns=REASON:.reason,MESSAGE:.message | grep -E 'REASON|Liveness|Killing'
REASON      MESSAGE
Unhealthy   Liveness probe failed: HTTP probe failed with statuscode: 503
Killing     Container web failed liveness probe, will be restarted
```

The probe got a 503, the code the program returns while `/tmp/stuck` exists, three times in a row,
and the kubelet killed the container. The restart cured it because the fault lived inside the container: a new container
starts with a fresh filesystem, without `/tmp/stuck`. That is the only kind of fault a restart can
cure, and the next section is about the other kind.

Two settings decide how long all this takes. `periodSeconds` times `failureThreshold` is the delay
between a fault and the action, nine seconds for this liveness probe. A third probe, `startupProbe`,
holds the other two back while a slow service starts, so that liveness does not kill a process that
is still loading.