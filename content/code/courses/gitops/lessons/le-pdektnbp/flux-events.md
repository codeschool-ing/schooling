---
title: What Flux did, and telling somebody
version: 1
---

**Flux records what it did as Kubernetes events**, on the object that did it: a source that fetched
a revision, a Kustomization that applied one, a HelmRelease that upgraded. `flux events` prints them
with their full messages, which run wide; `kubectl` reads the same events with only the columns you
name, oldest first:

```
ana@laptop:~/fleet$ kubectl -n flux-system get events --field-selector involvedObject.name=staging --sort-by=.lastTimestamp -o custom-columns=LAST:.lastTimestamp,COUNT:.count,TYPE:.type,REASON:.reason | tail -n 5
2026-10-16T04:48:15Z   3       Warning   ReconciliationFailed
2026-10-16T04:48:18Z   10      Normal    ReconciliationSucceeded
2026-10-16T04:48:28Z   2       Warning   ReconciliationFailed
2026-10-16T04:52:45Z   15      Normal    Succeeded
2026-10-16T04:53:33Z   3       Normal    DependencyNotReady
```

Newest last, with the `count` column saying how often each repeated: the two refusals of lesson 11,
`ReconciliationFailed`, among the runs that succeeded, and `DependencyNotReady` at the end, which is
the `dependsOn` of lesson 9 making staging wait for `sealed-secrets`. Every line is about one
object, the Kustomization `staging`.

Events are kept for an hour by default and live inside the cluster, so they answer *what just
happened* and not *what happened last month*. To keep them, and to tell people, Flux's notification
controller sends them out: a **Provider** says where to, and an **Alert** says which events.

The most useful destination is the one that closes the loop back to Git. A Provider of type `gitea`
posts a **commit status** on the commit a Kustomization applied, the same kind of status
`validate.sh` posts. The commit page in Gitea then says *deployed, to staging, at this time* beside
*checked*. It needs a token that may write statuses, and the `ci` account from lesson 2 is the one
whose job that already is:

```
ana@laptop:~/fleet$ kubectl -n flux-system create secret generic gitea-status --from-literal=token="$(cat ~/ci.token)"
secret/gitea-status created
```

Then the two objects, in `clusters/lab/notifications.yaml`:

```yaml
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Provider
metadata:
  name: gitea
  namespace: flux-system
spec:
  type: gitea
  address: http://gitea:3000/ana/fleet
  secretRef:
    name: gitea-status
---
apiVersion: notification.toolkit.fluxcd.io/v1beta3
kind: Alert
metadata:
  name: fleet
  namespace: flux-system
spec:
  providerRef:
    name: gitea
  eventSeverity: info
  eventSources:
  - kind: Kustomization
    name: '*'
```

```
ana@laptop:~/fleet$ git switch --quiet -c notifications
ana@laptop:~/fleet$ git add clusters && git commit --quiet -m "flux: report what it applied as commit statuses"
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" $API/commits/$(git rev-parse HEAD)/statuses | jq -c '.[] | {context, status, description, by: .creator.login}'
{"context":"kustomization/production/a0ceb284","status":"success","description":"reconciliation succeeded","by":"ci"}
{"context":"kustomization/staging/a0ceb284","status":"success","description":"reconciliation succeeded","by":"ci"}
{"context":"kustomization/flux-system/a0ceb284","status":"success","description":"reconciliation succeeded","by":"ci"}
```

Three statuses on the commit that was merged, one per Kustomization that applied it, each posted
through the `ci` account: `flux-system`, `staging` and `production`, all `success`. The commit page
in Gitea now says where this commit went, and that it worked there.

A Provider of another type sends the same events to a chat, a pager or a generic webhook. An Alert
with `eventSeverity: error` sends only failures: **the ExternalSecret that stopped syncing in lesson
10, the chart Flux refused in lesson 8**, each one a message to somebody rather than a status nobody
reads.
