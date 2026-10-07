---
title: Who may use a key, and for what
version: 1
---

Ana's root token can do anything with `ipe-cpf`. The website and support each need one thing,
and the point of a key-management service is that each can be given exactly that. OpenBao
expresses it as **policies**: a path, and the capabilities allowed on it.

```hcl
# The website encrypts a CPF when a customer signs up, and never reads one.
path "transit/encrypt/ipe-cpf" {
  capabilities = ["update"]
}
```

```hcl
# Support decrypts a CPF to confirm who is calling, and never encrypts.
path "transit/decrypt/ipe-cpf" {
  capabilities = ["update"]
}
```

Encrypting is a write to `transit/encrypt/ipe-cpf`, decrypting is a write to
`transit/decrypt/ipe-cpf`; both are the capability `update`. Each policy names one path. Nothing
in either mentions the key's configuration, its rotation, or any other key.

```
ana@lab:~/gov$ bao policy write site-app site-app.hcl
Success! Uploaded policy: site-app
ana@lab:~/gov$ bao policy write support support.hcl
Success! Uploaded policy: support
ana@lab:~/gov$ bao token create -policy=site-app -ttl=1h -field=token > site-app.token && wc -c site-app.token
26 site-app.token
ana@lab:~/gov$ bao token create -policy=support -ttl=1h -field=token > support.token && wc -c support.token
26 support.token
```

Each policy is attached to a **token** that expires in an hour. In the lab the tokens go in files,
counted with `wc` rather than printed. In production each program would get its token by logging in
to OpenBao with an identity of its own — a Kubernetes service account, a cloud instance's identity,
a certificate like `etl_loader`'s — and the token would never be written to a disk.

## The policies, tested

```
ana@lab:~/gov$ BAO_TOKEN=$(cat site-app.token) bao write -field=ciphertext transit/encrypt/ipe-cpf plaintext=MzcyLjg3NC4xNjgtMDk=; echo
vault:v1:u1P2QlncpgSzGvzSuNmTdKM7rQLM/PLQoxG116HwsHNKckNx9XvsRwOw
ana@lab:~/gov$ BAO_TOKEN=$(cat site-app.token) bao write transit/decrypt/ipe-cpf ciphertext=$(cat cpf.ct)
Error writing data to transit/decrypt/ipe-cpf: Error making API request.

URL: PUT https://bao.ipe.example:8200/v1/transit/decrypt/ipe-cpf
Code: 403. Errors:

* 1 error occurred:
	* permission denied


ana@lab:~/gov$ BAO_TOKEN=$(cat support.token) bao write -field=plaintext transit/decrypt/ipe-cpf ciphertext=$(cat cpf.ct) | base64 -d; echo
372.874.168-09
ana@lab:~/gov$ BAO_TOKEN=$(cat support.token) bao read transit/keys/ipe-cpf
Error reading transit/keys/ipe-cpf: Error making API request.

URL: GET https://bao.ipe.example:8200/v1/transit/keys/ipe-cpf
Code: 403. Errors:

* 1 error occurred:
	* permission denied
```

Four requests, four answers that each say something:

1. **The website encrypts.** That is what its policy allows.
2. **The website cannot decrypt** — `403 permission denied` — not even the ciphertext Ana made a
   minute earlier with the same key. Whoever steals the website's token can add encrypted CPFs to
   the database and cannot read one.
3. **Support decrypts.** The CPF comes out, for the agent who is confirming a caller's identity.
4. **Support cannot read the key's configuration.** It may use the key and nothing else.

That separation is what lesson 2's jobs did for tables, applied to a key. And it was not possible
in lesson 3: with pgcrypto, whoever could decrypt also held the key, and whoever held the key could
both encrypt and decrypt everything, for ever.
