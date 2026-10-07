---
title: The transit engine
version: 1
---

OpenBao does several jobs, each in an engine mounted at a path. The one that turns it into a
key-management service is **transit**: it holds keys, and offers encrypt, decrypt and a few more
operations on data that passes through it and is never stored. The name says it: the data is in
transit through the service, not at rest in it.

```
ana@lab:~/gov$ bao secrets enable transit
Success! Enabled the transit secrets engine at: transit/
ana@lab:~/gov$ bao write -f transit/keys/ipe-cpf
Key                       Value
---                       -----
allow_plaintext_backup    false
auto_rotate_period        0s
deletion_allowed          false
derived                   false
exportable                false
imported_key              false
keys                      map[1:1791343891]
latest_version            1
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
```

`ipe-cpf` is a key for one purpose, the CPF. The output is its configuration, and four lines of
it are decisions:

- **`type aes256-gcm96`** — AES with a 256-bit key in GCM mode, which encrypts and authenticates:
  a ciphertext altered in transit fails to decrypt instead of decrypting to garbage;
- **`exportable false`** — the key can never be read out of OpenBao, by anybody, root included;
- **`deletion_allowed false`** — the key cannot be deleted until somebody changes this first,
  which section 13 does on purpose to a different key;
- **`latest_version 1`** and **`min_decryption_version 1`** — the key has versions, and section
  10 adds one.

One key per purpose is the habit worth forming here. A key for the CPF, another for backups,
another per customer when the purpose requires it (section 13): the permissions, the rotation and
the deletion of each can then follow its own purpose.

## Encrypting and decrypting

Transit takes plaintext as base64, because it may be any bytes and not only text:

```
ana@lab:~/gov$ printf '372.874.168-09' | base64
MzcyLjg3NC4xNjgtMDk=
ana@lab:~/gov$ bao write -field=ciphertext transit/encrypt/ipe-cpf plaintext=MzcyLjg3NC4xNjgtMDk= > cpf.ct
ana@lab:~/gov$ cat cpf.ct; echo
vault:v1:t+QDwmezRheG3+m55XNJSVWHooTcFCNurwlvKNddUqWUAGnvTK1DTk7Z
ana@lab:~/gov$ bao write -field=plaintext transit/decrypt/ipe-cpf ciphertext=$(cat cpf.ct) | base64 -d; echo
372.874.168-09
```

The ciphertext is a string with three parts: **`vault`**, a fixed prefix; **`v1`**, the version
of the key that made it; and the encrypted bytes, which include a random nonce, so encrypting the
same CPF twice gives two different strings. Ana stored it in a file and handed it back, and the
CPF came out. At no point did the key appear on her screen, in her shell or on her disk.

That is the whole interface, and it is enough to build everything else in this lesson. What makes
it safe is not the interface but who may call which half of it.
