---
title: History, and why rollback is still a commit
version: 1
---

**Argo CD keeps a short history of what each Application synced**, which is a convenient answer to
"what was running an hour ago":

```
ana@laptop:~/setup$ argocd app history bulletin-staging
SOURCE  http://gitea:3000/ana/fleet.git
ID      DATE                           REVISION
0       2026-10-10 02:19:36 -0300 -03  main (2ce9f1e)
1       2026-10-10 02:19:43 -0300 -03  main (1c85197)
2       2026-10-10 02:19:52 -0300 -03  main (9ce8b81)
3       2026-10-10 02:20:01 -0300 -03  main (370bc6e)
4       2026-10-10 02:20:24 -0300 -03  main (370bc6e)
```

Each line is one sync: when, and which commit. Argo CD can also roll an Application back to one of
those entries, re-applying an old revision without touching Git. Try it on staging:

```
ana@laptop:~/setup$ argocd app rollback bulletin-staging 1
{"level":"fatal","msg":"rpc error: code = FailedPrecondition desc = rollback cannot be initiated when auto-sync is enabled","time":"2026-10-10T02:20:31-03:00"}
```

**Refused, because automated sync is on**, and the refusal is the right behaviour. A rollback that
does not change Git is drift by definition: the next automated sync would apply `main` again and
undo it, exactly like `kubectl rollout undo` in lesson 2. With automation off, `argocd app rollback`
works and leaves the Application `OutOfSync` until somebody fixes Git, which is honest about the
situation and still leaves the fix to be made where the truth is.

So the rule from lesson 2 stands with a real agent too: **in an emergency, revert in Git**, through
the shortest flow your team allows. Argo CD's history is for reading, and it is kept only for the
last ten syncs by default (`revisionHistoryLimit`); Git's history is kept for ever.
