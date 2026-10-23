---
title: linkbox's Deployment, field by field
version: 1
---

The refusals of the last section listed what the restricted profile wants. **Every field it asked
for is one of lesson 9's flags under another name**, and the manifest below sets them all, plus the
two writable places linkbox needs and a memory limit. `kubernetes` lesson 25 went through the
security context on a service of its own; here each field is tied to the run that showed why it is
there.

### The token, which is not in the repository

linkbox reads its admin token from `LINKBOX_TOKEN`, since lesson 6. In the cluster it comes from a
Secret, and the Secret is created with a command, from random bytes, and never written to a file:

```
ana@vm:~/linkbox$ kubectl create secret generic linkbox -n linkbox --from-literal=token="$(head -c 18 /dev/urandom | base64)"
secret/linkbox created
```

**Nothing in `k8s/` contains the token**, only the Secret's name. The file can be committed,
reviewed and scanned by lesson 6's gitleaks without anything to find. The Secret lives in the
cluster's own store, base64-encoded rather than encrypted unless the cluster is configured to
encrypt it at rest, which `kubernetes` lesson 23's access rules then protect; lesson 17 replaces a
long-lived token like this with one issued per need.

### The manifest

Save it as `k8s/linkbox.yaml`:

```schooling-example
{"language": "yaml", "file": "k8s/linkbox.yaml", "parts": [{"code": "# linkbox in its own namespace, which Pod Security Admission holds to the\n# restricted profile: a pod that could run as root, escalate or keep a\n# capability is refused before it is scheduled.\napiVersion: v1\nkind: Namespace\nmetadata:\n  name: linkbox\n  labels:\n    pod-security.kubernetes.io/enforce: restricted\n    pod-security.kubernetes.io/enforce-version: latest", "note": "The namespace carries its own rule. `enforce: restricted` makes Pod Security Admission refuse any pod here that breaks the restricted profile; `enforce-version: latest` judges by the profile of the cluster's own Kubernetes version."}, {"code": "---\napiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: linkbox\n  namespace: linkbox\nspec:\n  replicas: 1\n  selector:\n    matchLabels:\n      app: linkbox\n  template:\n    metadata:\n      labels:\n        app: linkbox\n    spec:", "note": "The Deployment: one replica of linkbox, found by its label."}, {"code": "      automountServiceAccountToken: false", "note": "No token for the Kubernetes API is mounted in the pod. linkbox never talks to the API, so a token there would only be something to steal; `kubernetes` lesson 23 is about what such a token can do."}, {"code": "      securityContext:\n        runAsNonRoot: true\n        seccompProfile:\n          type: RuntimeDefault", "note": "Pod-wide settings. `runAsNonRoot` makes the kubelet refuse to start a container whose user is 0, the check lesson 9 said an image's `USER` cannot make. `RuntimeDefault` is the container runtime's default seccomp filter, the one lesson 9 watched refuse a call, named explicitly because the restricted profile requires it."}, {"code": "      containers:\n        - name: linkbox\n          image: localhost:5000/linkbox:main", "note": "The image the pipeline pushed, by the name the admission rule of this lesson checks."}, {"code": "          ports:\n            - containerPort: 8000\n          env:\n            - name: LINKBOX_TOKEN\n              valueFrom:\n                secretKeyRef:\n                  name: linkbox\n                  key: token", "note": "The token comes from a Secret called `linkbox`, created with `kubectl` and never written into the repository."}, {"code": "          securityContext:\n            allowPrivilegeEscalation: false\n            readOnlyRootFilesystem: true\n            capabilities:\n              drop: [\"ALL\"]", "note": "The flags of lesson 9, as fields. `allowPrivilegeEscalation: false` sets `no_new_privs`; the filesystem is read-only; every capability is dropped."}, {"code": "          resources:\n            requests:\n              cpu: 50m\n              memory: 64Mi\n            limits:\n              memory: 128Mi", "note": "A request is what the scheduler reserves; a limit is the ceiling. 128Mi is about three times the 39 MiB lesson 9 measured. There is no CPU limit: one set too low shows up as latency rather than as an error, as `kubernetes` lesson 19 measured."}, {"code": "          volumeMounts:\n            - name: tmp\n              mountPath: /tmp\n            - name: data\n              mountPath: /data\n      volumes:\n        - name: tmp\n          emptyDir: {}\n        - name: data\n          emptyDir: {}", "note": "The two writable places, as `emptyDir` volumes: lesson 9's two `tmpfs`, here on the node's disk and gone with the pod."}, {"code": "---\napiVersion: v1\nkind: Service\nmetadata:\n  name: linkbox\n  namespace: linkbox\nspec:\n  selector:\n    app: linkbox\n  ports:\n    - port: 80\n      targetPort: 8000", "note": "The Service gives the pods one stable address inside the cluster, port 80 to the container's 8000."}]}
```

Two choices in it are worth a sentence more than a note. **The namespace is in the same file as the
Deployment**, with its Pod Security label, so the rule travels with the application and a fresh
cluster gets both from one `kubectl apply`. And **`runAsNonRoot` is checked against the image**: the
kubelet reads the numeric `USER` the image declares, 65532 here, and refuses to start a container
whose user is 0. An image that named its user by a name instead of a number would be refused too,
because the kubelet cannot tell from a name whether it is root.

### Apply it

```
ana@vm:~/linkbox$ kubectl apply -f k8s/linkbox.yaml
Warning: resource namespaces/linkbox is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
namespace/linkbox configured
deployment.apps/linkbox created
service/linkbox created
ana@vm:~/linkbox$ kubectl rollout status deployment/linkbox -n linkbox --timeout=120s
Waiting for deployment "linkbox" rollout to finish: 0 of 1 updated replicas are available...
deployment "linkbox" successfully rolled out
ana@vm:~/linkbox$ kubectl get pods -n linkbox
NAME                       READY   STATUS    RESTARTS   AGE
linkbox-56f7558485-jsxj4   1/1     Running   0          4s
```

**One pod, running.** The warning above it is about the namespace, which the last section created
with `kubectl create` rather than from this file: `kubectl apply` keeps a note of what it last
applied on every object it manages, found none on the namespace, and added it. From now on the file
is the namespace's source, labels included. Ask the process what it holds, with the same line of
Python as lesson 9:

```
ana@vm:~/linkbox$ status='import re; print("".join(l for l in open("/proc/1/status") if re.match("(Uid|Cap|NoNewPrivs|Seccomp)", l)), end="")'
ana@vm:~/linkbox$ kubectl exec -n linkbox deployment/linkbox -- python3 -c "$status"
Uid:	65532	65532	65532	65532
CapInh:	0000000000000000
CapPrm:	0000000000000000
CapEff:	0000000000000000
CapBnd:	0000000000000000
CapAmb:	0000000000000000
NoNewPrivs:	1
Seccomp:	2
Seccomp_filters:	1
ana@vm:~/linkbox$ kubectl exec -n linkbox deployment/linkbox -- python3 -c "print(open('/proc/mounts').read(), end='')" | grep -E ' (/|/tmp|/data) ' | sed -E 's/,(lower|upper|work)dir=[^, ]*//g'
overlay / overlay ro,relatime,uuid=on 0 0
/dev/vda /tmp ext4 rw,relatime,discard,no_prefetch_block_bitmaps,resv_strict,resuid=65534,resgid=65534 0 0
/dev/vda /data ext4 rw,relatime,discard,no_prefetch_block_bitmaps,resv_strict,resuid=65534,resgid=65534 0 0
```

**The same status as lesson 9's staging container**: user 65532, an empty bounding set,
`NoNewPrivs` 1, seccomp filtering. The mount table shows the root read-only and the two volumes
writable, as directories on the node's own disk, which is why they appear as `/dev/vda`. One difference from Docker: an `emptyDir` lives on the node's disk, not in memory, unless
it is declared with `medium: Memory`, and it does not carry the `noexec` option a `tmpfs` from
Docker had.

### And it answers

The Service is reachable from inside the cluster. `kubectl port-forward` lends it a port on your
machine for as long as it runs:

```
ana@vm:~/linkbox$ token=$(kubectl get secret linkbox -n linkbox -o jsonpath='{.data.token}' | base64 -d)
ana@vm:~/linkbox$ curl -s -X POST -H "X-Token: $token" -d url=https://example.org/handbook http://127.0.0.1:8080/links
{"code":"96QGlQ"}
ana@vm:~/linkbox$ curl -s -o /dev/null -w "%{http_code}\n" -X POST -d url=https://example.org/handbook http://127.0.0.1:8080/links
401
```

**201 with the token from the Secret, 401 without it.** The application behaves exactly as it did
on lesson 4's staging network; only the way it was started changed, and every restriction of
lesson 9 came with it.

The data, though, is in an `emptyDir`, and it goes when the pod goes. That is honest for a study
cluster and wrong for production, where `/data` would be a PersistentVolumeClaim; and SQLite on a
volume means one replica, which is why the Deployment says `replicas: 1`.
