---
title: The API server's own log
version: 1
---

**Every change to a cluster is a request to its API server**, whoever makes it: Flux applying a
commit, a person running `kubectl`, an operator writing a Secret. The API server can write each
request to an audit log as it handles it, with the user, the verb, the object and the time. It is
the one record that sees the changes nobody committed.

It is off unless the API server is started with a policy saying what to record, and on a managed
cluster it is a setting of the provider's: EKS, GKE and AKS each send it to their own log service
when asked. On kind it is a pair of flags passed through the cluster file, and **flags of the API
server are fixed when the cluster is created**. This course's cluster was created in lesson 1
without them, so the audit log is shown on a second, small cluster made for the purpose, beside the
first, and deleted afterwards.

The policy says what to record and how much of it. Save this as `~/setup/audit-policy.yaml`:

```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
- RequestReceived
rules:
- level: None
  resources:
  - group: coordination.k8s.io
    resources: ["leases"]
- level: Metadata
  resources:
  - group: ""
    resources: ["secrets"]
- level: RequestResponse
  verbs: ["create", "update", "patch", "delete"]
- level: None
```

The rules are read in order and the first that matches wins. Leases are renewed by every controller
every few seconds and say nothing, so they are dropped. **Secrets are recorded at `Metadata`**: who
did what to which Secret, and never the Secret's content, because an audit log that held every
secret would be the most valuable file in the company. Every other change is recorded with the
request and the response; and reads of anything but Secrets, the last rule, are not recorded at all,
a choice that keeps the log small and that a stricter policy would make differently.

The cluster file is lesson 1's without its ports, plus the two flags and the files they need. Save
it as `~/setup/audit-cluster.yaml`:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
# The next two patches are for the machine this was recorded on, which has
# cgroup v1 and forbids lowering a process's OOM score. Delete them on yours.
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri"]
    restrict_oom_score_adj = true
kubeadmConfigPatches:
- |
  kind: KubeletConfiguration
  failCgroupV1: false
- |
  kind: ClusterConfiguration
  apiServer:
    extraArgs:
    - name: audit-policy-file
      value: /etc/kubernetes/audit/policy.yaml
    - name: audit-log-path
      value: /var/log/kubernetes/audit.log
    extraVolumes:
    - name: audit-policy
      hostPath: /etc/kubernetes/audit
      mountPath: /etc/kubernetes/audit
      readOnly: true
      pathType: DirectoryOrCreate
    - name: audit-log
      hostPath: /var/log/kubernetes
      mountPath: /var/log/kubernetes
      pathType: DirectoryOrCreate
nodes:
- role: control-plane
  extraMounts:
  - hostPath: /home/ana/setup/audit-policy.yaml
    containerPath: /etc/kubernetes/audit/policy.yaml
    readOnly: true
```

`extraMounts` puts the policy into the node, and `extraVolumes` puts it, and the directory for the
log, into the API server's own container. Replace `/home/ana` with your home directory: kind needs
the path in full.

```
ana@laptop:~/setup$ kind create cluster --name audit --config audit-cluster.yaml --kubeconfig ~/.kube/audit --wait 2m --quiet
ana@laptop:~/setup$ KUBECONFIG=~/.kube/audit kubectl get nodes
NAME                  STATUS   ROLES           AGE   VERSION
audit-control-plane   Ready    control-plane   25s   v1.37.0
```

A person makes two changes, a ConfigMap and a Secret, and the log has them:

```
ana@laptop:~/setup$ export KUBECONFIG=~/.kube/audit
ana@laptop:~/setup$ kubectl create configmap note --from-literal=text=hello
configmap/note created
ana@laptop:~/setup$ kubectl create secret generic note --from-literal=password=not-in-the-log
secret/note created
ana@laptop:~/setup$ docker exec audit-control-plane cat /var/log/kubernetes/audit.log | jq -c 'select(.objectRef.name == "note" and .verb == "create") | {time: .requestReceivedTimestamp, user: .user.username, verb, resource: .objectRef.resource, name: .objectRef.name, level}'
{"time":"2026-10-16T04:54:37.474002Z","user":"kubernetes-admin","verb":"create","resource":"configmaps","name":"note","level":"RequestResponse"}
{"time":"2026-10-16T04:54:37.593582Z","user":"kubernetes-admin","verb":"create","resource":"secrets","name":"note","level":"Metadata"}
ana@laptop:~/setup$ docker exec audit-control-plane grep -c not-in-the-log /var/log/kubernetes/audit.log
0
ana@laptop:~/setup$ export KUBECONFIG=~/.kube/config
```

Two entries, one per request, each with the user, the verb, the object and the time to the
microsecond. The ConfigMap is recorded at `RequestResponse`, the Secret at `Metadata`, and `grep`
finds the Secret's value nowhere in the log: `0`.

**This is the record that catches a change nobody committed.** Flux would undo it on its next pass,
and the cluster would look as if nothing had happened; the audit log keeps the user, the time and
the object. Shipped to a log service, with alerts on changes by people to the namespaces Flux owns,
it turns "somebody used `kubectl` in production" from a rumour into an event.

```
ana@laptop:~/setup$ kind delete cluster --name audit --kubeconfig ~/.kube/audit
Deleting cluster "audit" ...
Deleted nodes: ["audit-control-plane"]
```
