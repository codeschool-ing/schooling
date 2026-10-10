---
title: Mounting without a Secret
version: 1
---

The operator's design has one property some teams refuse: **the value ends up in a Kubernetes
Secret**, in etcd, readable by anybody allowed to read Secrets in that namespace. The **Secrets
Store CSI Driver** avoids that. It is a volume driver: a pod mounts a volume of class
`secrets-store.csi.k8s.io`, and when the pod starts, the driver fetches the entries from the store,
as the pod's own identity, and writes them into a memory-backed volume inside that pod only.

| | External Secrets Operator | Secrets Store CSI Driver |
|---|---|---|
| where the value lands | a Secret, then any pod that mounts it | a volume in each pod that asks |
| who logs in to the store | the operator, as a ServiceAccount you name | the driver, as the pod's own ServiceAccount |
| when it is read | on a schedule, whether a pod runs or not | when the pod starts, and optionally on rotation |
| environment variables | yes, through the Secret | only by also syncing a Secret, which gives up the point |
| works when the store is down | pods start with the last value | pods that start cannot mount it |

The last row is the trade. The operator's Secret is a copy, which is a risk and also a buffer: a
store that is down, or a Vault that restarted sealed, stops new values, not new pods. The driver has
no copy, so the store's availability becomes every pod's. **Most teams start with the operator** and
move a few workloads to the driver where a Secret in etcd is not acceptable. This course runs the
operator and does not install the driver.
