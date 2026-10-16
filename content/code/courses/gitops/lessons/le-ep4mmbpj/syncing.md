---
title: Sync status and health are two questions
version: 1
---

**"Is the cluster what Git says?" and "Is what is running working?" are different questions, and
Argo CD answers them separately.** Sync status compares the live objects with the rendered
manifests. Health asks each object whether it is doing its job: a Deployment is healthy when its
replicas are available, a Service when it exists, a pod when it runs and passes its probes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 560 320\" xmlns=\"http://www.w3.org/2000/svg\" role=\"img\" aria-label=\"A grid with sync status across and health down. Synced and Healthy is the goal. OutOfSync and Healthy means a change not yet applied. Synced and Degraded means Git was applied and is wrong. OutOfSync and Degraded means both.\"><rect x=\"0\" y=\"0\" width=\"560\" height=\"320\" fill=\"var(--ink)\"/><text x=\"330\" y=\"28\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper-dim)\">sync status</text><text x=\"230\" y=\"52\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Synced</text><text x=\"430\" y=\"52\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">OutOfSync</text><text x=\"40\" y=\"130\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Healthy</text><text x=\"40\" y=\"240\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Degraded</text><rect x=\"140\" y=\"70\" width=\"180\" height=\"110\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\"/><text x=\"230.0\" y=\"129.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">the goal</text><rect x=\"340\" y=\"70\" width=\"180\" height=\"110\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"/><text x=\"430.0\" y=\"120.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">not applied yet,</text><text x=\"430.0\" y=\"138.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">or drift</text><rect x=\"140\" y=\"190\" width=\"180\" height=\"110\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"/><text x=\"230.0\" y=\"240.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">Git applied,</text><text x=\"230.0\" y=\"258.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">and Git is wrong</text><rect x=\"340\" y=\"190\" width=\"180\" height=\"110\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"/><text x=\"430.0\" y=\"240.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">both: read</text><text x=\"430.0\" y=\"258.55\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper)\">the sync first</text><text x=\"40\" y=\"300\" text-anchor=\"middle\" font-family=\"IBM Plex Sans\" font-size=\"13\" fill=\"var(--paper-dim)\">health</text></svg>", "caption": "Two independent questions. Argo CD can only fix the right-hand column by syncing; the bottom-left square is a bug in the repository, faithfully applied."}
```

Each of the four combinations means something:

| sync | health | what it usually means |
|---|---|---|
| Synced | Healthy | the goal: Git describes what runs, and it works |
| OutOfSync | Healthy | Git changed and nothing applied it yet, or somebody changed the cluster |
| Synced | Degraded | Git was applied faithfully, and what Git says does not work, like lesson 2's missing image |
| OutOfSync | Degraded | something is wrong on both counts; read the sync first |

The third row is the one people misread. **A Synced, Degraded application is not Argo CD failing.**
It did exactly its job, and the bug is in the repository.

## Syncing by hand

With no sync policy, Argo CD only reports. Applying is a command:

```
ana@laptop:~/setup$ argocd app sync bulletin-staging
TIMESTAMP                  GROUP        KIND   NAMESPACE                  NAME    STATUS    HEALTH        HOOK  MESSAGE
2026-10-10T02:19:36-03:00          Namespace                           staging  OutOfSync                       
2026-10-10T02:19:36-03:00            Service     staging              bulletin  OutOfSync  Healthy              
2026-10-10T02:19:36-03:00   apps  Deployment     staging              bulletin  OutOfSync  Healthy              
2026-10-10T02:19:36-03:00          Namespace                           staging    Synced                       
2026-10-10T02:19:36-03:00          Namespace     staging               staging   Running    Synced              namespace/staging configured
2026-10-10T02:19:36-03:00            Service     staging              bulletin  OutOfSync  Healthy              service/bulletin configured
2026-10-10T02:19:36-03:00   apps  Deployment     staging              bulletin  OutOfSync  Healthy              deployment.apps/bulletin configured
2026-10-10T02:19:36-03:00            Service     staging              bulletin    Synced  Healthy              service/bulletin configured
2026-10-10T02:19:36-03:00   apps  Deployment     staging              bulletin    Synced  Healthy              deployment.apps/bulletin configured

Name:               argocd/bulletin-staging
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          staging
URL:                http://localhost:38655/applications/bulletin-staging
Source:
- Repo:             http://gitea:3000/ana/fleet.git
  Target:           main
  Path:             staging
SyncWindow:         Sync Allowed
Sync Policy:        Manual
Sync Status:        Synced to main (2ce9f1e)
Health Status:      Healthy

Operation:          Sync
Sync Revision:      2ce9f1ef8198e2e2d50073b08e8ccd832d0cc499
Phase:              Succeeded
Start:              2026-10-10 02:19:36 -0300 -03
Finished:           2026-10-10 02:19:36 -0300 -03
Duration:           0s
Message:            successfully synced (all tasks run)

GROUP  KIND        NAMESPACE  NAME      STATUS   HEALTH   HOOK  MESSAGE
       Namespace   staging    staging   Running  Synced         namespace/staging configured
       Service     staging    bulletin  Synced   Healthy        service/bulletin configured
apps   Deployment  staging    bulletin  Synced   Healthy        deployment.apps/bulletin configured
       Namespace              staging   Synced                  
```

The table is the controller's account of the operation: each object, the `kubectl` result, and the
revision it applied, `2ce9f1e`. Afterwards the Application is `Synced` and `Healthy`, and the objects
carry the tracking annotation:

```
ana@laptop:~/setup$ argocd app list
NAME                     CLUSTER                         NAMESPACE  PROJECT  STATUS  HEALTH   SYNCPOLICY  CONDITIONS  REPO                             PATH     TARGET
argocd/bulletin-staging  https://kubernetes.default.svc  staging    default  Synced  Healthy  Manual      <none>      http://gitea:3000/ana/fleet.git  staging  main
ana@laptop:~/setup$ kubectl -n staging get deployment bulletin -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}'; echo
bulletin-staging:apps/Deployment:staging/bulletin
```

**The revision is recorded, not guessed.** Anybody with read access to the `argocd` namespace can
ask which commit staging is running, and the answer comes from the controller that applied it.
