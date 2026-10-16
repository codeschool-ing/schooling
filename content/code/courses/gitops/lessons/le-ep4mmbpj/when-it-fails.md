---
title: When an Application fails
version: 1
---

Argo CD reports its failures as conditions on the Application, and `argocd app get` prints them
under the summary. Each of these was produced on purpose, with a test Application applied by hand
and deleted afterwards.

## A repository it cannot read

The Application names a repository that Argo CD has no credentials for, here one that does not
exist:

```
ana@laptop:~/setup$ argocd app get probe-repo | sed -n '/^Sync Status/p;/^CONDITION/,/^$/p'
Sync Status:        Unknown
CONDITION        MESSAGE  LAST TRANSITION
ComparisonError  Failed to load target state: failed to generate manifest for source 1 of 1: rpc error: code = Unknown desc = failed to list refs: authentication required: Unauthorized
                 2026-10-10 02:21:02 -0300 -03
```

`ComparisonError`, and Gitea's answer passed through. Argo CD could not render anything, so it
cannot say whether the cluster is in sync: the status is `Unknown`, not `OutOfSync`. Check the URL
with `argocd repo list`, and that the credentials there can read it.

## A path that does not exist

```
ana@laptop:~/setup$ argocd app get probe-path | sed -n '/^Sync Status/p;/^CONDITION/,/^$/p'
Sync Status:        Unknown
CONDITION        MESSAGE                                                                                                                                       LAST TRANSITION
ComparisonError  Failed to load target state: failed to generate manifest for source 1 of 1: rpc error: code = Unknown desc = stagng: app path does not exist  2026-10-10 02:21:11 -0300 -03
```

A typo in `path`, and the repo server says exactly that. Nothing is deleted when the path vanishes,
and that is deliberate: **an empty render is never taken as "delete everything"**.

## Two Applications for one object

A second Application pointing at the same path, here `probe-copy`, finds objects that already
belong to `bulletin-staging`:

```
ana@laptop:~/setup$ argocd app get probe-copy | sed -n '/^Sync Status/p;/^CONDITION/,/^$/p'
Sync Status:        OutOfSync from main (463b299)
CONDITION              MESSAGE                                                                             LAST TRANSITION
SharedResourceWarning  Deployment/bulletin is part of applications argocd/probe-copy and bulletin-staging  2026-10-10 02:21:20 -0300 -03
SharedResourceWarning  Namespace/staging is part of applications argocd/probe-copy and bulletin-staging    2026-10-10 02:21:20 -0300 -03
SharedResourceWarning  Service/bulletin is part of applications argocd/probe-copy and bulletin-staging     2026-10-10 02:21:20 -0300 -03
```

`SharedResourceWarning` names both owners. It is lesson 2's "two truths" caught by the tool rather
than by a cluster flipping between them: two Applications syncing the same object would overwrite
each other's work and each other's tracking annotation on every pass. **Delete one of them**, or
point them at paths that do not overlap; nothing else makes the warning go away.
