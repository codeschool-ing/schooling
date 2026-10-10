#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of gitops, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh       # needs the network, for kubeconform's download
#                               # and the schemas it fetches
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON: Gitea from the `docker run`
# in a-git-server, the accounts, tokens and repository from the commands shown,
# the shell variables and the credential file from the fences shown, and
# validate.sh, which `shown` copies out of checks.md. What is STAGED:
#   - the state at the end of lesson 1 (`lab.sh up` and `lab.sh stage1`): the
#     cluster, the registry with bulletin 1.0, ~/fleet with lesson 1's four
#     commits at their dates, and staging applied;
#   - the edits made in an editor are made with sed;
#   - Ana and Bruno are two people at two desks in the lesson and one terminal
#     here; Bruno's commands use his token, as the lesson's do;
#   - reconcile.sh runs in the background from "loop" on, and its blocks print
#     its output under the command that started it;
#   - every commit Ana makes carries a fixed date. The merge commits are Gitea's
#     and carry the time they were made, so their hashes differ on every run.
#
# Recorded on Ubuntu 24.04 with Docker 29.8.2 and Gitea 28.1.0,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../capture.sh"
docker rm -f gitea >/dev/null 2>&1
lab up
lab stage1
rm -f /home/ana/ana.token /home/ana/bruno.token /home/ana/ci.token /home/ana/.git-credentials
git config --global --unset credential.helper
cd /home/ana

# a-git-server: the docker run the lesson shows, then wait for it to answer
docker run -d --restart=always --name gitea --network kind -p 127.0.0.1:3000:3000 \
  -e GITEA__security__INSTALL_LOCK=true gitea/gitea:28.1.0-rootless >/dev/null
until curl -fs localhost:3000/api/v1/version >/dev/null; do sleep 1; done

block account
run "docker exec gitea gitea admin user create --admin --username ana --password 'change-me-now' --email ana@example.org --must-change-password=false"
run 'docker exec gitea gitea admin user generate-access-token --username ana --token-name terminal --scopes write:repository,write:user --raw > ~/ana.token'
run 'chmod 600 ~/ana.token'
run 'wc -c ~/ana.token'

block repo
API=http://localhost:3000/api/v1/repos/ana/fleet
AS_ANA="Authorization: token $(cat ~/ana.token)"
JSON='Content-Type: application/json'
run 'curl -s -H "$AS_ANA" -H "$JSON" -d '"'"'{"name": "fleet", "private": true}'"'"' http://localhost:3000/api/v1/user/repos | jq '"'"'{full_name, private, clone_url}'"'"''
git config --global credential.helper store
printf 'http://ana:%s@localhost:3000\n' "$(cat ~/ana.token)" > ~/.git-credentials
chmod 600 ~/.git-credentials

block push
cd /home/ana/fleet
run 'git remote set-url origin http://localhost:3000/ana/fleet.git'
run 'git push --quiet -u origin main'
run 'git ls-remote origin'
run 'git log --oneline -1'

block inside
run 'kubectl run probe --restart=Never --image=busybox:1.37 -- wget -qO- http://gitea:3000/api/v1/version'
quiet "kubectl wait --for=jsonpath='{.status.phase}'=Succeeded pod/probe --timeout=120s"
run 'kubectl logs probe; echo'
run 'kubectl delete pod probe'

block bruno
run "docker exec gitea gitea admin user create --username bruno --password 'change-me-too' --email bruno@example.org --must-change-password=false"
run 'docker exec gitea gitea admin user generate-access-token --username bruno --token-name terminal --scopes write:repository --raw > ~/bruno.token'
run 'chmod 600 ~/bruno.token'
run 'curl -s -o /dev/null -w "%{http_code}\n" -X PUT -H "$AS_ANA" -H "$JSON" -d '"'"'{"permission": "write"}'"'"' $API/collaborators/bruno'
AS_BRUNO="Authorization: token $(cat ~/bruno.token)"

block protect
run 'curl -s -H "$AS_ANA" -H "$JSON" -d '"'"'{"rule_name": "main", "enable_push": false, "required_approvals": 1, "dismiss_stale_approvals": true}'"'"' $API/branch_protections | jq '"'"'{rule_name, enable_push, required_approvals, dismiss_stale_approvals}'"'"''

block rejected
sed -i 's/value: Staging has the new banner./value: Staging is ready for review./' staging/bulletin.yaml
at 2026-10-13T10:00:00-03:00 run 'git commit --quiet -am "staging: ready for review"'
run 'git push'

block rescue
run 'git switch -c banner-v2'
run 'git switch main'
run 'git reset --hard origin/main'

block open
run 'git push --quiet -u origin banner-v2'
run 'curl -s -H "$AS_ANA" -H "$JSON" -d '"'"'{"head": "banner-v2", "base": "main", "title": "staging: ready for review", "body": "QA starts on staging on Monday, and the banner tells them it is ready."}'"'"' $API/pulls | jq '"'"'{number, title, state, mergeable}'"'"''

block refused
run 'curl -s -w " %{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '"'"'{"Do": "merge"}'"'"' $API/pulls/1/merge'

block self-approve
run 'curl -s -w " %{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '"'"'{"event": "APPROVED", "body": "Looks fine to me."}'"'"' $API/pulls/1/reviews'

block review
run 'git fetch --quiet'
run 'git diff --stat main origin/banner-v2'
run "git diff main origin/banner-v2 | grep '^[-+] '"
run 'git switch --quiet --detach origin/banner-v2'
run "kubectl diff -f staging/ | grep '^[-+] '"
run 'git switch --quiet main'

block approve
run 'curl -s -H "$AS_BRUNO" -H "$JSON" -d '"'"'{"event": "APPROVED", "body": "Checked against the live object: one value, one rollout."}'"'"' $API/pulls/1/reviews | jq '"'"'{state, user: .user.login, body}'"'"''
run 'curl -s -w "%{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '"'"'{"Do": "merge"}'"'"' $API/pulls/1/merge'
run 'git pull --quiet'
run 'git log --oneline -3'

block loop
LOG=/tmp/gitops-l2-loop.log
rm -rf /home/ana/.reconcile
setsid sh /home/ana/setup/reconcile.sh http://localhost:3000/ana/fleet.git staging >$LOG 2>&1 </dev/null &
LOOP=$!
sleep 8
quiet 'kubectl -n staging rollout status deployment bulletin --timeout=120s'
printf 'ana@laptop:~$ sh ~/setup/reconcile.sh http://localhost:3000/ana/fleet.git staging\n'
cat $LOG; seen=$(wc -l <$LOG)

block after
run 'curl -s localhost:8080'

block install-kubeconform
cd /home/ana/setup
run 'ARCH=$(dpkg --print-architecture)'
run 'curl -fsSLO https://github.com/yannh/kubeconform/releases/download/v0.8.0/kubeconform-linux-$ARCH.tar.gz'
run 'curl -fsSL https://github.com/yannh/kubeconform/releases/download/v0.8.0/CHECKSUMS | grep " kubeconform-linux-$ARCH.tar.gz$" | sha256sum --check'
run 'tar -xzf kubeconform-linux-$ARCH.tar.gz kubeconform && sudo install -m 0755 kubeconform /usr/local/bin/ && rm kubeconform kubeconform-linux-$ARCH.tar.gz'
run 'kubeconform -v'
cd /home/ana/fleet

block ci-user
run "docker exec gitea gitea admin user create --username ci --password 'change-me-also' --email ci@example.org --must-change-password=false"
run 'docker exec gitea gitea admin user generate-access-token --username ci --token-name checks --scopes write:repository --raw > ~/ci.token'
run 'chmod 600 ~/ci.token'
run 'curl -s -o /dev/null -w "%{http_code}\n" -X PUT -H "$AS_ANA" -H "$JSON" -d '"'"'{"permission": "write"}'"'"' $API/collaborators/ci'
shown "$HERE/checks.md" '~/setup/validate.sh' /home/ana/setup/validate.sh

block require
run 'curl -s -X PATCH -H "$AS_ANA" -H "$JSON" -d '"'"'{"enable_status_check": true, "status_check_contexts": ["validate"]}'"'"' $API/branch_protections/main | jq '"'"'{rule_name, required_approvals, enable_status_check, status_check_contexts}'"'"''

block bad
run 'git switch --quiet -c three-replicas'
sed -i 's/  replicas: 2/  replicas: three/' staging/bulletin.yaml
run "git diff | grep '^[-+] '"
at 2026-10-13T11:00:00-03:00 run 'git commit --quiet -am "staging: three replicas"'
run 'git push --quiet -u origin three-replicas'
run 'curl -s -H "$AS_ANA" -H "$JSON" -d '"'"'{"head": "three-replicas", "base": "main", "title": "staging: three replicas", "body": "Load testing starts on Monday."}'"'"' $API/pulls | jq .number'
run 'sh ~/setup/validate.sh $(git rev-parse HEAD)'
run 'curl -s -w " %{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '"'"'{"Do": "merge"}'"'"' $API/pulls/2/merge'

block fixed
sed -i 's/  replicas: three/  replicas: 3/' staging/bulletin.yaml
at 2026-10-13T11:05:00-03:00 run 'git commit --quiet -am "staging: replicas is a number"'
run 'git push --quiet'
run 'sh ~/setup/validate.sh $(git rev-parse HEAD)'
run 'curl -s -H "$AS_BRUNO" -H "$JSON" -d '"'"'{"event": "APPROVED", "body": "Three it is."}'"'"' $API/pulls/2/reviews | jq -r .state'
run 'curl -s -w "%{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '"'"'{"Do": "merge"}'"'"' $API/pulls/2/merge'
run 'git switch --quiet main && git pull --quiet'
quiet 'sleep 20'
quiet 'kubectl -n staging rollout status deployment bulletin --timeout=120s'
run 'kubectl -n staging get deployment bulletin'

block bad-image
run 'git switch --quiet -c staging-1.1'
sed -i 's#localhost:5001/bulletin:1.0#localhost:5001/bulletin:1.1#' staging/bulletin.yaml
at 2026-10-13T14:00:00-03:00 run 'git commit --quiet -am "staging: bulletin 1.1"'
run 'git push --quiet -u origin staging-1.1'
run 'curl -s -H "$AS_ANA" -H "$JSON" -d '"'"'{"head": "staging-1.1", "base": "main", "title": "staging: bulletin 1.1", "body": "The new release, for QA."}'"'"' $API/pulls | jq .number'
run 'sh ~/setup/validate.sh $(git rev-parse HEAD)'
run 'curl -s -H "$AS_BRUNO" -H "$JSON" -d '"'"'{"event": "APPROVED", "body": "Fine."}'"'"' $API/pulls/3/reviews | jq -r .state'
run 'curl -s -w "%{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '"'"'{"Do": "merge"}'"'"' $API/pulls/3/merge'

block stuck
quiet 'sleep 45'
run 'kubectl -n staging get pods'
run 'kubectl -n staging get deployment bulletin'
run 'curl -s localhost:8080'

block revert
run 'git switch --quiet main && git pull --quiet'
run 'git switch --quiet -c revert-1.1'
at 2026-10-13T14:20:00-03:00 run 'git revert --no-edit -m 1 HEAD'
run 'git push --quiet -u origin revert-1.1'
run 'curl -s -H "$AS_ANA" -H "$JSON" -d '"'"'{"head": "revert-1.1", "base": "main", "title": "Revert staging to bulletin 1.0", "body": "1.1 was never built. Back to 1.0 until it is."}'"'"' $API/pulls | jq .number'
run 'sh ~/setup/validate.sh $(git rev-parse HEAD)'
run 'curl -s -H "$AS_BRUNO" -H "$JSON" -d '"'"'{"event": "APPROVED", "body": "Yes, revert."}'"'"' $API/pulls/4/reviews | jq -r .state'
run 'curl -s -w "%{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '"'"'{"Do": "merge"}'"'"' $API/pulls/4/merge'

block recovered
run 'git switch --quiet main && git pull --quiet'
quiet 'sleep 20'
quiet 'kubectl -n staging rollout status deployment bulletin --timeout=120s'
run 'kubectl -n staging get pods'
run 'git log --oneline --first-parent -4'

block recovered-loop
tail -n +$((seen + 1)) $LOG; seen=$(wc -l <$LOG)

block fail-token
run 'curl -s -w " %{http_code}\n" -H "Authorization: token 0123456789abcdef" $API'

block fail-stale
run 'git switch --quiet -c banner-v3'
sed -i 's/value: Staging is ready for review./value: Staging is in use by QA./' staging/bulletin.yaml
at 2026-10-13T15:00:00-03:00 run 'git commit --quiet -am "staging: in use by QA"'
run 'git push --quiet -u origin banner-v3'
run 'curl -s -H "$AS_ANA" -H "$JSON" -d '"'"'{"head": "banner-v3", "base": "main", "title": "staging: in use by QA"}'"'"' $API/pulls | jq .number'
run 'sh ~/setup/validate.sh $(git rev-parse HEAD)'
run 'curl -s -H "$AS_BRUNO" -H "$JSON" -d '"'"'{"event": "APPROVED", "body": "OK."}'"'"' $API/pulls/5/reviews | jq -r .state'
sed -i 's/value: Staging is in use by QA./value: Staging is in use by QA until Friday./' staging/bulletin.yaml
at 2026-10-13T15:05:00-03:00 run 'git commit --quiet -am "staging: until Friday"'
run 'git push --quiet'
run 'sh ~/setup/validate.sh $(git rev-parse HEAD)'
run 'curl -s -w " %{http_code}\n" -H "$AS_ANA" -H "$JSON" -d '"'"'{"Do": "merge"}'"'"' $API/pulls/5/merge'

block fail-password
run 'git ls-remote http://127.0.0.1:3000/ana/fleet.git'

kill $LOOP
git switch --quiet main
