#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of gitops, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON: every file under fleet and
# ~/vault is copied out of the lesson's .md by `shown`. What is STAGED:
#   - the state at the end of lesson 10 (`lab.sh up`, `stage1`, `stage2`,
#     `stage4` to `stage10`), Vault unsealed;
#   - every pull request to fleet, through `lab.sh merge`, as in lesson 3;
#   - the PostgreSQL image is taken from the lab's image cache and tagged
#     with the name the lesson runs, so that the run below pulls nothing.
#
# Recorded on Ubuntu 24.04 with Docker 29.8.2, Flux 2.9.6, Vault 2.1.2 and
# PostgreSQL 17, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../capture.sh"
cd /home/ana
# LAB_READY=1 skips the rebuild when the lab is already in that state
[ -n "${LAB_READY:-}" ] || { lab up && lab stage1 && lab stage2 && lab stage4 && lab stage5 && lab stage6 && lab stage7 && lab stage8 && lab stage9 && lab stage10 || exit 1; }
settle staging production
export VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=$(jq -r .root_token /home/ana/vault-init.json)
quiet 'docker pull 127.0.0.1:5002/postgres:17-alpine && docker tag 127.0.0.1:5002/postgres:17-alpine postgres:17-alpine'
quiet 'docker rm -fv postgres'
psql_as() { docker run --rm --network kind -e PGPASSWORD="$2" postgres:17-alpine psql -h postgres -U "$1" -d bulletin -tAc "$3"; }

block postgres
run 'docker run -d --name postgres --network kind -e POSTGRES_PASSWORD=initial-password -e POSTGRES_DB=bulletin postgres:17-alpine'
for i in $(seq 60); do docker exec postgres pg_isready -q 2>/dev/null && break; sleep 1; done
quiet 'sleep 2'
run 'docker exec postgres pg_isready'

block db-config
run 'vault secrets enable database'
run "vault write database/config/bulletin plugin_name=postgresql-database-plugin connection_url='postgresql://{{username}}:{{password}}@postgres:5432/bulletin?sslmode=disable' allowed_roles=bulletin-readonly username=postgres password=initial-password"

block db-role
shown "$HERE/dynamic-credentials.md" '~/vault/readonly.sql' /home/ana/vault/readonly.sql
run 'cat ~/vault/readonly.sql'
run 'vault write database/roles/bulletin-readonly db_name=bulletin creation_statements=@$HOME/vault/readonly.sql default_ttl=1h max_ttl=24h'

block db-creds
run 'CREDS=$(vault read -format=json database/creds/bulletin-readonly)'
run "echo \"\$CREDS\" | jq '{lease_id, lease_duration, renewable, username: .data.username}'"

block db-login
run 'DBUSER=$(echo "$CREDS" | jq -r .data.username) PASS=$(echo "$CREDS" | jq -r .data.password)'
run 'docker run --rm --network kind -e PGPASSWORD=$PASS postgres:17-alpine psql -h postgres -U $DBUSER -d bulletin -tAc "select current_user"'
run "docker exec postgres psql -U postgres -tAc \"select rolname, rolvaliduntil from pg_roles where rolname like 'v-%'\""

block db-revoke
run 'vault lease revoke $(echo "$CREDS" | jq -r .lease_id)'
run 'docker run --rm --network kind -e PGPASSWORD=$PASS postgres:17-alpine psql -h postgres -U $DBUSER -d bulletin -tAc "select current_user"'

block db-rotate-root
run 'vault write -f database/rotate-root/bulletin'
run 'docker run --rm --network kind -e PGPASSWORD=initial-password postgres:17-alpine psql -h postgres -U postgres -d bulletin -tAc "select 1"'
run 'vault read -format=json database/creds/bulletin-readonly | jq -r .data.username'

block rotate-new
cd /home/ana
run 'docker exec gitea gitea admin user generate-access-token --username image-bot --token-name automation-2 --scopes write:repository --raw > ~/image-bot-2.token 2>/dev/null && chmod 600 ~/image-bot-2.token'
run "curl -s -u image-bot:change-me-please http://localhost:3000/api/v1/users/image-bot/tokens | jq -r '.[].name'"

block rotate-deliver
run 'flux create secret git fleet-writer-auth --url=http://gitea:3000/ana/fleet.git --username=image-bot --password="$(cat ~/image-bot-2.token)"'
run 'flux reconcile source git fleet-writer'
run 'flux get sources git fleet-writer'

block rotate-revoke
run 'curl -s -o /dev/null -w "%{http_code}\n" -u image-bot:change-me-please -X DELETE http://localhost:3000/api/v1/users/image-bot/tokens/automation'
run 'curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: token $(cat ~/image-bot.token)" http://localhost:3000/api/v1/repos/ana/fleet'
run 'mv ~/image-bot-2.token ~/image-bot.token'
run 'flux reconcile source git fleet-writer && flux get sources git fleet-writer'

block flux-admin
cd /home/ana/fleet
run "kubectl get clusterrolebinding cluster-reconciler-flux-system -o custom-columns=ROLE:.roleRef.name,SUBJECTS:.subjects[*].name"
run 'kubectl auth can-i create clusterrolebindings --all-namespaces --as=system:serviceaccount:flux-system:kustomize-controller'

block impersonate-fail
run 'git switch --quiet -c staging-applier'
shown "$HERE/flux-impersonation.md" 'clusters/lab/staging-applier.yaml' clusters/lab/staging-applier.yaml
sed -i 's/^spec:$/spec:\n  serviceAccountName: staging-applier/' clusters/lab/staging.yaml
run "git diff | grep '^[-+] '"
at 2026-10-10T02:20:00-03:00 run 'git add clusters && git commit --quiet -m "staging: applied as staging-applier"'
lab merge staging-applier "staging: applied as staging-applier" >/dev/null || exit 1
quiet 'flux reconcile kustomization flux-system --with-source'
quiet 'flux reconcile kustomization staging'
for i in $(seq 60); do kubectl -n flux-system get kustomization staging -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}' | grep -q forbidden && break; sleep 2; done
run 'flux get kustomizations staging'

block impersonate-all
run 'kubectl kustomize apps/bulletin/staging | kubectl apply --server-side --dry-run=server --as=system:serviceaccount:flux-system:staging-applier -f -'

block impersonate-ok
run 'git switch --quiet main && git pull --quiet && git switch --quiet -c staging-applier-extra'
shown "$HERE/flux-impersonation.md" 'clusters/lab/staging-applier-extra.yaml' clusters/lab/staging-applier-extra.yaml
at 2026-10-10T02:25:00-03:00 run 'git add clusters && git commit --quiet -m "staging-applier: its namespace and its sealed secrets"'
lab merge staging-applier-extra "staging-applier: its namespace and its sealed secrets" >/dev/null || exit 1
quiet 'flux reconcile kustomization flux-system --with-source'
quiet 'flux reconcile kustomization staging'
for i in $(seq 60); do kubectl -n flux-system get kustomization staging -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q True && break; sleep 2; done
run 'flux get kustomizations staging'

block escalate
run 'git switch --quiet main && git pull --quiet && git switch --quiet -c staging-debug'
shown "$HERE/flux-impersonation.md" 'apps/bulletin/staging/debug.yaml' apps/bulletin/staging/debug.yaml
sed -i 's/^resources:$/resources:\n- debug.yaml/' apps/bulletin/staging/kustomization.yaml
at 2026-10-10T02:30:00-03:00 run 'git add apps && git commit --quiet -m "staging: a debugging account"'
lab merge staging-debug "staging: a debugging account" >/dev/null || exit 1
quiet 'flux reconcile kustomization flux-system --with-source'
quiet 'flux reconcile kustomization staging'
for i in $(seq 60); do kubectl -n flux-system get kustomization staging -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}' | grep -q forbidden && break; sleep 2; done
run 'flux get kustomizations staging'
run 'kubectl get clusterrolebinding staging-debug'
run 'git switch --quiet main && git pull --quiet && git switch --quiet -c revert-staging-debug'
at 2026-10-10T02:35:00-03:00 run 'git revert --no-edit HEAD^2 >/dev/null && git log -1 --format=%s'
lab merge revert-staging-debug "staging: no debugging account" >/dev/null || exit 1
quiet 'flux reconcile kustomization flux-system --with-source'
quiet 'flux reconcile kustomization staging'
for i in $(seq 60); do kubectl -n flux-system get kustomization staging -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q True && break; sleep 2; done
run 'flux get kustomizations staging'

echo FINISHED
