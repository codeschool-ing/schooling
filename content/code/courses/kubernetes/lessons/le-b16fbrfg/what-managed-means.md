---
title: What a provider takes, and what it leaves you
version: 1
---

**"Managed" is easy to read as "somebody else's problem", and for a Kubernetes cluster that is half
true.** The provider takes the control plane: the API server, etcd, the scheduler and the controller
manager, which lesson 4 opens up on the laptop's cluster. It keeps them running on machines you
never see, backs up etcd, and upgrades them when you ask, or on its own schedule if you let it. What
it does not take is everything you put in the cluster.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A managed cluster drawn as two areas. The provider's area holds the control plane: API server, etcd, scheduler and controller manager, backed up and upgraded by the provider. Your area holds the worker nodes, the pods and their manifests, RBAC and network policies. A dashed outline around the nodes says they move to the provider's side with Autopilot, Auto Mode or Fargate.\"><defs><marker id=\"mg-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"260\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"150\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the provider's</text><rect x=\"40\" y=\"60\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">control plane</text><text x=\"150.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">API server · etcd</text><rect x=\"40\" y=\"120\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">scheduler</text><text x=\"150.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">controller-manager</text><rect x=\"300\" y=\"20\" width=\"400\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">yours</text><rect x=\"320\" y=\"60\" width=\"170\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"405.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">worker nodes</text><text x=\"405.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kubelet · containerd</text><text x=\"405\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">moves to the provider with</text><text x=\"405\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Autopilot, Auto Mode, Fargate</text><rect x=\"510\" y=\"60\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">your pods and manifests</text><rect x=\"510\" y=\"110\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">who may do what (RBAC)</text><rect x=\"510\" y=\"160\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">which pod may talk to which</text><path d=\"M320 85 L262 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mg-ah-paper-dim)\" marker-start=\"url(#mg-ah-paper-dim)\"></path></svg>", "caption": "The control plane is always the provider's on a managed cluster. The nodes can be either side; the workloads and the rules about them are always yours."}
```

## The line, drawn

| | managed cluster, you run the nodes | managed cluster, provider runs the nodes too |
|---|---|---|
| API server, etcd, scheduler, upgrades of them | provider | provider |
| the worker machines, their operating system, their upgrades | you | provider |
| how many nodes, of which size | you, or an autoscaler you configure | provider, from what your pods ask for |
| your workloads, their images, their manifests | you | you |
| who may do what in the cluster (lesson 23) | you | you |
| which pod may talk to which (lesson 24) | you | you |
| the bill for all of it | you | you |

The middle column is the classic arrangement: the provider's control plane, and node groups of
virtual machines in your account that you size, patch and upgrade. The right-hand column is newer
and goes by a different name at each provider — **GKE Autopilot**, **EKS Auto Mode**, or pods on
**Fargate** — and in it you describe pods and the provider decides what machines run them. You pay
for what the pods request rather than for whole machines, and you give up choosing the machines.

## What does not move, whichever column

Two rows stay with you in both columns, and they are the two that cause most incidents. **Your
workloads are yours**: a broken image, a missing probe, a limit set too low fail on a managed
cluster exactly as they fail on the laptop. **And so is access**: the provider authenticates people
with its own identity system, but which of them may delete a deployment is written in RBAC, by you.

A managed control plane also removes a few things you might want. You cannot log in to it, you
cannot read its etcd directly as lesson 4 does, and you cannot install a component of your own
beside the API server. Lesson 45's extension points work on a managed cluster because they were
designed to be reached through the API, not through the machine.
