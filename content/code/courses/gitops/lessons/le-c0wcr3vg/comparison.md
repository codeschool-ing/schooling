---
title: Argo CD and Flux, side by side
version: 1
---

**Both tools implement the same four principles, and a team that picks either one carefully ends
up with GitOps.** They differ in how they are shaped, and the differences decide which one fits a
team, more than any feature list does. Everything in this table was seen in lessons 3 and 4:

| | Argo CD | Flux |
|---|---|---|
| the unit | an `Application`: one source, one destination | a chain: a source object, then a `Kustomization` or `HelmRelease` that applies it |
| interface | a web interface, an API server with its own users and roles, a CLI | the Kubernetes API, and a CLI that reads it |
| drift | watched: a manual change is reverted in seconds with `selfHeal` | reapplied on the interval: a manual change lasts until the next reconciliation |
| pruning | opt-in per Application, `prune: true` | `prune: true` on the Kustomization |
| a field to leave alone | `ignoreDifferences`, per field | leave it out of Git, or an annotation per object |
| Helm | renders the chart to manifests and applies them, no Helm release | installs a real Helm release with Helm's own library |
| encrypted secrets in Git | through a plugin or an operator | SOPS decryption built in, lesson 9 |
| new image tags | a separate project, Argo CD Image Updater | the image controllers, part of Flux |
| bootstrap | install, then an app of apps applied once | `flux bootstrap`, or the three steps of this lesson |
| what runs in the cluster | six deployments and a statefulset | four deployments, two more with the image controllers |

## How to choose

**Choose Argo CD when people need to see.** Its web interface draws every application as a tree of
objects with their health, and a team that includes people who do not live in a terminal gets a
shared picture of what is deployed. Its projects and roles let one Argo CD serve many teams with
different permissions, without giving any of them access to the cluster itself.

**Choose Flux when the cluster is the interface.** It has fewer parts, nothing to log in to, and
everything it does is a Kubernetes object that the cluster's own permissions already govern. It
treats SOPS, OCI artifacts, signature verification and image updates as part of itself rather than as
add-ons, and the next lessons use all four.

Many organisations run both, Argo CD where application teams want the interface and Flux for the
platform underneath. **What no organisation should do is run both on the same objects**, which is
why this lesson began by removing one.

## Which one the rest of this course uses

From lesson 5 on, `fleet` is applied by **Flux**, because lessons 7 to 9 use the parts it carries
built in: artifacts in a registry, verified signatures and encrypted secrets. Where Argo CD does the
same thing differently, the lesson says how, so that nothing here is knowledge of one tool only.
