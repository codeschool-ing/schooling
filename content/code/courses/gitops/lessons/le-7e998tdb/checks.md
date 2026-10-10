---
title: Checks a machine makes before a person looks
version: 1
---

**A reviewer's attention is the scarcest thing in the flow, so a machine should spend it first.** A
manifest with a typo in a field name, a string where Kubernetes wants a number, or an indentation
that moved a key into the wrong object can all be found without a person and without the cluster.
This section adds that check, makes it report to Gitea, and makes the protection rule wait for it.

## A validator

`kubeconform` checks manifests against the JSON schemas of a Kubernetes version, offline except for
fetching those schemas the first time. It is one file, installed like `kind` in lesson 1:

```
ana@laptop:~/setup$ ARCH=$(dpkg --print-architecture)
ana@laptop:~/setup$ curl -fsSLO https://github.com/yannh/kubeconform/releases/download/v0.8.0/kubeconform-linux-$ARCH.tar.gz
ana@laptop:~/setup$ curl -fsSL https://github.com/yannh/kubeconform/releases/download/v0.8.0/CHECKSUMS | grep " kubeconform-linux-$ARCH.tar.gz$" | sha256sum --check
kubeconform-linux-amd64.tar.gz: OK
ana@laptop:~/setup$ tar -xzf kubeconform-linux-$ARCH.tar.gz kubeconform && sudo install -m 0755 kubeconform /usr/local/bin/ && rm kubeconform kubeconform-linux-$ARCH.tar.gz
ana@laptop:~/setup$ kubeconform -v
v0.8.0
```

## A CI of one script

A real CI system runs on every push and reports back. Here a script does the same job when you run
it, which is enough to see every part of the arrangement. It reports as its own user, `ci`, so the
checks are never confused with a person's word. Make the user and its token as you made Bruno's:

```
ana@laptop:~/fleet$ docker exec gitea gitea admin user create --username ci --password 'change-me-also' --email ci@example.org --must-change-password=false
New user 'ci' has been successfully created!
ana@laptop:~/fleet$ docker exec gitea gitea admin user generate-access-token --username ci --token-name checks --scopes write:repository --raw > ~/ci.token
ana@laptop:~/fleet$ chmod 600 ~/ci.token
ana@laptop:~/fleet$ curl -s -o /dev/null -w "%{http_code}\n" -X PUT -H "$AS_ANA" -H "$JSON" -d '{"permission": "write"}' $API/collaborators/ci
204
```

And save this as `~/setup/validate.sh`:

```sh
#!/bin/sh
# The course's CI: check one commit of fleet and report the result to Gitea.
# Usage: sh validate.sh COMMIT
sha=$1 api=http://localhost:3000/api/v1/repos/ana/fleet
work=$(mktemp -d)
git clone --quiet http://localhost:3000/ana/fleet.git "$work"
git -C "$work" checkout --quiet "$sha"
if kubeconform -strict -summary -kubernetes-version 1.37.0 "$work/staging"; then
  state=success text="kubeconform passed"
else
  state=failure text="kubeconform found invalid manifests"
fi
curl -s -o /dev/null -H "Authorization: token $(cat ~/ci.token)" \
  -H 'Content-Type: application/json' \
  -d "{\"state\": \"$state\", \"context\": \"validate\", \"description\": \"$text\"}" \
  "$api/statuses/$sha"
echo "validate: $state"
rm -rf "$work"
```

It clones the repository, checks out the exact commit it was given, validates `staging/` with
`-strict`, which also refuses fields the schema does not know, and posts a **commit status** called
`validate` to that commit. The rule can then require that status:

```
ana@laptop:~/fleet$ curl -s -X PATCH -H "$AS_ANA" -H "$JSON" -d '{"enable_status_check": true, "status_check_contexts": ["validate"]}' $API/branch_protections/main | jq '{rule_name, required_approvals, enable_status_check, status_check_contexts}'
{
  "rule_name": "main",
  "required_approvals": 1,
  "enable_status_check": true,
  "status_check_contexts": [
    "validate"
  ]
}
```

## A change that fails

Ana asks for three replicas, and types the number as a word:

```
ana@laptop:~/fleet$ git switch --quiet -c three-replicas
ana@laptop:~/fleet$ git diff | grep '^[-+] '
-  replicas: 2
+  replicas: three
ana@laptop:~/fleet$ git commit --quiet -am "staging: three replicas"
ana@laptop:~/fleet$ git push --quiet -u origin three-replicas
remote: 
remote: Create a new pull request for 'three-replicas':        
remote:   http://localhost:3000/ana/fleet/pulls/new/three-replicas        
remote: 
ana@laptop:~/fleet$ curl -s -H "$AS_ANA" -H "$JSON" -d '{"head": "three-replicas", "base": "main", "title": "staging: three replicas", "body": "Load testing starts on Monday."}' $API/pulls | jq .number
2
ana@laptop:~/fleet$ sh ~/setup/validate.sh $(git rev-parse HEAD)
/tmp/tmp.EcfvHQ4Lh5/staging/bulletin.yaml - Deployment bulletin is invalid: problem validating schema. Check JSON formatting: jsonschema validation failed with 'https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.37.0-standalone-strict/deployment-apps-v1.json#' - at '/spec/replicas': got string, want null or integer
Summary: 3 resources found in 1 file - Valid: 2, Invalid: 1, Errors: 0, Skipped: 0
validate: failure
ana@laptop:~/fleet$ curl -s -w " %{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '{"Do": "merge"}' $API/pulls/2/merge
{"message":"Not all required status checks successful","url":"http://localhost:3000/api/swagger"} 405
```

The protection rule now holds the merge for two reasons, and the message names the first one it
found. **Bruno never had to read this version**: the machine said what was wrong, with the field and
the type, before anybody spent attention on it. Ana fixes it on the same branch:

```
ana@laptop:~/fleet$ git commit --quiet -am "staging: replicas is a number"
ana@laptop:~/fleet$ git push --quiet
remote: 
remote: Visit the existing pull request:        
remote:   http://localhost:3000/ana/fleet/pulls/2        
remote: 
ana@laptop:~/fleet$ sh ~/setup/validate.sh $(git rev-parse HEAD)
Summary: 3 resources found in 1 file - Valid: 3, Invalid: 0, Errors: 0, Skipped: 0
validate: success
ana@laptop:~/fleet$ curl -s -H "$AS_BRUNO" -H "$JSON" -d '{"event": "APPROVED", "body": "Three it is."}' $API/pulls/2/reviews | jq -r .state
APPROVED
ana@laptop:~/fleet$ curl -s -w "%{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '{"Do": "merge"}' $API/pulls/2/merge
200
ana@laptop:~/fleet$ git switch --quiet main && git pull --quiet
ana@laptop:~/fleet$ kubectl -n staging get deployment bulletin
NAME       READY   UP-TO-DATE   AVAILABLE   AGE
bulletin   3/3     3            3           47s
```

The status went green on the new commit, Bruno approved what will actually be merged, and the merge
went through. Within one pass the loop applies it, and staging runs three replicas.
