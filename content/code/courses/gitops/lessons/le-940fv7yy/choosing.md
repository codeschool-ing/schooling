---
title: Kustomize or Helm
version: 1
---

**The two tools answer different questions, and most real repositories use both.**

| | Kustomize | Helm |
|---|---|---|
| starts from | plain manifests, valid on their own | templates, valid only once rendered |
| an environment is | an overlay: what is different | a values file: the answers to the chart's questions |
| suits | your own applications, a handful of environments | software you install and did not write, many configurations |
| what a reviewer reads | the overlay, and `kubectl kustomize` output | the values, and `helm template` output |
| packaging | none: a directory | a versioned chart, published to a repository or a registry |
| the release | none: objects in the cluster | a Helm release with history, in the cluster |

**Use Kustomize for what you write**, because a base that is plain YAML is something everybody on
the team can read, and an overlay that lists differences is the cheapest possible description of an
environment. **Use Helm for what you install**, because the chart's author already answered the
hundreds of questions you would otherwise have to, and a values file is a much smaller thing to own
than their manifests. When a third-party chart needs one change it does not offer a value for,
Kustomize can patch Helm's output after rendering it, which both Flux's `postRenderers` and Argo CD's
Kustomize integration support.

## Rendering in the agent, or in Git

Both Flux and Argo CD render overlays and charts inside the cluster, at every reconciliation, and
Git holds only the sources. Some teams render in CI instead and commit the result, plain manifests,
to a separate directory or branch that the agent applies. The trade is the one lesson 2 named: the
rendered output is exactly what will be applied and a reviewer can read it, at the cost of a second
copy of everything that can disagree with its source. **Rendering in the agent is the default for a
good reason**; render in CI when a reviewer reading the final manifests is worth that second copy.
