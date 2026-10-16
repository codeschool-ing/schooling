---
title: When it fails
version: 1
---

Each tool in this lesson fails closed: without the right key or the right identity, nothing is
decrypted and nothing is handed out. That is the property worth having, and it means the failures
look like refusals. Two more, beside the copied seal, the strict check and the sealed Vault met
already.

**A teammate without the key.** Somebody clones `fleet` and tries to read production's token. Their
machine has no age key in the place SOPS looks:

```
ana@laptop:~/fleet$ HOME=/tmp sops --decrypt apps/bulletin/production/token.sops.yaml
Failed to get the data key required to decrypt the SOPS file.

Group 0: FAILED
  age16890kj8h7350f8d3nah8fk9s67ert0uqasr3ydumddk00fqv93jsxqsenx: FAILED
    - | failed to load age identities. Did not find keys in
      | locations 'SOPS_AGE_SSH_PRIVATE_KEY_FILE',
      | 'SOPS_AGE_SSH_PRIVATE_KEY_CMD', '/tmp/.ssh/id_ed25519',
      | '/tmp/.ssh/id_rsa', 'SOPS_AGE_KEY', 'SOPS_AGE_KEY_FILE',
      | 'SOPS_AGE_KEY_CMD', and '/tmp/.config/sops/age/keys.txt'.

Recovery failed because no master key was able to decrypt the file. In
order for SOPS to recover the file, at least one key has to be successful,
but none were.
```

SOPS lists every place it looked for an age key and found none, and refuses. **There is no partial
answer**: without a key that opens the data key, the file is ciphertext.

**A pod from the wrong namespace.** A ServiceAccount token from staging, presented to the role made
for production:

```
ana@laptop:~$ vault write auth/kubernetes/login role=bulletin-production jwt=$(kubectl -n staging create token default)
Error writing data to auth/kubernetes/login: Error making API request.

URL: PUT http://127.0.0.1:8200/v1/auth/kubernetes/login
Code: 403. Errors:

* service account name not authorized
```

`service account name not authorized`: the token is genuine, and the API server said so, but the
role names `bulletin` in `production`, and this is `default` in `staging`.

| what you see | where | what it means |
|---|---|---|
| `ErrUnsealFailed` | the SealedSecret's events | a seal used under a name or namespace it was not made for |
| `additional properties 'sops' not allowed` | `validate.sh` | the `sops` block reached a strict schema check |
| `Failed to get the data key` | `sops --decrypt` | no key on this machine can open the file |
| `Vault is sealed`, code 503 | any Vault command | Vault restarted and nobody unsealed it |
| `service account name not authorized` | a Vault login | the ServiceAccount or namespace is not the one the role names |

**A missing key is not a bug to work around.** Each of these is the system doing its job, and the
answer is never to widen it until the error goes away: a seal made cluster-wide, a role bound to
every namespace, a CI given the age key "just to validate". Every widening is a new set of people or
programs that can read the secret, and none of them shows up in a diff as a secret.
