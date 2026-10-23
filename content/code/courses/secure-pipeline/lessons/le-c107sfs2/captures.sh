#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of secure-pipeline, as a script
# that produces them. Each block of output starts with `##### <name>`.
#
#   sudo bash captures.sh
#
# WHAT IS STAGED: the project as lesson 16 leaves it, with the CI server's
# signing key and its password in ~/ci/keys (lesson 14). Every file the
# lesson has the student save is copied out of the lesson's own fences
# (`place`). Nothing else is prepared: Vault is started on screen from the
# image hashicorp/vault:2.1.2, which was pulled before the recording.
#
# WHAT DIFFERS BETWEEN RUNS: the container id, Vault's unseal key and root
# token, the creation time Vault records, and the RSA keys, so every token
# is different. The one wait the lesson shows is real: a sleep as long as
# the token's life.
#
# Recorded on Ubuntu 24.04 with Docker 29.9.1, TZ=America/Sao_Paulo.
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lab/capture.sh"
MD=lessons/le-c107sfs2
docker rm -f vault >/dev/null 2>&1
lab project 17 >/dev/null 2>&1 || { echo "##### the project did not build" >&2; exit 1; }

block inventory
run 'cd linkbox'
run 'grep -n -e password -e LINKBOX_TOKEN ci/*.sh'
run 'ls -l ~/ci/keys'

block vault-start
run 'docker run -d --name vault -p 127.0.0.1:8200:8200 -e VAULT_ADDR=http://127.0.0.1:8200 -e VAULT_DEV_ROOT_TOKEN_ID=dev-only-root hashicorp/vault:2.1.2'
quiet 'sleep 3'
run 'docker logs vault 2>&1 | sed -n "/WARNING!/,/production/p"'

block vault-cli
run 'vault() { docker exec -i vault vault "$@"; }'
run 'vault status'

block kv
run 'vault kv put secret/linkbox/signing password="$(cat ~/ci/keys/password)"'
run '[ "$(vault kv get -field=password secret/linkbox/signing)" = "$(cat ~/ci/keys/password)" ] && echo same'

block policy
place "$MD/policies.md" "~/ci/vault/linkbox-sign.hcl"
run 'vault policy write linkbox-sign - <~/ci/vault/linkbox-sign.hcl'
run 't=$(vault token create -policy=linkbox-sign -ttl=30s -field=token)'
run 'vault token lookup "$t" | grep -E "^(policies|ttl) "'

block reads
run 'export VAULT_ADDR=http://127.0.0.1:8200'
run 'curl -s -H "X-Vault-Token: $t" $VAULT_ADDR/v1/secret/data/linkbox/signing | jq -c ".data.data | keys"'
run 'curl -s -H "X-Vault-Token: $t" $VAULT_ADDR/v1/secret/data/linkbox/registry | jq -c'
run 'curl -s -H "X-Vault-Token: $t" --data "{\"data\": {\"password\": \"x\"}}" $VAULT_ADDR/v1/secret/data/linkbox/signing | jq -c'

block expiry
run 'sleep 30'
run 'curl -s -H "X-Vault-Token: $t" $VAULT_ADDR/v1/secret/data/linkbox/signing | jq -c'

block keys
run 'mkdir -p ~/ci/oidc && cd ~/ci/oidc'
run 'openssl genpkey -quiet -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out ci-oidc.key'
run 'openssl pkey -in ci-oidc.key -pubout -out ci-oidc.pub'
place "$MD/identity.md" "~/ci/oidc/mint.py"

block files
run 'ls -l'
run 'cd ~/linkbox'

block mint
run 'main=$(python3 ~/ci/oidc/mint.py refs/heads/main)'
run 'cut -c1-64 <<<"$main"'
cmd=$(cat <<'EOF'
jq -R 'split(".")[1] | gsub("-";"+") | gsub("_";"/") | @base64d | fromjson' <<<"$main"
EOF
)
run "$cmd"

block jwt-config
run 'vault auth enable jwt'
run 'vault write auth/jwt/config jwt_validation_pubkeys="$(cat ~/ci/oidc/ci-oidc.pub)" bound_issuer=https://ci.linkbox.example'

block broad
run 'vault write auth/jwt/role/linkbox-any role_type=jwt bound_audiences=vault user_claim=sub token_policies=linkbox-sign token_ttl=5m'
run 'feature=$(python3 ~/ci/oidc/mint.py refs/heads/try-something)'
run 'curl -s --data "{\"role\": \"linkbox-any\", \"jwt\": \"$feature\"}" $VAULT_ADDR/v1/auth/jwt/login | jq -c ".auth | {policies, lease_duration}"'
run 'vault delete auth/jwt/role/linkbox-any'

block bound
place "$MD/jwt-auth.md" "~/ci/vault/linkbox-main.json"
run 'vault write auth/jwt/role/linkbox-main - <~/ci/vault/linkbox-main.json'
run 'curl -s --data "{\"role\": \"linkbox-main\", \"jwt\": \"$main\"}" $VAULT_ADDR/v1/auth/jwt/login | jq -c ".auth | {policies, lease_duration}"'
run 'curl -s --data "{\"role\": \"linkbox-main\", \"jwt\": \"$feature\"}" $VAULT_ADDR/v1/auth/jwt/login | jq -c'

block others
run 'elsewhere=$(python3 ~/ci/oidc/mint.py refs/heads/main registry)'
run 'curl -s --data "{\"role\": \"linkbox-main\", \"jwt\": \"$elsewhere\"}" $VAULT_ADDR/v1/auth/jwt/login | jq -c'
run 'openssl genpkey -quiet -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out /tmp/stranger.key'
run 'stranger=$(CI_OIDC_KEY=/tmp/stranger.key python3 ~/ci/oidc/mint.py refs/heads/main)'
run 'curl -s --data "{\"role\": \"linkbox-main\", \"jwt\": \"$stranger\"}" $VAULT_ADDR/v1/auth/jwt/login | jq -c'
run 'rm /tmp/stranger.key'

block script
place "$MD/jwt-auth.md" "ci/vault-read.sh"
run 'CI_ID_TOKEN=$main bash ci/vault-read.sh linkbox-main linkbox/signing password | cmp - ~/ci/keys/password && echo same'
run 'CI_ID_TOKEN=$feature bash ci/vault-read.sh linkbox-main linkbox/signing password; echo "exit $?"'
run 'git add ci/vault-read.sh'
run 'git commit -q -m "the pipeline reads its secrets from Vault with an identity of its own"'

block pin
run 'git ls-remote https://github.com/aws-actions/configure-aws-credentials refs/tags/v6.3.0'

block cleanup
run 'docker rm -f vault'

block end
docker rm -f vault >/dev/null 2>&1
exit 0
