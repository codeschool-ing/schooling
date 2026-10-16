#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of gitops, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON: every file under fleet is
# copied out of the lesson's .md by `shown`. What is STAGED:
#   - the state at the end of lesson 9 (`lab.sh up`, `stage1`, `stage2`,
#     `stage4` to `stage9`), Vault unsealed;
#   - every pull request to fleet, through `lab.sh merge`, as in lesson 3;
#   - the operator's image. The chart asks for
#     ghcr.io/external-secrets/external-secrets:v1.3.2, which this machine
#     cannot download; `lab.sh images` builds that version from its tagged
#     source and the nodes' mirror for ghcr.io serves it under that name.
#   - the cloud SecretStores are checked by the API server with a dry run,
#     and never used: the recording machine has no cloud account.
#
# Recorded on Ubuntu 24.04 with Docker 29.8.2, Flux 2.9.6, Helm 4.3.0 and
# Vault 2.1.2, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../capture.sh"
cd /home/ana
# LAB_READY=1 skips the rebuild when the lab is already in that state
[ -n "${LAB_READY:-}" ] || { lab up && lab stage1 && lab stage2 && lab stage4 && lab stage5 && lab stage6 && lab stage7 && lab stage8 && lab stage9 || exit 1; }
settle staging production
export VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=$(jq -r .root_token /home/ana/vault-init.json)
waitfor() { for i in $(seq 120); do curl -s "$1" | grep -q "$2" && return; sleep 2; done; }
fingerprint() { curl -s localhost:8081 | awk '/^token:/ { print $2 }'; }
# every pod answers with Vault's current value, twelve times in a row
consistent() {
  local want n i
  want=sha256:$(vault kv get -field=token secret/bulletin/production | sha256sum | cut -c1-12)
  for i in $(seq 150); do
    n=0; for j in $(seq 12); do [ "$(fingerprint)" = "$want" ] && n=$((n + 1)); done
    [ "$n" = 12 ] && return; sleep 2
  done
}

block chart
cd /home/ana/setup
run 'curl -fsSLO https://github.com/external-secrets/external-secrets/releases/download/helm-chart-1.3.2/external-secrets-1.3.2.tgz'
run "helm show chart external-secrets-1.3.2.tgz | grep -E '^(name|version|appVersion):'"

block chart-push
run 'helm push external-secrets-1.3.2.tgz oci://localhost:5001/charts --plain-http'

block install
cd /home/ana/fleet
run 'git switch --quiet -c external-secrets'
mkdir -p infrastructure/external-secrets
for f in namespace.yaml release.yaml kustomization.yaml; do
  shown "$HERE/installing.md" "infrastructure/external-secrets/$f" "infrastructure/external-secrets/$f"
done
sed 's/sealed-secrets/external-secrets/g' clusters/lab/sealed-secrets.yaml > clusters/lab/external-secrets.yaml
run 'git add infrastructure clusters && git status --short'
at 2026-10-10T02:00:00-03:00 run 'git commit --quiet -m "external-secrets: the operator, 1.3.2"'
lab merge external-secrets "external-secrets: the operator, 1.3.2" >/dev/null || exit 1
quiet 'flux reconcile kustomization flux-system --with-source'
for i in $(seq 150); do flux get helmreleases -n external-secrets 2>/dev/null | grep -q 'True' && break; sleep 2; done
quiet 'kubectl -n external-secrets wait --for=condition=Available deployment --all --timeout=180s'
run 'kubectl -n external-secrets get deployments'
run "kubectl get crds -o name | grep -c external-secrets.io"

block cloud-dry-run
cd /home/ana/setup
awk '/^```yaml$/ { n++; next } /^```$/ { if (n == 1) exit } n == 1' "$HERE/cloud-stores.md" > cloud-stores.yaml
run 'kubectl apply --dry-run=server -f cloud-stores.yaml'
rm -f cloud-stores.yaml

block to-vault
cd /home/ana/fleet
run 'git switch --quiet -c production-vault'
shown "$HERE/production-from-vault.md" 'apps/bulletin/production/vault.yaml' apps/bulletin/production/vault.yaml
sed -i 's/-skip HelmRelease,OCIRepository,SealedSecret /-skip HelmRelease,OCIRepository,SealedSecret,SecretStore,ExternalSecret /' ~/setup/validate.sh
sed -i 's/^- token.sops.yaml$/- vault.yaml/' apps/bulletin/production/kustomization.yaml
run 'git rm --quiet apps/bulletin/production/token.sops.yaml && git add apps'
run "git diff --cached --stat"
at 2026-10-10T02:10:00-03:00 run 'git commit --quiet -m "production: the token comes from Vault"'
lab merge production-vault "production: the token comes from Vault" >/dev/null || exit 1
quiet 'flux reconcile kustomization flux-system --with-source'
for i in $(seq 120); do kubectl -n production get externalsecret bulletin-token -o jsonpath='{.status.conditions[0].reason}' 2>/dev/null | grep -q SecretSynced && break; sleep 2; done
consistent
run 'kubectl -n production get secretstore,externalsecret'
run 'curl -s localhost:8081'
run 'vault kv get -field=token secret/bulletin/production | sha256sum | cut -c1-12'

block refresh
run 'kubectl -n production get pods -o name'
run 'vault kv put secret/bulletin/production token=$(openssl rand -hex 16) | grep -E "^(version|created_time)"'
consistent
run 'curl -s localhost:8081'
run 'kubectl -n production get pods -o name'
run 'vault kv get -field=token secret/bulletin/production | sha256sum | cut -c1-12'

block fail-key
run "kubectl -n production patch externalsecret bulletin-token --type merge -p '{\"spec\":{\"data\":[{\"secretKey\":\"token\",\"remoteRef\":{\"key\":\"bulletin/prod\",\"property\":\"token\"}}]}}'"
quiet 'kubectl -n production annotate externalsecret bulletin-token force-sync=$(date +%s) --overwrite'
for i in $(seq 60); do kubectl -n production get externalsecret bulletin-token -o jsonpath='{.status.conditions[0].reason}' | grep -q Error && break; sleep 2; done
run 'kubectl -n production get externalsecret bulletin-token'
run "kubectl -n production get externalsecret bulletin-token -o jsonpath='{.status.conditions[0].message}'; echo"
run 'kubectl -n external-secrets logs deployment/external-secrets --since=2m | grep bulletin-token | tail -n 1 | jq -c "{msg, error}"'
run 'curl -s localhost:8081 | grep token'
quiet 'flux reconcile kustomization production'
for i in $(seq 60); do kubectl -n production get externalsecret bulletin-token -o jsonpath='{.status.conditions[0].reason}' | grep -q SecretSynced && break; sleep 2; done

block fail-sealed
run 'docker restart vault'
quiet 'sleep 3'
quiet 'kubectl -n production annotate externalsecret bulletin-token force-sync=$(date +%s) --overwrite'
for i in $(seq 60); do kubectl -n production get externalsecret bulletin-token -o jsonpath='{.status.conditions[0].reason}' | grep -q Error && break; sleep 2; done
run 'kubectl -n production get secretstore,externalsecret'
run 'kubectl -n external-secrets logs deployment/external-secrets --since=1m | grep bulletin-token | tail -n 1 | jq -c "{msg, error}"'
run 'curl -s localhost:8081 | grep token'
run "vault operator unseal \$(jq -r '.unseal_keys_b64[0]' ~/vault-init.json) | grep '^Sealed'"

echo FINISHED
