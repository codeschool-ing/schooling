---
title: x
version: 1
---

Save it as `~/quota.yaml`:

```yaml
# What the linkbox namespace may use, set by whoever runs the cluster rather
# than by the application's repository. The LimitRange fills in a memory
# limit for a container that declares none and refuses one above 256Mi; the
# ResourceQuota caps the namespace as a whole.
apiVersion: v1
kind: LimitRange
metadata:
  name: linkbox
  namespace: linkbox
spec:
  limits:
    - type: Container
      default:
        memory: 128Mi
      defaultRequest:
        memory: 64Mi
      max:
        memory: 256Mi
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: linkbox
  namespace: linkbox
spec:
  hard:
    pods: "4"
    requests.memory: 512Mi
    limits.memory: 512Mi
```
