---
title: Vault trusts the CI, and a role decides which runs
version: 1
---

Vault checks identity tokens with its **JWT authentication method**. It has two layers, and the
difference between them is where this whole lesson's safety sits. **The method's configuration says
whose signature to believe. A role says which of the believed tokens get which policy.** A token
signed by the right key gets nothing on its own; it has to match a role.

### Trusting the CI server's key

Enable the method and give it the public key and the issuer name `mint.py` signs as:

@@CAPTURE jwt-config@@

`jwt_validation_pubkeys` is the simplest way to tell Vault whose signatures to believe: paste the
public key. `bound_issuer` makes Vault refuse a token whose `iss` claim is anything else, which
matters the day the same key, or a key in the same list, signs for something else.

### A role that checks too little

The first role is the one that is easy to write and wrong. It checks that the token is for Vault
and nothing about the run, and it attaches the signing policy:

@@CAPTURE broad@@

**A run of a branch called `try-something` logged in and got the policy that reads the signing
password.** Nothing about the token is forged: the CI server signed it, it is for Vault, it is
current. That is precisely the problem. The role trusted every token the CI server will ever sign,
and the CI server signs one for every branch anybody pushes, so this role hands the password to every
branch, exactly like the file it was meant to replace. The same mistake on a hosted service is worse,
because there the issuer signs for every repository of every customer; the last section of the
lesson comes back to it.

The defect is in the role, so the fix is a role that checks the run. Delete this one before going on,
as the capture does: a role nobody uses is still a way in.

### A role bound to main

Save the role as `~/ci/vault/linkbox-main.json`:

```json
{
  "role_type": "jwt",
  "bound_audiences": ["vault"],
  "bound_claims": {
    "repository": "ana/linkbox",
    "ref": "refs/heads/main"
  },
  "user_claim": "sub",
  "token_policies": ["linkbox-sign"],
  "token_ttl": "5m",
  "token_max_ttl": "5m"
}
```

`bound_claims` is the line the first role lacked: **every claim listed must equal the value given**,
or the login is refused. `user_claim` names the claim Vault records as who logged in, so its audit
log says `repo:ana/linkbox:ref:refs/heads/main` rather than a token number. And `token_ttl` with
`token_max_ttl` give the Vault token the same five minutes as the identity token, with no renewing
past them. Load it, then log in with the `main` token minted in the previous section and with the
`try-something` one:

@@CAPTURE bound@@

`main` gets the policy for 300 seconds. `try-something` is refused, and **the error names the claim
that failed**, which is what you want from a refusal you will one day read in a CI log: not "denied"
but which condition did not hold.

### Every check, refused once

Two more tokens show the checks that came before the role's. One is minted for a different
audience, as a token meant for the registry would be. The other is signed by a key Vault has never
seen:

@@CAPTURE others@@

Each is refused at a different step, and the figure puts the four in order. The audience check is
what stops a token issued for one service being replayed against another: a registry that received
a token could otherwise use it to log in to Vault. The signature check is the foundation of the rest,
because everything after it reads claims that only the signature makes trustworthy.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 192\" role=\"img\" data-fig=\"sp-l17-checks\" aria-label=\"The checks Vault makes on an identity token before it hands back a Vault token, in order: the signature against the public key it trusts, then the issuer, then the audience, then the claims the role binds, repository and ref. Each check has the token from this lesson that it refused: one signed by a stranger's key, one minted for the registry, and one for the branch try-something. A token that passes all four gets a Vault token with the policy linkbox-sign for five minutes, which reads one path.\"><defs><marker id=\"sp-l17-checks-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l17-checks-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"8\" y=\"40\" width=\"112\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"64.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a login</text><text x=\"64.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">role + JWT</text><path d=\"M120 68 L130 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l17-checks-ah-phosphor)\"></path><rect x=\"132\" y=\"40\" width=\"100\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"182.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">signature</text><text x=\"182.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">a trusted key?</text><path d=\"M182 96 L182 136\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l17-checks-ah-amber)\"></path><rect x=\"132\" y=\"138\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"182.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">a stranger's key</text><path d=\"M232 68 L242 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l17-checks-ah-phosphor)\"></path><rect x=\"244\" y=\"40\" width=\"100\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"294.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">issuer</text><text x=\"294.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">bound_issuer</text><path d=\"M344 68 L354 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l17-checks-ah-phosphor)\"></path><rect x=\"356\" y=\"40\" width=\"100\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"406.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">audience</text><text x=\"406.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">bound_audiences</text><path d=\"M406 96 L406 136\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l17-checks-ah-amber)\"></path><rect x=\"356\" y=\"138\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"406.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">minted for registry</text><path d=\"M456 68 L466 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l17-checks-ah-phosphor)\"></path><rect x=\"468\" y=\"40\" width=\"100\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"518.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">claims</text><text x=\"518.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">bound_claims</text><path d=\"M518 96 L518 136\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l17-checks-ah-amber)\"></path><rect x=\"468\" y=\"138\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"518.0\" y=\"156.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">try-something</text><text x=\"64\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">refused here</text><path d=\"M568 68 L586 68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l17-checks-ah-phosphor)\"></path><rect x=\"588\" y=\"40\" width=\"126\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"651.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Vault token</text><text x=\"651.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">linkbox-sign, 5 minutes</text></svg>", "caption": "Four checks, each with the token of this lesson that it stopped. Only the last one knows anything about linkbox's branches."}
```

One thing the captures do not refuse is worth noticing. The `main` token logged in once in the
previous capture and is used again below, and Vault accepts it both times. **An identity token is a
bearer token for its five minutes**: whoever holds it can use it, as often as they like, until `exp`.
The short life is what limits a stolen one, and it is why a log must never print the token even
though it holds no secret.

### The pipeline's side

What remains is the few lines a pipeline stage runs: exchange the identity token for a Vault token,
read one field, and give the Vault token back. Save it as `ci/vault-read.sh`:

```sh
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
```

`jq -n` builds the login request, so a token with an odd character in it cannot break the JSON.
`jq -e` exits with an error when the field is missing, which makes the script **fail closed**: a
refused login or a refused read stops the stage with Vault's own message, instead of handing the
next command an empty password. The `trap` revokes the Vault token as soon as the script ends,
successful or not, so the five minutes are a ceiling and not the usual life.

Run it as the CI server would for a run of `main`, and for a run of `try-something`:

@@CAPTURE script@@

The `main` run reads a value equal to the file on the CI server's disk, and the comparison says so
without printing it. The `try-something` run stops with exit status 1 and the reason. Commit the
script; the pre-commit hook from lesson 6 scans the change for secrets on the way in and finds none,
because there are none in it.

### What a real CI server would change, and why this one does not

On a CI server wired for this, the hook would mint a token for each run and pass it in. The lines
below were not run in this course. In lesson 1's hook, the line that starts the pipeline would gain
one variable:

```sh
  if CI_ID_TOKEN=$(python3 ~/ci/oidc/mint.py "$ref") \
      CI_COMMIT=${new:0:7} CI_BRANCH=${ref#refs/heads/} CI_LOGS=$run/logs \
      "$run/src/ci/pipeline.sh"; then
```

and `ci/sign.sh` would take its password from Vault instead of the file:

```sh
COSIGN_PASSWORD=$(bash ci/vault-read.sh linkbox-main linkbox/signing password)
```

after which the file in `~/ci/keys` could be deleted, and a branch that changed `sign.sh` to print the
password would find there was nothing to print. **This course's pipeline keeps reading the file**, and
the hook stays as lesson 1 wrote it. The reason is the dev-mode server: it lives as long as its
container and forgets everything when it stops, so a pipeline that depended on it would break the
first time the machine restarted. Lessons 18 to 20 keep pushing to the CI server, and they need it to
work with no Vault running. On a production Vault the two lines above are the whole change.
