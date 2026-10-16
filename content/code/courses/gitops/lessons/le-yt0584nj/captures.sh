#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of gitops, as a script that
# produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# THE STUDENT BUILDS ALL OF THIS FROM THE LESSON: every file under fleet and
# ~/vault is copied out of the lesson's .md by `shown`; the keys, tokens and
# encrypted files are made by the commands the lesson shows. What is STAGED:
#   - the state at the end of lesson 8 (`lab.sh up`, `stage1`, `stage2`,
#     `stage4` to `stage8`);
#   - every pull request to fleet, through `lab.sh merge`, as in lesson 3;
#   - edits made in an editor are made with sed here;
#   - the Vault image is taken from the lab's image cache and tagged with the
#     name the lesson runs, so that the run below pulls nothing.
#
# Recorded on Ubuntu 24.04 with Docker 29.8.2, Flux 2.9.6, kubeseal 0.40.0,
# SOPS 3.13.3, age 1.3.2 and Vault 2.1.2, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../capture.sh"
cd /home/ana
lab up && lab stage1 && lab stage2 && lab stage4 && lab stage5 && lab stage6 && lab stage7 && lab stage8 || exit 1
settle staging production
waitfor() { for i in $(seq 120); do curl -s "$1" | grep -q "$2" && return; sleep 2; done; }
rm -f /usr/local/bin/kubeseal /usr/local/bin/sops /usr/local/bin/age /usr/local/bin/age-keygen
quiet 'docker pull 127.0.0.1:5002/hashicorp/vault:2.1.2 && docker tag 127.0.0.1:5002/hashicorp/vault:2.1.2 hashicorp/vault:2.1.2'

block secret
cd /home/ana/fleet
run 'kubectl -n staging create secret generic bulletin-token --from-literal=token=a-staging-token --dry-run=client -o yaml'

block decode
run "kubectl -n staging create secret generic bulletin-token --from-literal=token=a-staging-token --dry-run=client -o jsonpath='{.data.token}' | base64 -d; echo"

block install-kubeseal
cd /home/ana/setup
run 'ARCH=$(dpkg --print-architecture)'
run 'curl -fsSLO https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.40.0/kubeseal-0.40.0-linux-$ARCH.tar.gz'
run 'curl -fsSL https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.40.0/sealed-secrets_0.40.0_checksums.txt | grep " kubeseal-0.40.0-linux-$ARCH.tar.gz$" | sha256sum --check'
run 'tar -xzf kubeseal-0.40.0-linux-$ARCH.tar.gz kubeseal && sudo install -m 0755 kubeseal /usr/local/bin/ && rm kubeseal kubeseal-0.40.0-linux-$ARCH.tar.gz'
run 'kubeseal --version'

block controller
cd /home/ana/fleet
run 'git switch --quiet -c sealed-secrets'
run 'mkdir -p infrastructure/sealed-secrets'
run 'curl -fsSLo infrastructure/sealed-secrets/controller.yaml https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.40.0/controller.yaml'
run "grep -c '^kind:' infrastructure/sealed-secrets/controller.yaml"
shown "$HERE/sealed-secrets.md" 'clusters/lab/sealed-secrets.yaml' clusters/lab/sealed-secrets.yaml
at 2026-10-10T01:00:00-03:00 run 'git add infrastructure clusters && git commit --quiet -m "sealed-secrets: the controller, 0.40.0"'
lab merge sealed-secrets "sealed-secrets: the controller, 0.40.0" >/dev/null || exit 1
quiet 'flux reconcile kustomization flux-system --with-source'
for i in $(seq 90); do kubectl -n kube-system get deployment sealed-secrets-controller >/dev/null 2>&1 && break; sleep 2; done
quiet 'kubectl -n kube-system rollout status deployment sealed-secrets-controller --timeout=180s'
run 'kubectl -n kube-system get deployment sealed-secrets-controller'

block fetch-cert
run 'kubeseal --fetch-cert > ~/setup/sealed-secrets.pem'
run 'openssl x509 -in ~/setup/sealed-secrets.pem -noout -subject -enddate'

block seal
run 'git switch --quiet -c staging-token'
run 'TOKEN=$(openssl rand -hex 16)'
run 'kubectl -n staging create secret generic bulletin-token --from-literal=token=$TOKEN --dry-run=client -o yaml | kubeseal --cert ~/setup/sealed-secrets.pem -o yaml > apps/bulletin/staging/token.yaml'
run 'cat apps/bulletin/staging/token.yaml'

block mount
shown "$HERE/sealed-secrets.md" 'apps/bulletin/base/deployment.yaml' apps/bulletin/base/deployment.yaml
sed -i 's#^- \.\./base$#- ../base\n- token.yaml#' apps/bulletin/staging/kustomization.yaml
sed -i 's/^spec:$/spec:\n  dependsOn:\n  - name: sealed-secrets/' clusters/lab/staging.yaml
sed -i 's/-skip HelmRelease,OCIRepository /-skip HelmRelease,OCIRepository,SealedSecret /' ~/setup/validate.sh
run "git diff | grep '^[-+] '"
at 2026-10-10T01:10:00-03:00 run 'git add apps clusters && git commit --quiet -m "staging: a sealed token"'
lab merge staging-token "staging: a sealed token" >/dev/null || exit 1
quiet 'flux reconcile kustomization flux-system --with-source'
waitfor localhost:8080 'token: sha256'
quiet 'kubectl -n staging rollout status deployment bulletin --timeout=120s'
settle staging
run 'kubectl -n staging get sealedsecrets,secrets'
run 'curl -s localhost:8080'
run 'printf %s "$TOKEN" | sha256sum | cut -c1-12'

block fail-scope
run "sed 's/namespace: staging/namespace: production/' apps/bulletin/staging/token.yaml | kubectl apply -f -"
quiet 'sleep 5'
run 'kubectl -n production get sealedsecret bulletin-token'
run 'kubectl -n production get events --field-selector involvedObject.name=bulletin-token -o custom-columns=REASON:.reason,MESSAGE:.message'
run 'kubectl -n production delete sealedsecret bulletin-token'

block controller-key
run 'kubectl -n kube-system get secrets -l sealedsecrets.bitnami.com/sealed-secrets-key'

block install-sops
cd /home/ana/setup
run 'curl -fsSLO https://github.com/getsops/sops/releases/download/v3.13.3/sops-v3.13.3.linux.$ARCH'
run 'curl -fsSL https://github.com/getsops/sops/releases/download/v3.13.3/sops-v3.13.3.checksums.txt | grep " sops-v3.13.3.linux.$ARCH$" | sha256sum --check'
run 'sudo install -m 0755 sops-v3.13.3.linux.$ARCH /usr/local/bin/sops && rm sops-v3.13.3.linux.$ARCH'
run 'curl -fsSLO https://github.com/FiloSottile/age/releases/download/v1.3.2/age-v1.3.2-linux-$ARCH.tar.gz'
run 'tar -xzf age-v1.3.2-linux-$ARCH.tar.gz && sudo install -m 0755 age/age age/age-keygen /usr/local/bin/ && rm -r age age-v1.3.2-linux-$ARCH.tar.gz'
run 'sops --disable-version-check --version; age --version'

block age-key
cd /home/ana
quiet 'rm -rf ~/.config/sops'
run 'mkdir -p ~/.config/sops/age && age-keygen -o ~/.config/sops/age/keys.txt'
run "stat -c '%A %n' ~/.config/sops/age/keys.txt"
run 'AGE=$(age-keygen -y ~/.config/sops/age/keys.txt); echo $AGE'

block encrypt
cd /home/ana/fleet
run 'git switch --quiet -c production-token'
shown "$HERE/sops.md" '.sops.yaml' .sops.yaml
sed -i "s/AGE_PUBLIC_KEY/$AGE/" .sops.yaml
run 'cat .sops.yaml'
run 'TOKEN=$(openssl rand -hex 16)'
run 'kubectl -n production create secret generic bulletin-token --from-literal=token=$TOKEN --dry-run=client -o yaml > apps/bulletin/production/token.sops.yaml'
run 'sops --encrypt --in-place apps/bulletin/production/token.sops.yaml'
run 'cat apps/bulletin/production/token.sops.yaml'

block decrypt
run "sops --decrypt --extract '[\"data\"][\"token\"]' apps/bulletin/production/token.sops.yaml | base64 -d | sha256sum | cut -c1-12"

block fail-ci
sed -i 's#^- \.\./base$#- ../base\n- token.sops.yaml#' apps/bulletin/production/kustomization.yaml
at 2026-10-10T01:20:00-03:00 run 'git add .sops.yaml apps && git commit --quiet -m "production: a token encrypted with SOPS"'
run 'git push --quiet -u origin production-token 2>/dev/null'
run 'sh ~/setup/validate.sh $(git rev-parse HEAD)'


block fix-ci
python3 - <<'PY'
p = '/home/ana/setup/validate.sh'
s = open(p).read()
old = [l for l in s.split('\n') if l.startswith('  elif ! kubeconform')][0]
new = """  elif ! awk '/^sops:/ { s = 1; next } /^[^ ]/ { s = 0 } !s' "$work/out.yaml" |
       kubeconform -strict -summary -skip HelmRelease,OCIRepository,SealedSecret -kubernetes-version 1.37.0; then"""
open(p, 'w').write(s.replace(old, new))
PY
run 'sh ~/setup/validate.sh $(git rev-parse HEAD)'

block flux-decrypt
run 'kubectl -n flux-system create secret generic sops-age --from-file=age.agekey=$HOME/.config/sops/age/keys.txt'
sed -i 's/^spec:$/spec:\n  decryption:\n    provider: sops\n    secretRef:\n      name: sops-age/' clusters/lab/production.yaml
run "git diff | grep '^[-+] '"
at 2026-10-10T01:30:00-03:00 run 'git commit --quiet -am "production: Flux decrypts with sops-age"'
lab merge production-token "production: a token encrypted with SOPS" >/dev/null || exit 1
quiet 'flux reconcile kustomization flux-system --with-source'
# every pod has to have the file, and the Service spreads requests across them
allhave() { local n; for n in $(seq 12); do curl -s "$1" | grep -q 'token: sha256' || return 1; done; }
for i in $(seq 300); do allhave localhost:8081 && break; sleep 2; done
quiet 'kubectl -n production rollout status deployment bulletin --timeout=120s'
settle production
run 'curl -s localhost:8081'
run 'kubectl -n production get secret bulletin-token -o jsonpath="{.data.token}" | base64 -d | sha256sum | cut -c1-12'

block install-vault
cd /home/ana/setup
run 'curl -fsSLO https://releases.hashicorp.com/vault/2.1.2/vault_2.1.2_linux_$ARCH.zip'
run 'curl -fsSL https://releases.hashicorp.com/vault/2.1.2/vault_2.1.2_SHA256SUMS | grep " vault_2.1.2_linux_$ARCH.zip$" | sha256sum --check'
run 'unzip -q vault_2.1.2_linux_$ARCH.zip vault && sudo install -m 0755 vault /usr/local/bin/ && rm vault vault_2.1.2_linux_$ARCH.zip'
run 'vault version'

block vault-run
cd /home/ana
quiet 'docker rm -fv vault; docker volume rm vault-data'
mkdir -p /home/ana/vault
shown "$HERE/vault.md" '~/vault/vault.hcl' /home/ana/vault/vault.hcl
run 'docker run -d --name vault --network kind -p 127.0.0.1:8200:8200 -v ~/vault:/vault/config:ro -v vault-data:/vault/file hashicorp/vault:2.1.2 server'
for i in $(seq 60); do curl -s 127.0.0.1:8200/v1/sys/seal-status >/dev/null && break; sleep 1; done
run 'export VAULT_ADDR=http://127.0.0.1:8200'
run 'vault status'

block vault-init
run 'vault operator init -key-shares=1 -key-threshold=1 -format=json > ~/vault-init.json && chmod 600 ~/vault-init.json'
run 'jq -c keys ~/vault-init.json'
run "vault operator unseal \$(jq -r '.unseal_keys_b64[0]' ~/vault-init.json) | grep -E '^(Initialized|Sealed)'"

block vault-kv
run 'export VAULT_TOKEN=$(jq -r .root_token ~/vault-init.json)'
run 'vault secrets enable -path=secret kv-v2'
run 'vault kv put secret/bulletin/staging token=$(openssl rand -hex 16) >/dev/null'
run 'vault kv put secret/bulletin/production token=$(openssl rand -hex 16)'
run 'vault kv get -field=token secret/bulletin/production | sha256sum | cut -c1-12'

block vault-sealed
run 'docker restart vault'
for i in $(seq 60); do curl -s 127.0.0.1:8200/v1/sys/seal-status >/dev/null && break; sleep 1; done
run "vault status | grep -E '^(Initialized|Sealed)'"
run 'vault kv get secret/bulletin/production'
run "vault operator unseal \$(jq -r '.unseal_keys_b64[0]' ~/vault-init.json) | grep '^Sealed'"

block vault-auth-pr
cd /home/ana/fleet
run 'git switch --quiet -c vault-auth'
mkdir -p infrastructure/vault-auth
shown "$HERE/vault-kubernetes.md" 'infrastructure/vault-auth/vault-auth.yaml' infrastructure/vault-auth/vault-auth.yaml
shown "$HERE/vault-kubernetes.md" 'apps/bulletin/production/serviceaccount.yaml' apps/bulletin/production/serviceaccount.yaml
sed 's/sealed-secrets/vault-auth/g' clusters/lab/sealed-secrets.yaml > clusters/lab/vault-auth.yaml
sed -i 's#^- \.\./base$#- ../base\n- serviceaccount.yaml#' apps/bulletin/production/kustomization.yaml
run 'git add infrastructure apps clusters && git status --short'
at 2026-10-10T01:40:00-03:00 run 'git commit --quiet -m "vault: an identity to check tokens with, and one for production"'
lab merge vault-auth "vault: an identity to check tokens with, and one for production" >/dev/null || exit 1
quiet 'flux reconcile kustomization flux-system --with-source'
for i in $(seq 90); do kubectl -n vault-auth get secret vault-auth -o jsonpath='{.data.token}' 2>/dev/null | grep -q . && kubectl -n production get serviceaccount bulletin >/dev/null 2>&1 && break; sleep 2; done
run 'kubectl -n vault-auth get serviceaccount,secret'
run 'kubectl -n production get serviceaccount bulletin'

block vault-config
cd /home/ana
run 'vault auth enable kubernetes'
run "kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ~/vault/cluster-ca.crt"
run "vault write auth/kubernetes/config kubernetes_host=https://gitops-control-plane:6443 kubernetes_ca_cert=@\$HOME/vault/cluster-ca.crt token_reviewer_jwt=\$(kubectl -n vault-auth get secret vault-auth -o jsonpath='{.data.token}' | base64 -d)"

block vault-role
shown "$HERE/vault-kubernetes.md" '~/vault/bulletin-production.hcl' /home/ana/vault/bulletin-production.hcl
run 'vault policy write bulletin-production ~/vault/bulletin-production.hcl'
run 'vault write auth/kubernetes/role/bulletin-production bound_service_account_names=bulletin bound_service_account_namespaces=production policies=bulletin-production ttl=10m'

block vault-login
run 'POD_TOKEN=$(kubectl -n production create token bulletin)'
run "vault write -format=json auth/kubernetes/login role=bulletin-production jwt=\$POD_TOKEN | jq '.auth | {policies, lease_duration, metadata}'"

block vault-read
run "BULLETIN=\$(vault write -field=token auth/kubernetes/login role=bulletin-production jwt=\$POD_TOKEN)"
run 'VAULT_TOKEN=$BULLETIN vault kv get -field=token secret/bulletin/production | sha256sum | cut -c1-12'
run 'VAULT_TOKEN=$BULLETIN vault kv get secret/bulletin/staging'

block fail-login
run 'vault write auth/kubernetes/login role=bulletin-production jwt=$(kubectl -n staging create token default)'

block fail-sops
cd /home/ana/fleet
run 'HOME=/tmp sops --decrypt apps/bulletin/production/token.sops.yaml'

echo FINISHED
