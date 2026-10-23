# One field of one secret, read from Vault with the identity this run was
# given. The CI server mints that identity for the branch it is building and
# hands it over in CI_ID_TOKEN; Vault decides from its claims whether this
# run may have the secret at all. Nothing in this file is a credential, and
# the Vault token it gets is revoked when the script ends.
#
#   ci/vault-read.sh ROLE SECRET FIELD
set -euo pipefail
vault=${VAULT_ADDR:-http://127.0.0.1:8200}
fail() { jq -r '.errors[]?' <<<"$1" >&2; exit 1; }
login=$(curl -s --data "$(jq -n --arg role "$1" --arg jwt "$CI_ID_TOKEN" '{$role, $jwt}')" \
  "$vault/v1/auth/jwt/login")
token=$(jq -er .auth.client_token <<<"$login") || fail "$login"
trap 'curl -s -X POST -H "X-Vault-Token: $token" "$vault/v1/auth/token/revoke-self"' EXIT
secret=$(curl -s -H "X-Vault-Token: $token" "$vault/v1/secret/data/$2")
jq -er --arg field "$3" '.data.data[$field]' <<<"$secret" || fail "$secret"
