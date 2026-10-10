---
title: Nobody pushes to main
version: 1
---

**Whoever can write to `main` can change production**, because the agent applies whatever `main`
says. Guarding the branch is guarding the cluster, and the guard has two parts: a second person,
and a rule that nothing reaches `main` without that person.

## A second person

A review needs a reviewer. In your lab you play both people, so make the second account and a token
for it:

```
ana@laptop:~/fleet$ docker exec gitea gitea admin user create --username bruno --password 'change-me-too' --email bruno@example.org --must-change-password=false
New user 'bruno' has been successfully created!
ana@laptop:~/fleet$ docker exec gitea gitea admin user generate-access-token --username bruno --token-name terminal --scopes write:repository --raw > ~/bruno.token
ana@laptop:~/fleet$ chmod 600 ~/bruno.token
ana@laptop:~/fleet$ curl -s -o /dev/null -w "%{http_code}\n" -X PUT -H "$AS_ANA" -H "$JSON" -d '{"permission": "write"}' $API/collaborators/bruno
204
```

Bruno is now a **collaborator** with `write` permission: he can push branches and approve pull
requests on `fleet`. One more variable for his token:

```sh
AS_BRUNO="Authorization: token $(cat ~/bruno.token)"
```

## The rule

A branch protection rule on `main` says three things here. **No direct pushes**, by anybody,
administrators included. **One approval** before a pull request can merge. And **an approval is
dismissed when new commits arrive**, so a reviewer approves exactly what is merged, not an earlier
version of it.

```
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" -H "$JSON" -d '{"rule_name": "main", "enable_push": false, "required_approvals": 1, "dismiss_stale_approvals": true}' $API/branch_protections | jq '{rule_name, enable_push, required_approvals, dismiss_stale_approvals}'
{
  "rule_name": "main",
  "enable_push": false,
  "required_approvals": 1,
  "dismiss_stale_approvals": true
}
```

Now try the old way. Change the message in `staging/bulletin.yaml` to `Staging is ready for
review.` and push it straight to `main`:

```
ana@laptop:~/fleet$ git commit --quiet -am "staging: ready for review"
ana@laptop:~/fleet$ git push
remote: 
remote: error:        
remote: error: Not allowed to push to protected branch main        
remote: error:        
To http://localhost:3000/ana/fleet.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to 'http://localhost:3000/ana/fleet.git'
```

`Not allowed to push to protected branch main`. The commit exists on your machine and nowhere else.
It is not lost: put it on a branch of its own and move `main` back to where the server has it,

```
ana@laptop:~/fleet$ git switch -c banner-v2
Switched to a new branch 'banner-v2'
ana@laptop:~/fleet$ git switch main
Switched to branch 'main'
Your branch is ahead of 'origin/main' by 1 commit.
  (use "git push" to publish your local commits)
ana@laptop:~/fleet$ git reset --hard origin/main
HEAD is now at f990998 Revert "staging: no service"
```

and `main` matches the server again, while the change waits on `banner-v2` for the pull request of
the next section.
