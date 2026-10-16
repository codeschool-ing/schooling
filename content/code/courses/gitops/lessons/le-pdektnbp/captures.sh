#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of gitops, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON: every file under fleet and
# ~/setup is copied out of the lesson's .md by `shown`. What is STAGED:
#   - the state at the end of lesson 11 (`lab.sh up`, `stage1`, `stage2`,
#     `stage4` to `stage11`), Vault unsealed;
#   - every pull request to fleet, through `lab.sh merge`, as in lesson 3;
#   - the second cluster's node image comes from the lab's image cache, like
#     the first cluster's, and it is made without the recording machine's
#     proxy in the environment, as lab.sh makes the first.
#
# Recorded on Ubuntu 24.04 with Docker 29.8.2, kind 0.33.0, Flux 2.9.6 and
# Vault 2.1.2, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../capture.sh"
cd /home/ana
# LAB_READY=1 skips the rebuild when the lab is already in that state
[ -n "${LAB_READY:-}" ] || { lab up && lab stage1 && lab stage2 && lab stage4 && lab stage5 && lab stage6 && lab stage7 && lab stage8 && lab stage9 && lab stage10 && lab stage11 || exit 1; }
settle staging production
export VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=$(jq -r .root_token /home/ana/vault-init.json)
AS_ANA="Authorization: token $(cat ~/ana.token)"
API=http://localhost:3000/api/v1/repos/ana/fleet

block git-log
cd /home/ana/fleet
run "git log --first-parent --format='%h %ad %s' --date=format:'%m-%d %H:%M' main | head -n 8"

block pr-record
run "N=\$(curl -s -H \"\$AS_ANA\" \"\$API/pulls?state=closed&limit=1\" | jq '.[0].number'); echo \$N"
run "curl -s -H \"\$AS_ANA\" \$API/pulls/\$N | jq '{title, opened_by: .user.login, merged_by: .merged_by.login, merged_at, merge_commit_sha}'"
run "curl -s -H \"\$AS_ANA\" \$API/pulls/\$N/reviews | jq -c '.[] | {by: .user.login, state, submitted_at}'"
run "curl -s -H \"\$AS_ANA\" \$API/commits/\$(git rev-parse HEAD^2)/statuses | jq -c '.[] | {context, status, by: .creator.login}'"

block git-signature
run "git log --show-signature -1 --format='%h %an %s' \$(git log --no-merges --format=%h --grep='back to the signed chart' -1)"

block flux-events
run "kubectl -n flux-system get events --field-selector involvedObject.name=staging --sort-by=.lastTimestamp -o custom-columns=LAST:.lastTimestamp,COUNT:.count,TYPE:.type,REASON:.reason | tail -n 5"

block notify-secret
run 'kubectl -n flux-system create secret generic gitea-status --from-literal=token="$(cat ~/ci.token)"'

block notify-status
run 'git switch --quiet -c notifications'
shown "$HERE/flux-events.md" 'clusters/lab/notifications.yaml' clusters/lab/notifications.yaml
at 2026-10-10T02:40:00-03:00 run 'git add clusters && git commit --quiet -m "flux: report what it applied as commit statuses"'
lab merge notifications "flux: report what it applied as commit statuses" >/dev/null || exit 1
quiet 'flux reconcile kustomization flux-system --with-source'
for i in $(seq 60); do kubectl -n flux-system get alert fleet >/dev/null 2>&1 && break; sleep 2; done
quiet 'flux reconcile kustomization staging; flux reconcile kustomization production'
for i in $(seq 60); do curl -s -H "$AS_ANA" "$API/commits/$(git rev-parse HEAD)/statuses" | grep -q kustomization && break; sleep 2; done
quiet 'sleep 5'
run "curl -s -H \"\$AS_ANA\" \$API/commits/\$(git rev-parse HEAD)/statuses | jq -c '.[] | {context, status, description, by: .creator.login}'"

block managed-fields
run 'kubectl -n staging scale deployment bulletin --replicas=5'
run "kubectl -n staging get deployment bulletin -o json --show-managed-fields | jq -c '.metadata.managedFields[] | {manager, operation, time, replicas: (.fieldsV1.\"f:spec\".\"f:replicas\" != null)}'"
run 'flux reconcile kustomization staging >/dev/null'
run "kubectl -n staging get deployment bulletin -o json --show-managed-fields | jq -c '.metadata.managedFields[] | {manager, operation, time, replicas: (.fieldsV1.\"f:spec\".\"f:replicas\" != null)}'"

# the recording machine reaches the internet through a proxy, which kind would
# pass into the new nodes; lesson 1's cluster is made without it, and so is this
SAVED_PROXY=$(env | grep -i '_proxy=' || true)
unset HTTPS_PROXY https_proxy HTTP_PROXY http_proxy NO_PROXY no_proxy
block audit-cluster
cd /home/ana/setup
shown "$HERE/api-audit.md" '~/setup/audit-policy.yaml' /home/ana/setup/audit-policy.yaml
shown "$HERE/api-audit.md" '~/setup/audit-cluster.yaml' /home/ana/setup/audit-cluster.yaml
run 'kind create cluster --name audit --config audit-cluster.yaml --kubeconfig ~/.kube/audit --wait 2m --quiet'
run 'KUBECONFIG=~/.kube/audit kubectl get nodes'

block audit-read
run 'export KUBECONFIG=~/.kube/audit'
run 'kubectl create configmap note --from-literal=text=hello'
run 'kubectl create secret generic note --from-literal=password=not-in-the-log'
quiet 'sleep 2'
run "docker exec audit-control-plane cat /var/log/kubernetes/audit.log | jq -c 'select(.objectRef.name == \"note\" and .verb == \"create\") | {time: .requestReceivedTimestamp, user: .user.username, verb, resource: .objectRef.resource, name: .objectRef.name, level}'"
run "docker exec audit-control-plane grep -c not-in-the-log /var/log/kubernetes/audit.log"
run 'export KUBECONFIG=~/.kube/config'

block audit-delete
run 'kind delete cluster --name audit --kubeconfig ~/.kube/audit'

while IFS= read -r v; do [ -n "$v" ] && export "$v"; done <<< "$SAVED_PROXY"

block vault-audit-on
run 'vault audit enable file file_path=/vault/logs/audit.log'
run 'vault audit list'

block vault-audit-read
quiet 'kubectl -n production annotate externalsecret bulletin-token force-sync=$(date +%s) --overwrite'
for i in $(seq 90); do docker exec vault grep -q secret/data/bulletin/production /vault/logs/audit.log 2>/dev/null && break; sleep 2; done
run "docker exec vault cat /vault/logs/audit.log | jq -c 'select(.type == \"response\" and .request.path == \"secret/data/bulletin/production\") | {time, op: .request.operation, path: .request.path, role: .auth.metadata.role, account: .auth.metadata.service_account_name, namespace: .auth.metadata.service_account_namespace, token: .response.data.data.token}' | tail -n 1"
run 'vault write -field=hash sys/audit-hash/file input="$(vault kv get -field=token secret/bulletin/production)"; echo'

block trace
cd /home/ana/fleet
run "IMAGE=\$(kubectl -n production get deployment bulletin -o jsonpath='{.spec.template.spec.containers[0].image}'); echo \$IMAGE"
run "REV=\$(docker buildx imagetools inspect \$IMAGE --format '{{json .Provenance.SLSA}}' | jq -r '.buildDefinition.externalParameters.request.root.request.args[\"vcs:revision\"]'); echo \$REV"
run "git -C ~/bulletin log -1 --format='%h %an %s' \$REV"
run "C=\$(git log --format=%h -S \${IMAGE#*@} -- apps/bulletin/production | tail -n 1); git log -1 --format='%h %an %s' \$C"
run "git log --merges --ancestry-path --format='%h %s' \$C..main | tail -n 1"

block revoke-root
run 'vault token revoke $VAULT_TOKEN'
run 'vault token lookup'

echo FINISHED
