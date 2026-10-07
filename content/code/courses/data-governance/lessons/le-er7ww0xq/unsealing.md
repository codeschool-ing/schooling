---
title: Sealed, unsealed, and the root token
version: 1
---

A sealed OpenBao has its data on disk and no way to read it: the root key is not in memory. Every
time the server starts — after a reboot, a crash, an upgrade — it starts sealed, and somebody has
to bring it shares. Two people, each with their own:

```
ana@lab:~/gov$ bao operator unseal
Unseal Key (will be hidden): 
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       3
Threshold          2
Unseal Progress    1/2
Unseal Nonce       48bbd00f-7b02-88dd-be2f-02e550815d84
Version            2.5.5
Build Date         2026-06-17T11:18:48Z
Storage Type       file
HA Enabled         false
ana@lab:~/gov$ bao operator unseal
Unseal Key (will be hidden): 
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    3
Threshold       2
Version         2.5.5
Build Date      2026-06-17T11:18:48Z
Storage Type    file
Cluster Name    vault-cluster-157cb233
Cluster ID      d58b45c1-7643-0109-4ba6-6620c5c9e101
HA Enabled      false
```

The share is read at a hidden prompt, so it does not end up in the shell's history. After the
first, `Unseal Progress` is `1/2`; after the second, `Sealed false`, and the server is serving.
Ana used shares 1 and 3. Which two does not matter — any two rebuild the same root key.

**Being sealed is the state OpenBao falls back to when anything is wrong**, and it can be put
there on purpose with `bao operator seal`: a suspected intrusion is answered by sealing the store,
after which nothing can be decrypted until two share holders agree to open it again. The price is
that a reboot at three in the morning needs two people awake. Production deployments trade that
for **auto-unseal**, where the root key is itself protected by a cloud KMS or a hardware module —
the same idea one level down, and the reason section 12 matters even to a team that runs OpenBao.

## The root token

```
ana@lab:~/gov$ bao login -no-print
Token (will be hidden): 
ana@lab:~/gov$ bao token lookup -format=json | python3 -c "import json, sys; d = json.load(sys.stdin)['data']; print(d['policies'], d['ttl'])"
['root'] 0
```

The token typed at the hidden prompt was the **initial root token** from the init output.
`-no-print` keeps the token off the screen, and the lookups say what it is: the `root` policy,
which allows everything, and a `ttl` of 0, which means it never expires.
Ana uses it for the next few minutes to set up the transit engine and the policies, because
something has to.

**A root token should not outlive the setup it was used for.** The production pattern is: use it
to create an administrators' policy and a way for administrators to log in through the company's
identity provider (lesson 1's single sign-on, again), then revoke it with
`bao token revoke -self`. If a root token is needed again, two share holders can generate a new
one with `bao operator generate-root`. That keeps "everything, for ever" out of anybody's
password manager. In the lab Ana keeps hers, because the lab is reset more often than it is
attacked — and the revocation command was not run here.
