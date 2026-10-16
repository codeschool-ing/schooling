---
title: When the flow fails
version: 1
---

Each of these was produced on purpose against the Gitea of this lesson, and each one stops a change
for a reason worth reading.

## A token that is wrong

```
ana@laptop:~/fleet$ curl -s -w " %{http_code}\n" -H "Authorization: token 0123456789abcdef" $API
{"message":"invalid username, password or token","url":"http://localhost:3000/api/swagger"} 401
```

`401` and `invalid username, password or token`. The token in the header matched no token on the
server: a copy that lost a character, a file read from the wrong path, or a token that was deleted.
`wc -c ~/ana.token` should say 41, forty characters and a newline; make a new token if it does not.

## An approval that went stale

Bruno approves, and Ana pushes one more commit to the branch before merging:

```
ana@laptop:~/fleet$ git switch --quiet -c banner-v3
ana@laptop:~/fleet$ git commit --quiet -am "staging: in use by QA"
ana@laptop:~/fleet$ git push --quiet -u origin banner-v3
remote: 
remote: Create a new pull request for 'banner-v3':        
remote:   http://localhost:3000/ana/fleet/pulls/new/banner-v3        
remote: 
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" -H "$JSON" -d '{"head": "banner-v3", "base": "main", "title": "staging: in use by QA"}' $API/pulls | jq .number
5
ana@laptop:~/fleet$ sh ~/setup/validate.sh $(git rev-parse HEAD)
Summary: 3 resources found in 1 file - Valid: 3, Invalid: 0, Errors: 0, Skipped: 0
validate: success
ana@laptop:~/fleet$ curl -s -H "$AS_BRUNO" -H "$JSON" -d '{"event": "APPROVED", "body": "OK."}' $API/pulls/5/reviews | jq -r .state
APPROVED
ana@laptop:~/fleet$ git commit --quiet -am "staging: until Friday"
ana@laptop:~/fleet$ git push --quiet
remote: 
remote: Visit the existing pull request:        
remote:   http://localhost:3000/ana/fleet/pulls/5        
remote: 
ana@laptop:~/fleet$ sh ~/setup/validate.sh $(git rev-parse HEAD)
Summary: 3 resources found in 1 file - Valid: 3, Invalid: 0, Errors: 0, Skipped: 0
validate: success
ana@laptop:~/fleet$ curl -s -w " %{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '{"Do": "merge"}' $API/pulls/5/merge
{"message":"Does not have enough approvals","url":"http://localhost:3000/api/swagger"} 405
```

The rule dismisses an approval when new commits arrive, so the approval no longer counts and the
merge is refused. That is the rule working: **Bruno approved a version that is no longer the one
being merged.** He reviews the new commit and approves again.

## Git asks for a username

```
ana@laptop:~/fleet$ git ls-remote http://127.0.0.1:3000/ana/fleet.git
fatal: could not read Username for 'http://127.0.0.1:3000': terminal prompts disabled
```

Git found no stored credential for that address. In a terminal it stops and asks for a username;
this transcript was recorded with Git's prompts turned off, so it says why it could not ask
instead. Either `~/.git-credentials` was not written, or it was written for a different address:
`http://127.0.0.1:3000` and `http://localhost:3000` are two different servers as far as Git is
concerned. The remote and the credential line must name the same host.

## `jq: command not found`

Every command that pipes into `jq` prints nothing useful without it. `sudo apt-get install jq`
installs it; the commands work without the `| jq …` part as well, at the price of reading a page of
JSON.
