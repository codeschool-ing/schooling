---
title: What Argo CD is made of
version: 1
---

**Argo CD is lesson 1's loop, split into the parts that each need to be good at one thing.** The
shell script fetched, rendered, compared and applied in one process and kept nothing. Argo CD gives
each of those jobs to a component of its own and keeps its state as Kubernetes objects.

@@figure argo

- **The repo server** clones repositories and turns a path into plain manifests. For a directory of
  YAML that is reading files; for Kustomize or Helm, which lesson 6 covers, it runs the tool. It holds
  no credentials to the cluster at all, which matters, because it is the component that runs
  whatever a repository asks it to render.
- **The application controller** is the loop. For every Application it asks the repo server for the
  desired manifests, reads the live objects from the cluster, compares the two, and records the
  result. When told to, it applies the difference. It is the one component with write access to the
  cluster.
- **The API server** answers the web interface and the `argocd` command. It does not apply
  anything; it asks the controller to.
- **Redis** caches what the repo server rendered and what the controller saw, so that a comparison
  every few minutes does not clone and render everything again.
- **Dex**, the ApplicationSet controller and the notifications controller are optional parts: single
  sign-on, generating many Applications from one template, and sending messages when something
  happens. Lesson 5 uses an ApplicationSet; lesson 12 the notifications.

## The Application, the unit of everything

Argo CD adds a resource type to the cluster, `Application`, and **one Application is one arrow from
a place in Git to a place in the cluster**: this repository, at this revision, at this path, goes
to this namespace of this cluster. Everything Argo CD reports is reported per Application: whether
it is in sync, whether it is healthy, which commit it is at, what it did and when.

Because an Application is itself a Kubernetes object, it can be described in YAML and kept in Git
like anything else. The end of this lesson does exactly that, and Argo CD ends up managing its own
list of applications from the repository.
