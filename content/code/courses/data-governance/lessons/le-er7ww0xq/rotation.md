---
title: Rotating a key without losing the data
version: 1
---

Keys are rotated for two reasons. **On a schedule**, because the longer a key is used the more
ciphertext depends on it and the larger the damage if it ever leaks; frameworks such as PCI DSS
ask for every key to have a defined lifetime. **On suspicion**, because a key that may have been exposed has
to stop being used today, without waiting for anybody to prove it was.

The naive rotation — new key, decrypt everything with the old, encrypt it with the new, delete the
old — needs every ciphertext rewritten at the moment of rotating, and a mistake halfway loses
data. Transit avoids that by giving a key **versions**:

```
ana@lab:~/gov$ bao write -f transit/keys/ipe-cpf/rotate
Key                       Value
---                       -----
allow_plaintext_backup    false
auto_rotate_period        0s
deletion_allowed          false
derived                   false
exportable                false
imported_key              false
keys                      map[1:1791343891 2:1791343893]
latest_version            2
min_available_version     0
min_decryption_version    1
min_encryption_version    0
name                      ipe-cpf
soft_deleted              false
supports_decryption       true
supports_derivation       true
supports_encryption       true
supports_signing          false
type                      aes256-gcm96
ana@lab:~/gov$ bao read -field=latest_version transit/keys/ipe-cpf; echo
2
ana@lab:~/gov$ bao write -field=ciphertext transit/encrypt/ipe-cpf plaintext=MzcyLjg3NC4xNjgtMDk=; echo
vault:v2:TAfnVYW24GxKtIwJRUyGpJ03xspQsVyKPrd0Ol8z08oye70Zk2zMUpVe
ana@lab:~/gov$ bao write -field=plaintext transit/decrypt/ipe-cpf ciphertext=$(cat cpf.ct) | base64 -d; echo
372.874.168-09
```

`latest_version` is now 2. **New encryptions use version 2**, and the ciphertext says so: it starts
`vault:v2:`. **Old ciphertext still decrypts**: the `v1` CPF in `cpf.ct`, made before the rotation,
came back unchanged. Nothing had to be rewritten for the rotation to take effect.

## Retiring the old version

A rotation on suspicion is not finished while version 1 still decrypts, and the old ciphertext can
be moved to the new version **without OpenBao ever showing it to anybody in clear**:

```
ana@lab:~/gov$ bao write -field=ciphertext transit/rewrap/ipe-cpf ciphertext=$(cat cpf.ct); echo
vault:v2:Txej4JhYdP1wS4HPaAMVtP92S66q0YB/z0TsZv+9+IDMMx9qxOwy4Z4+
ana@lab:~/gov$ bao write transit/keys/ipe-cpf/config min_decryption_version=2
Key                       Value
---                       -----
allow_plaintext_backup    false
auto_rotate_period        0s
deletion_allowed          false
derived                   false
exportable                false
imported_key              false
keys                      map[2:1791343893]
latest_version            2
min_available_version     0
min_decryption_version    2
min_encryption_version    0
name                      ipe-cpf
soft_deleted              false
supports_decryption       true
supports_derivation       true
supports_encryption       true
supports_signing          false
type                      aes256-gcm96
ana@lab:~/gov$ bao write transit/decrypt/ipe-cpf ciphertext=$(cat cpf.ct)
Error writing data to transit/decrypt/ipe-cpf: Error making API request.

URL: PUT https://bao.ipe.example:8200/v1/transit/decrypt/ipe-cpf
Code: 400. Errors:

* ciphertext or signature version is disallowed by policy (too old)
```

**`rewrap`** takes a `v1` ciphertext and returns the same plaintext encrypted as `v2`; the
plaintext exists only inside OpenBao for the duration of the call. A job that rewraps every
ciphertext in a table moves the data to the new version without the job, or its operator, being
able to read it — which is exactly the property a rotation after a suspected leak needs.

Then **`min_decryption_version=2`** retires version 1: the key's list now holds only version 2,
and the original `v1` ciphertext is refused as `too old`. Anything still encrypted with version 1
after that is unreadable, so the order is fixed: **rewrap first, raise the minimum after**, and
count the `v1:` ciphertexts left before raising it.

## In a schedule

Transit can rotate a key by itself (`auto_rotate_period` in the key's configuration), and the
cloud services all offer the same. Automatic rotation makes the new version; it does not rewrap,
and it does not retire old versions. Those two steps stay somebody's job, and the honest record of
a rotation policy is not "keys rotate yearly" but "keys rotate yearly, old versions are rewrapped
within a month and retired after".
