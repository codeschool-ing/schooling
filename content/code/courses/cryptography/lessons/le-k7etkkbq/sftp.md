---
title: SFTP, file transfer inside SSH
version: 1
---

**SFTP is not FTP with encryption added. It is a different protocol that runs inside an SSH
connection, and it inherits everything SSH does: an encrypted channel, a server that proves its
identity with a host key, and clients that can sign in with a key instead of a password.** FTPS, by
contrast, is the old FTP wrapped in TLS, with certificates and two connections. Both are
encrypted; SFTP is simpler to run through a firewall and is what most teams choose.

## Checking the server's key, the first time

SSH has no certificate authority by default. The first time a client meets a server, it receives
the server's **host key** and has to decide whether to trust it, which is the moment lesson 7 warned
about. The administrator of Vereda's file server publishes the key's fingerprint, computed from the
key itself:

```
ana@lab:~/lab$ ssh-keygen -lf keys/sftp_host_ed25519
256 SHA256:ab2RcbxsJtmnwtnW6lBA5u897l40ZxOUi/ikAg3jjfk  (ED25519)
```

Ana asks the server for its key and computes the same fingerprint from what came back:

```
ana@lab:~/lab$ ssh-keyscan -p 2222 files.vereda.example 2>/dev/null | ssh-keygen -lf -
256 SHA256:ab2RcbxsJtmnwtnW6lBA5u897l40ZxOUi/ikAg3jjfk [files.vereda.example]:2222 (ED25519)
```

They match, so the key the server presented is the one the administrator published, and Ana saves
it. From now on her client refuses the connection if the server ever presents another key:

```
ana@lab:~/lab$ ssh-keyscan -p 2222 files.vereda.example 2>/dev/null > known_hosts
```

This comparison is what `ssh` asks for when it prints *"The authenticity of host … can't be
established"*. Answering `yes` without comparing is trusting whoever answered. Teams with many
servers avoid the question altogether by distributing `known_hosts` entries through configuration
management, or by using SSH certificates signed by an internal CA, so that clients trust the CA
rather than each key.

## Signing in with a key

Ana's SFTP session signs in with her Ed25519 key from lesson 6. The server holds only her public key,
in `authorized_keys`, and no password exists for the account at all:

```
ana@lab:~/lab$ echo 'ls /etc/hostname' | sftp -b - -i keys/ana_ssh -P 2222 -o UserKnownHostsFile=known_hosts -o StrictHostKeyChecking=yes ana@files.vereda.example
sftp> ls /etc/hostname
/etc/hostname   
```

## What the connection negotiated

The verbose output of the same connection shows the choices, the SSH equivalent of lesson 10's
ServerHello:

```
ana@lab:~/lab$ ssh -v -i keys/ana_ssh -p 2222 -o UserKnownHostsFile=known_hosts -o StrictHostKeyChecking=yes ana@files.vereda.example true 2>&1 | grep -E 'kex: algorithm|kex: client->server|Server host key|matches|Authenticated to'
debug1: kex: algorithm: sntrup761x25519-sha512@openssh.com
debug1: kex: client->server cipher: chacha20-poly1305@openssh.com MAC: <implicit> compression: none
debug1: Server host key: ssh-ed25519 SHA256:ab2RcbxsJtmnwtnW6lBA5u897l40ZxOUi/ikAg3jjfk
debug1: Host '[files.vereda.example]:2222' is known and matches the ED25519 host key.
Authenticated to files.vereda.example ([127.0.0.1]:2222) using "publickey".
```

- `sntrup761x25519-sha512` is the **key exchange**: X25519 combined with Streamlined NTRU Prime, a
  post-quantum algorithm. OpenSSH has used this **hybrid** by default since version 9.0 in 2022, for
  exactly the harvest-now-decrypt-later reason of lesson 7;
- `chacha20-poly1305` is the **authenticated cipher** of lesson 1's final section, in its non-AES
  form;
- the **host key** fingerprint is checked against `known_hosts` and matches;
- `publickey` is how Ana was authenticated, with no password ever crossing the connection.
