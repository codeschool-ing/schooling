---
title: Reviewing a change to production
version: 1
---

**A reviewer of application code asks "is this correct?". A reviewer of desired state asks a
second question: "what will this do to the cluster?"** The diff answers the first. The second needs
the cluster.

## Two diffs

Before approving, Bruno reads the change as Git sees it, and then as the cluster would:

```
ana@laptop:~/fleet$ git fetch --quiet
ana@laptop:~/fleet$ git diff --stat main origin/banner-v2
 staging/bulletin.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@laptop:~/fleet$ git diff main origin/banner-v2 | grep '^[-+] '
-          value: Staging has the new banner.
+          value: Staging is ready for review.
ana@laptop:~/fleet$ git switch --quiet --detach origin/banner-v2
ana@laptop:~/fleet$ kubectl diff -f staging/ | grep '^[-+] '
-  generation: 1
+  generation: 2
-          value: Staging has the new banner.
+          value: Staging is ready for review.
ana@laptop:~/fleet$ git switch --quiet main
```

The first diff is the commit: one line. The second is `kubectl diff`, which sends the manifests to
the API server as a dry run and prints what would change **in the live object**: the same line,
plus `generation` going up, which is Kubernetes saying it will start a rollout. On a one-line change
the two agree. They stop agreeing when the live object has drifted, or when a field the commit did
not touch has a default the cluster fills in. **`kubectl diff` needs read access to the cluster**,
which is fine for Bruno at his desk and not something to hand to a CI system; the next section
checks what can be checked without it.

## Approving and merging

```
ana@laptop:~/fleet$ curl -s -H "$AS_BRUNO" -H "$JSON" -d '{"event": "APPROVED", "body": "Checked against the live object: one value, one rollout."}' $API/pulls/1/reviews | jq '{state, user: .user.login, body}'
{
  "state": "APPROVED",
  "user": "bruno",
  "body": "Checked against the live object: one value, one rollout."
}
ana@laptop:~/fleet$ curl -s -w "%{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '{"Do": "merge"}' $API/pulls/1/merge
200
ana@laptop:~/fleet$ git pull --quiet
ana@laptop:~/fleet$ git log --oneline -3
e1e3fc8 Merge pull request 'staging: ready for review' (#1) from banner-v2 into main
19332a9 staging: ready for review
7cb8caf Revert "staging: no service"
```

The review is recorded against the pull request with Bruno's name and his comment, and the merge
succeeds. `main` on the server now ends in a merge commit that names the pull request.

## And the cluster follows

The loop from lesson 1 reads only the repository, so point it at the server. Its old clone came
from `~/fleet.git`; delete it, and start the loop again in the second terminal:

```sh
rm -rf ~/.reconcile
sh ~/setup/reconcile.sh http://localhost:3000/ana/fleet.git staging
```

It clones with the credentials Git already has for `localhost:3000`, which are yours; lesson 3's
agent gets a read-only token of its own instead. A few seconds later, in the second terminal:

```
ana@laptop:~$ sh ~/setup/reconcile.sh http://localhost:3000/ana/fleet.git staging
02:01:35 at e1e3fc8
deployment.apps/bulletin configured
```

and in the first:

```
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.0
message: Staging is ready for review.
token: none
```

Nobody ran `kubectl apply`. The change went from Ana's editor to a branch, a pull request, Bruno's
approval, a merge, and from `main` to the cluster, and every step left a record with a name on it.
