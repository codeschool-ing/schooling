---
title: Starting OpenBao
version: 1
---

OpenBao is one binary. Ana downloads the release this course was recorded with, **checks it
against the SHA-256 the project publishes** — a key-management server is the last program to run
without knowing where it came from — and installs it. It runs as a user of its own, with its data,
its configuration and its log in three directories, and it gets the certificate lesson 3 issued
for `bao.ipe.example`. The last command opens an editor for the configuration:

```sh
curl -fsSLO https://github.com/openbao/openbao/releases/download/v2.5.5/bao_2.5.5_Linux_x86_64.tar.gz
echo "2c5577707e97fc95c2086950f39880ead5e45b356c94388e5cb606f5a5c2b697  bao_2.5.5_Linux_x86_64.tar.gz" | sha256sum -c
tar -xzf bao_2.5.5_Linux_x86_64.tar.gz bao
sudo install -m 0755 bao /usr/local/bin/bao
rm bao bao_2.5.5_Linux_x86_64.tar.gz
sudo useradd --system --home /var/lib/bao --shell /usr/sbin/nologin bao
sudo mkdir -p /etc/bao /var/lib/bao/data /var/log/bao
sudo chown -R bao:bao /var/lib/bao /var/log/bao
sudo install -m 0644 -o bao -g bao /etc/ipe-pki/bao.crt /etc/bao/bao.crt
sudo install -m 0600 -o bao -g bao /etc/ipe-pki/bao.key /etc/bao/bao.key
sudo nano /etc/bao/bao.hcl
```

On a machine whose processor is ARM rather than x86-64, the release page lists the file for it, with
its own checksum. The configuration is short:

```
ana@lab:~/gov$ cat /etc/bao/bao.hcl
# OpenBao for the lab: one node, its data in a directory, TLS on the
# listener with the lab CA's certificate for bao.ipe.example.
storage "file" {
  path = "/var/lib/bao/data"
}
listener "tcp" {
  address       = "127.0.0.1:8200"
  tls_cert_file = "/etc/bao/bao.crt"
  tls_key_file  = "/etc/bao/bao.key"
}
api_addr      = "https://bao.ipe.example:8200"
ui            = false

# Every request and every response, written to a file. OpenBao takes audit
# devices from this file and refuses to create them through its API.
audit "file" "to-file" {
  options {
    file_path = "/var/log/bao/audit.log"
  }
}
```

Four decisions are in it. **Storage is a directory**, `/var/lib/bao/data`, which is fine for one
machine and a lab; a production cluster uses OpenBao's integrated storage replicated across
several nodes. **The listener speaks TLS** with a certificate from the same lab CA as the
database, for the name `bao.ipe.example`, so every client checks it the way lesson 3 taught.
**`api_addr`** is the address clients are told to use. And **every request and response goes to
an audit file**, declared here because this version of OpenBao takes audit devices from its
configuration file only: what is audited is part of the file a reviewer reads, not a setting
somebody with a token can change.

Ana starts the server as the user `bao`, in the background, and tells her own shell where it is
and which CA to trust. `BAO_CLI_NO_COLOR` keeps colour codes out of the output, which is how the
transcripts read:

```sh
sudo -u bao sh -c 'nohup bao server -config=/etc/bao/bao.hcl >> /var/log/bao/server.log 2>&1 &'
echo 'export BAO_ADDR=https://bao.ipe.example:8200 BAO_CACERT=/etc/ipe-pki/ca.crt BAO_CLI_NO_COLOR=1' >> ~/.bashrc
source ~/.bashrc
```

A systemd unit would start it on every boot; started by hand, it has to be started again after a
reboot, and unsealed again too, as the next section shows. It answers, and says it is not ready:

```
ana@lab:~/gov$ bao status
Key                Value
---                -----
Seal Type          shamir
Initialized        false
Sealed             true
Total Shares       0
Threshold          0
Unseal Progress    0/0
Unseal Nonce       n/a
Version            2.5.5
Build Date         2026-06-17T11:18:48Z
Storage Type       file
HA Enabled         false
```

**`Initialized false`, `Sealed true`.** It has no keys of its own yet, and it would not use them if
it had.

## Initialising: the key that protects the keys

Everything OpenBao stores — the transit keys, the policies, the tokens — is encrypted on disk with
a **root key**. Initialising creates that root key and immediately splits it:

```
ana@lab:~/gov$ bao operator init -key-shares=3 -key-threshold=2 | tee init.txt
Unseal Key 1: ww4p5g5yMarTi+uQqj/RFvlLb9iiPVgowyHdGRnrv8ku
Unseal Key 2: p8/iqwHalb0j8A8icSj7LSg49v4L9kc8gmbdJvYchQTq
Unseal Key 3: gL6lUyyvxNjFioURRk0tjCl6FAx5sRpQXqjdm03vI1GA

Initial Root Token: s.qM3mk84dD0pyHn59xIaDH4h4

Vault initialized with 3 key shares and a key threshold of 2. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 2 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated root key. Without at least 2 keys to
reconstruct the root key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum
of existing unseal keys shares. See "bao operator rotate-keys" for more
information.
```

The root key was cut into **three shares, any two of which can rebuild it**. That is Shamir's
secret sharing, and the point of it is the line under the keys: OpenBao does not keep the root
key. It exists only while it is being rebuilt from shares. The messages still say "Vault", an
inheritance from the project OpenBao forked.

**The three shares are printed here because this lab is thrown away when it is reset.** In a real
deployment each share goes to a different person, each person stores theirs somewhere the others
cannot reach, and nobody — including whoever ran this command — keeps all three. A threshold of
two means one person can be on holiday and one share can be lost without locking the company out,
and no single person can open the store alone.

The **initial root token** is the other thing on the screen, and the next section is about why it
should exist for as short a time as possible.
