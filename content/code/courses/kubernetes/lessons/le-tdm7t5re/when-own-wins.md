---
title: When running your own still wins
version: 1
---

The arithmetic of the previous section favours a managed control plane for most teams in a cloud.
**It stops applying where there is no provider to manage it**, or where the provider's terms are the
problem:

| situation | why your own |
|---|---|
| your own hardware, in your own data centre | there is no managed service on machines you own; somebody runs kubeadm or a distribution |
| data that may not leave a country, or a provider | the law decides the place, and the place may have no managed Kubernetes |
| many small clusters at the edge, in shops or factories | a fee per cluster multiplies, and lightweight distributions such as k3s are built for this |
| a control plane configured beyond what the provider allows | admission plugins, API server flags or an etcd layout the managed service does not offer |
| a platform team that already runs this as its job | the hours are already being spent; the question is only where |

**The middle ground is common**: managed clusters in the cloud and self-run clusters on premises,
deployed and governed the same way, through the GitOps of lesson 39 and the multiple contexts of
lesson 48. Distributions such as OpenShift and Rancher sell exactly that sameness.

And there is the case of this course itself. Running kind on a laptop is running your own cluster,
and everything learnt by doing it, the static pods, the certificates, etcd, is what makes a managed
service's behaviour understandable when it goes wrong. **Knowing how to run one is the best reason to
let somebody else run it**, because you can then tell what you are paying for.
