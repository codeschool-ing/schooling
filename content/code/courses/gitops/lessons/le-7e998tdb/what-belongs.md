---
title: What belongs in the repository
version: 1
---

**"The repository is the source of truth" is a rule with edges, and most of the trouble in a GitOps
setup comes from not knowing where they are.** Something that is in Git but should not be, or
that changes in the cluster but is also in Git, shows up as a fight between the agent and whatever
else writes it.

## What goes in

- **The manifests**: every object the cluster should have, with every field you mean to decide.
- **The configuration values** that differ between environments: replica counts, messages, feature
  switches, resource requests.
- **The image references**, by tag at least and by digest at best; lesson 7 explains the
  difference.
- **The agent's own configuration** once there is one: lesson 3 puts Argo CD's description of what
  to deploy in this repository too.

## What stays out

**Secrets in clear text.** A Kubernetes Secret is base64, which is an encoding anybody reverses with
one command, and a repository is copied to every laptop that clones it and kept for ever in its
history. Lessons 9 to 11 are about putting a *reference* to a secret, or an encrypted copy, in Git
instead.

**Fields that something else owns.** If a HorizontalPodAutoscaler decides how many replicas a
deployment has, and the manifest in Git also says `replicas: 2`, the two will fight: the autoscaler
raises it, the agent puts it back, for ever. The rule is **one owner per field**. Leave `replicas`
out of the manifest when an autoscaler owns it, and both lesson 3's Argo CD and lesson 4's Flux
also have a way to be told explicitly which fields to ignore.

**State the application produces.** A database's data, a cache, a log. Git describes what should
run; what the running thing writes is somebody else's problem, with backups rather than commits.

**Generated output, usually.** If a tool renders the manifests from templates, the templates and
their values go in Git, and the agent renders them. Lesson 6 discusses the exception, where teams
commit the rendered result on purpose so that a reviewer reads exactly what will be applied.

## One repository, one truth

A rule that sounds obvious and is broken constantly: **every object has exactly one place in Git
that describes it.** Two directories that both contain the staging Deployment, or two agents that
both apply it, is not redundancy. It is two truths that disagree as soon as somebody edits one of
them, and the cluster flips between them on every pass. Lesson 5 is about laying out a repository so
that the one place is easy to find.
