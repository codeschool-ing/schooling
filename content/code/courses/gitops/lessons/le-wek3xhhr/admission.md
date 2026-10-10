---
title: Checking at the cluster's door
version: 1
---

**Flux verifying a chart protects what Flux pulls.** It does nothing for an image named in a
Deployment, which the kubelet pulls, or for a pod somebody creates with `kubectl run`. The place that
sees every pod before it exists is the API server's **admission**: a webhook the API server calls for
each request, which can refuse it.

Three projects provide signature checks there:

| | what it is | how a rule looks |
|---|---|---|
| **Kyverno** | a general policy engine whose rules are Kubernetes objects | a `ClusterPolicy` with `verifyImages`: which image names, which key or identity |
| **Sigstore policy-controller** | Sigstore's own admission controller, for cosign signatures only | a `ClusterImagePolicy`: which images, which authorities |
| **Ratify** | a verifier that Gatekeeper calls, for several signature formats | a Gatekeeper constraint and a Ratify verifier |

All three answer the same question at the same point: **does this image carry a signature from a
key or identity I trust?** A pod whose image does not is refused before the scheduler sees it, with
a message that names the rule.

A Kyverno rule for this course's images would read like this:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: bulletin-is-signed
spec:
  validationFailureAction: Enforce
  rules:
  - name: signed-by-the-release-key
    match:
      any:
      - resources:
          kinds: ["Pod"]
    verifyImages:
    - imageReferences: ["localhost:5001/bulletin*"]
      attestors:
      - entries:
        - keys:
            publicKeys: |-
              -----BEGIN PUBLIC KEY-----
              (the contents of cosign.pub)
              -----END PUBLIC KEY-----
```

**It was not applied for this course**: Kyverno's images are published on registries the recording
machine cannot reach. Two properties of such a policy are worth knowing before you meet one. It
needs to verify **digests**, so it rewrites a tag in a pod's spec to the digest it verified, and the
pod runs exactly what was checked. And it is a **door that can be locked from the inside**: a policy
that refuses every image, including the policy engine's own on its next restart, stops the cluster
from healing, which is why such policies exclude the system namespaces and are tried in `Audit` mode
first.
