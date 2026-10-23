---
title: A policy that reads one path, and a token that dies
version: 1
---

Two of the three narrowings are Vault's everyday tools. **A policy says what a token may do, and a
token's time to live says for how long.** Both are shown here with a token made by hand; the next
two sections replace the hand with the pipeline's own identity.

### The policy

Vault refuses everything a policy does not grant, so a policy is a list of what is allowed and
nothing else. The pipeline on `main` needs to read one value, the signing password, and the policy
says exactly that. It belongs to whoever runs Vault rather than to the project, so it lives beside
the CI server's other files. Save it as `~/ci/vault/linkbox-sign.hcl`:

```hcl
# What a run of linkbox's pipeline on main may do in Vault: read the
# password of the signing key. Not list the secrets beside it, not write
# this one, not read any other path.
path "secret/data/linkbox/signing" {
  capabilities = ["read"]
}
```

The path is the API path from the previous section, with `data/` in it. **Capabilities are verbs**:
`read`, `create`, `update`, `delete` and `list` are the ones a key/value store uses, and `sudo` and
`deny` are the two that change how the others apply. A policy that granted `list` on
`secret/metadata/linkbox/` would let the pipeline see the names of every secret beside this one,
which is already more than it needs. A path may end in `*` to match everything below it, and that
asterisk is where most over-broad policies come from: `secret/data/linkbox/*` reads like "linkbox's
secrets" and grants every secret any later team adds under that name.

Load it into Vault, and make a token that carries it and lives thirty seconds:

```
ana@vm:~/linkbox$ vault policy write linkbox-sign - <~/ci/vault/linkbox-sign.hcl
Success! Uploaded policy: linkbox-sign
ana@vm:~/linkbox$ t=$(vault token create -policy=linkbox-sign -ttl=30s -field=token)
ana@vm:~/linkbox$ vault token lookup "$t" | grep -E "^(policies|ttl) "
policies            [default linkbox-sign]
ttl                 29s
```

`vault token create` prints a table by default; `-field=token` prints only the token, which goes
into the shell variable `t` and never onto the screen. The lookup confirms two things. The token
carries `linkbox-sign` and also `default`, a policy every token gets, which lets a token look itself
up and renew or revoke itself. And it has 29 seconds left, because a second passed between making it
and asking.

### Using it the way a pipeline would

From here the commands are the pipeline's side, so they use `curl` against Vault's HTTP API rather
than the root-powered `vault` function. `VAULT_ADDR` in your shell is the address the pipeline would
be given. Read the password's key names, then try a path the policy does not name, then try to
write:

```
ana@vm:~/linkbox$ export VAULT_ADDR=http://127.0.0.1:8200
ana@vm:~/linkbox$ curl -s -H "X-Vault-Token: $t" $VAULT_ADDR/v1/secret/data/linkbox/signing | jq -c ".data.data | keys"
["password"]
ana@vm:~/linkbox$ curl -s -H "X-Vault-Token: $t" $VAULT_ADDR/v1/secret/data/linkbox/registry | jq -c
{"errors":["1 error occurred:\n\t* permission denied\n\n"]}
ana@vm:~/linkbox$ curl -s -H "X-Vault-Token: $t" --data "{\"data\": {\"password\": \"x\"}}" $VAULT_ADDR/v1/secret/data/linkbox/signing | jq -c
{"errors":["1 error occurred:\n\t* permission denied\n\n"]}
```

The read answers `["password"]`, the names of the fields at that path, and nothing about their
values: asking `jq` for the keys is how to check a read worked without printing a secret. The other
path and the write both answer **permission denied**. Vault does not say whether
`secret/data/linkbox/registry` exists, and that is on purpose: a token that could tell a missing
secret from a forbidden one could map what it is not allowed to read.

### Watching it die

The token was made with thirty seconds to live. Wait that long and try the read that worked:

```
ana@vm:~/linkbox$ sleep 30
ana@vm:~/linkbox$ curl -s -H "X-Vault-Token: $t" $VAULT_ADDR/v1/secret/data/linkbox/signing | jq -c
{"errors":["2 errors occurred:\n\t* permission denied\n\t* invalid token\n\n"]}
```

The same request, the same path, refused, and this time with a second reason: **invalid token**.
Vault forgets an expired token, so for the server it no longer exists. Nobody revoked anything and
no job had to remember to clean up. A token leaked in a log at second 10 is worthless at second 31.

A token's life has two limits in Vault. The **TTL** is how long it lives unless it is renewed, and
the **maximum TTL** is the ceiling renewals cannot pass. A token that a job renews every few minutes
can outlive the job if nothing stops it, so a CI token wants a maximum close to the length of a run.
The role in two sections' time sets both to five minutes.

### What this solved, and what it did not

Two of the three questions now have narrow answers. **What**: one path, read only. **How long**:
thirty seconds here, five minutes for the pipeline. The third, **who**, is untouched, and it is
the expensive one. To use this token a run needs to be handed it, which means somebody or something
with the root token, or with a long-lived token allowed to create tokens, sits on the CI server
making them. That long-lived token is the password from the first section with a new name.

**A short-lived credential is only as good as the way it is obtained.** If obtaining it needs a
long-lived secret, the short life is decoration. The next section removes that secret by changing
what the pipeline presents: not something it holds, but a statement about what it is, signed by the
CI server.
