---
title: Vault on your machine
version: 1
---

**HashiCorp Vault is a server whose whole job is to hold secrets and decide who may read them.** It
stores them encrypted, hands each one out only to a caller that proved who it is and holds a policy
allowing it, and records every request. It can also make secrets up on demand, a database password
that exists for an hour, which lesson 11 uses. Here it runs in a container beside the cluster, the
way the registry and Gitea do.

The command-line client is a zip from HashiCorp's release site, with a checksum file beside it:

```
ana@laptop:~/setup$ curl -fsSLO https://releases.hashicorp.com/vault/2.1.2/vault_2.1.2_linux_$ARCH.zip
ana@laptop:~/setup$ curl -fsSL https://releases.hashicorp.com/vault/2.1.2/vault_2.1.2_SHA256SUMS | grep " vault_2.1.2_linux_$ARCH.zip$" | sha256sum --check
vault_2.1.2_linux_amd64.zip: OK
ana@laptop:~/setup$ unzip -q vault_2.1.2_linux_$ARCH.zip vault && sudo install -m 0755 vault /usr/local/bin/ && rm vault vault_2.1.2_linux_$ARCH.zip
ana@laptop:~/setup$ vault version
Vault v2.1.2 (76fdd6587523c4c6cb079635075e019714d23470), built 2026-10-06T15:17:37Z
```

## Not the dev server

Vault has a **dev mode**, `vault server -dev`, and most tutorials start there: one command, already
unsealed, a root token printed on the screen, everything kept in memory. It is a fine way to try a
command and a poor way to learn Vault, because it skips the two things that make Vault what it is:
storage that survives a restart, and a **seal**. This lab runs the real server with a small
configuration. Save this as `~/vault/vault.hcl`:

```hcl
storage "raft" {
  path    = "/vault/file"
  node_id = "vault-1"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true
}

api_addr      = "http://127.0.0.1:8200"
cluster_addr  = "http://127.0.0.1:8201"
disable_mlock = true
```

`raft` is Vault's own storage, kept in a volume so it survives the container. `tls_disable` is for
this laptop only, where the listener answers on `127.0.0.1` and on the cluster's Docker network; on
anything shared, Vault speaks TLS and nothing else. `disable_mlock` is what HashiCorp recommends
with `raft` storage, whose memory-mapped files do not mix well with locking memory.

The container joins the `kind` network, so that the cluster can reach it as `vault`, the way it
reaches `registry` and `gitea`:

```
ana@laptop:~$ docker run -d --name vault --network kind -p 127.0.0.1:8200:8200 -v ~/vault:/vault/config:ro -v vault-data:/vault/file hashicorp/vault:2.1.2 server
2214e313b639bb282002c8ca632fc7031d6d968a1c5c010708d20ee383ebd70f
ana@laptop:~$ export VAULT_ADDR=http://127.0.0.1:8200
ana@laptop:~$ vault status
Key                     Value
---                     -----
Seal Type               shamir
Initialized             false
Sealed                  true
Total Shares            0
Threshold               0
Unseal Progress         0/0
Unseal Nonce            n/a
Version                 2.1.2
Build Date              2026-10-06T15:17:37Z
Storage Type            raft
Removed From Cluster    false
HA Enabled              true
```

`Initialized false`, `Sealed true`: a server that has never been set up and cannot read its own
storage. The exit code of `vault status` says the same, `2` for sealed, which a script can test.

## Initialised, then unsealed

**Vault encrypts everything it stores with a key it does not keep on disk.** Initialising makes that
key and splits the key that protects it into **unseal keys**; starting the server leaves it
**sealed**, unable to read its own storage, until enough unseal keys are presented. In production
there are five unseal keys held by five people and any three open it, or a cloud key service unseals
it automatically. Here one key is enough, and it goes in a file only you can read, together with the
**root token**, which can do anything:

```
ana@laptop:~$ vault operator init -key-shares=1 -key-threshold=1 -format=json > ~/vault-init.json && chmod 600 ~/vault-init.json
ana@laptop:~$ jq -c keys ~/vault-init.json
["recovery_keys_b64","recovery_keys_hex","recovery_keys_shares","recovery_keys_threshold","root_token","unseal_keys_b64","unseal_keys_hex","unseal_shares","unseal_threshold"]
ana@laptop:~$ vault operator unseal $(jq -r '.unseal_keys_b64[0]' ~/vault-init.json) | grep -E '^(Initialized|Sealed)'
Initialized             true
Sealed                  false
```

The file holds the unseal keys, the root token and their recovery counterparts, and `jq -c keys`
shows its shape without printing any of them. One key unsealed it: `Sealed false`.

## A secret, and a restart

Vault's key-value engine keeps versioned secrets under paths. It is enabled once, at `secret/`:

```
ana@laptop:~$ export VAULT_TOKEN=$(jq -r .root_token ~/vault-init.json)
ana@laptop:~$ vault secrets enable -path=secret kv-v2
Success! Enabled the kv-v2 secrets engine at: secret/
ana@laptop:~$ vault kv put secret/bulletin/staging token=$(openssl rand -hex 16) >/dev/null
ana@laptop:~$ vault kv put secret/bulletin/production token=$(openssl rand -hex 16)
========= Secret Path =========
secret/data/bulletin/production

======= Metadata =======
Key                Value
---                -----
created_time       2026-10-16T00:49:25.786557741Z
custom_metadata    <nil>
deletion_time      n/a
destroyed          false
version            1
ana@laptop:~$ vault kv get -field=token secret/bulletin/production | sha256sum | cut -c1-12
94054ba47262
```

Version 1 of `bulletin/production`, written at the time Vault prints; every later write is a new
version, and the old ones stay readable until somebody destroys them. The fingerprint is the one
production's pods will print once lesson 10 reads it from here.

Now the property that dev mode hides. Restart the container, as a reboot of the laptop would:

```
ana@laptop:~$ docker restart vault
vault
ana@laptop:~$ vault status | grep -E '^(Initialized|Sealed)'
Initialized             true
Sealed                  true
ana@laptop:~$ vault kv get secret/bulletin/production
Error making API request.

URL: GET http://127.0.0.1:8200/v1/sys/internal/ui/mounts/secret/bulletin/production
Code: 503. Errors:

* Vault is sealed
ana@laptop:~$ vault operator unseal $(jq -r '.unseal_keys_b64[0]' ~/vault-init.json) | grep '^Sealed'
Sealed                  false
```

**After every restart Vault is sealed, and nothing can read a secret until somebody unseals it.**
That is the price of a secret store that does not keep its own key next to its data, and the reason
the real deployments use automatic unsealing with a cloud key service: a sealed Vault at three in
the morning is an outage for everything that depends on it. The root token is for setting Vault up;
after that, people and programs get tokens of their own, with policies that allow what they need.
The next section gives one to the cluster.
