---
title: Rolling back is a commit
version: 1
---

**Checks catch a manifest that is malformed. They do not catch one that is valid and wrong.** An
image tag that does not exist is a perfectly good string, and `kubeconform` passes it. This section
merges exactly that, watches what the cluster does, and undoes it the GitOps way.

## A valid, wrong change

Ana moves staging to `bulletin:1.1`, which nobody ever built. The check passes, Bruno approves, and
it merges:

```
ana@laptop:~/fleet$ git switch --quiet -c staging-1.1
ana@laptop:~/fleet$ git commit --quiet -am "staging: bulletin 1.1"
ana@laptop:~/fleet$ git push --quiet -u origin staging-1.1
remote: 
remote: Create a new pull request for 'staging-1.1':        
remote:   http://localhost:3000/ana/fleet/pulls/new/staging-1.1        
remote: 
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" -H "$JSON" -d '{"head": "staging-1.1", "base": "main", "title": "staging: bulletin 1.1", "body": "The new release, for QA."}' $API/pulls | jq .number
3
ana@laptop:~/fleet$ sh ~/setup/validate.sh $(git rev-parse HEAD)
Summary: 3 resources found in 1 file - Valid: 3, Invalid: 0, Errors: 0, Skipped: 0
validate: success
ana@laptop:~/fleet$ curl -s -H "$AS_BRUNO" -H "$JSON" -d '{"event": "APPROVED", "body": "Fine."}' $API/pulls/3/reviews | jq -r .state
APPROVED
ana@laptop:~/fleet$ curl -s -w "%{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '{"Do": "merge"}' $API/pulls/3/merge
200
```

The loop applied it, and the deployment started a rollout that cannot finish:

```
ana@laptop:~/fleet$ kubectl -n staging get pods
NAME                        READY   STATUS         RESTARTS   AGE
bulletin-54b57cfbcf-p667z   0/1     ErrImagePull   0          33s
bulletin-657dd4685b-4gfmw   1/1     Running        0          79s
bulletin-657dd4685b-xfh6g   1/1     Running        0          80s
bulletin-657dd4685b-z5hg9   1/1     Running        0          64s
ana@laptop:~/fleet$ kubectl -n staging get deployment bulletin
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
bulletin   3/3     1            3           94s
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.0
message: Staging is ready for review.
token: none
```

**Staging is still up.** A rolling update starts new pods before it removes old ones, and a new pod
that never becomes ready never replaces anything. The three pods from the last version keep
serving, and `curl` still gets an answer. Everything that went wrong is visible: one pod in
`ErrImagePull`, and a deployment with one up-to-date replica out of the three it asked for.

## The way back

The tempting fix is `kubectl rollout undo`. It works, for one pass of the loop, and then the loop
applies `main` again and the broken image is back. **The fix has to go where the truth is.**
`git revert` makes a new commit that undoes an old one, and it goes through the same flow as any
other change:

```
ana@laptop:~/fleet$ git switch --quiet main && git pull --quiet
ana@laptop:~/fleet$ git switch --quiet -c revert-1.1
ana@laptop:~/fleet$ git revert --no-edit -m 1 HEAD
[revert-1.1 ab2c952] Revert "Merge pull request 'staging: bulletin 1.1' (#3) from staging-1.1 into main"
 Date: Tue Oct 13 14:20:00 2026 -0300
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@laptop:~/fleet$ git push --quiet -u origin revert-1.1
remote: 
remote: Create a new pull request for 'revert-1.1':        
remote:   http://localhost:3000/ana/fleet/pulls/new/revert-1.1        
remote: 
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" -H "$JSON" -d '{"head": "revert-1.1", "base": "main", "title": "Revert staging to bulletin 1.0", "body": "1.1 was never built. Back to 1.0 until it is."}' $API/pulls | jq .number
4
ana@laptop:~/fleet$ sh ~/setup/validate.sh $(git rev-parse HEAD)
Summary: 3 resources found in 1 file - Valid: 3, Invalid: 0, Errors: 0, Skipped: 0
validate: success
ana@laptop:~/fleet$ curl -s -H "$AS_BRUNO" -H "$JSON" -d '{"event": "APPROVED", "body": "Yes, revert."}' $API/pulls/4/reviews | jq -r .state
APPROVED
ana@laptop:~/fleet$ curl -s -w "%{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '{"Do": "merge"}' $API/pulls/4/merge
200
```

The revert went through the check and the review like any change, because it is one, and the loop
put the cluster back:

```
ana@laptop:~/fleet$ git switch --quiet main && git pull --quiet
ana@laptop:~/fleet$ kubectl -n staging get pods
NAME                        READY   STATUS    RESTARTS   AGE
bulletin-657dd4685b-4gfmw   1/1     Running   0          101s
bulletin-657dd4685b-xfh6g   1/1     Running   0          102s
bulletin-657dd4685b-z5hg9   1/1     Running   0          86s
ana@laptop:~/fleet$ git log --oneline --first-parent -4
404ce6c Merge pull request 'Revert staging to bulletin 1.0' (#4) from revert-1.1 into main
0a11e7a Merge pull request 'staging: bulletin 1.1' (#3) from staging-1.1 into main
4bb78f9 Merge pull request 'staging: three replicas' (#2) from three-replicas into main
efa3978 Merge pull request 'staging: ready for review' (#1) from banner-v2 into main
```

The loop, all this time, applied each merge on the pass after it landed: the three replicas, the
broken image, and the revert.

```
01:51:12 at 4bb78f9
deployment.apps/bulletin configured
01:51:28 at 4bb78f9
01:51:43 at 0a11e7a
deployment.apps/bulletin configured
01:51:59 at 0a11e7a
01:52:15 at 0a11e7a
01:52:30 at 404ce6c
deployment.apps/bulletin configured
```

## Why not rewrite history

The other tempting fix is to move `main` back to before the bad merge and force-push. The rule
already refuses it, and for good reason: **history that can be rewritten is not a record.** After a
revert, `git log` tells the true story, that 1.1 was merged, applied, failed and was reverted, with
two names and two times on it. After a force-push it tells a story in which nothing happened, and
the pods that crashed in the meantime have no explanation anywhere.
