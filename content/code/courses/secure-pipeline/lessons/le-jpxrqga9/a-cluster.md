---
title: x
version: 1
---

Save it as `~/kind.yaml`:

```yaml
# The study cluster: one node, which pulls localhost:5000/... from the
# registry container on this machine.
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry]
    config_path = "/etc/containerd/certs.d"
# The next two patches are for the machine this was recorded on, which has
# cgroup v1 and forbids lowering a process's OOM score. Delete them on yours.
- |-
  [plugins."io.containerd.grpc.v1.cri"]
    restrict_oom_score_adj = true
kubeadmConfigPatches:
- |
  kind: KubeletConfiguration
  failCgroupV1: false
```
