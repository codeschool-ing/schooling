---
title: Keys that expire within the hour
version: 1
---

**A key in `authorized_keys` is valid until somebody remembers to remove it.** That is the weakness
lesson 1 pointed at when it listed the key files on `web`: each line is a standing permission, it
carries no expiry date, and a person who leaves the firm keeps it until the line is found. Most
breaches that start with a stolen SSH key start with one that should have stopped working years
earlier.

**An SSH certificate is a key signed by an authority, with an expiry date and a list of names it may
log in as.** The server trusts the authority, not each key. So an administrator gets a certificate in
the morning, valid for the hours they need; it stops working on its own; and the server's
configuration never lists a person at all.

## The authority

The certificate authority is one more key pair. For the lab it lives on `admin`:

```
ana@admin:~$ ssh-keygen -q -t ed25519 -N "" -C "jatoba user CA" -f ~/user-ca; cat ~/user-ca.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN1M6z71F2vUOh+XHozQw0N0uet3KVSOd0dmFu/h2Br6 jatoba user CA
```

**In a real firm this key never lives on a workstation.** It is the key that can make anybody an
administrator of every server, so it is kept offline, in a hardware token or a dedicated signing
service, and the act of signing is itself logged. The lab keeps it in your home directory because
the lab has nowhere better, and the prose says so in order that nobody copies the shortcut.

## A certificate for an hour

Signing takes your existing public key and adds three things: an identity for the logs (`-I`), the
account names it may log in as (`-n`), and a validity period (`-V +1h`):

```
ana@admin:~$ ssh-keygen -s ~/user-ca -I ana@jatoba -n ana -V +1h ~/.ssh/id_ed25519.pub
Signed user key /home/ana/.ssh/id_ed25519-cert.pub: id "ana@jatoba" serial 0 for ana valid from 2026-10-23T08:40:00 to 2026-10-23T09:41:48
ana@admin:~$ ssh-keygen -L -f ~/.ssh/id_ed25519-cert.pub | sed -n "4,9p"
        Signing CA: ED25519 SHA256:cGACsyfksD/bNohootB5cxsSQnXiWRHRd0ZyB8Jxg/k (using ssh-ed25519)
        Key ID: "ana@jatoba"
        Serial: 0
        Valid: from 2026-10-23T08:40:00 to 2026-10-23T09:41:48
        Principals: 
                ana
```

`ssh-keygen -L` reads the certificate back. The `Principals` list is the important line: this
certificate may log in as `ana` and as nothing else, whatever account somebody asks for. The validity
starts a little before the moment of signing, so a server whose clock runs slightly behind does not
refuse it.

## A server that trusts the authority instead of the keys

`web` gets the authority's public key, and two lines that change how it decides who may log in:

```
root@web:~# echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN1M6z71F2vUOh+XHozQw0N0uet3KVSOd0dmFu/h2Br6 jatoba user CA' > /etc/ssh/user-ca.pub
root@web:~# cat > /etc/ssh/sshd_config.d/10-ca.conf <<'EOF'
TrustedUserCAKeys /etc/ssh/user-ca.pub
AuthorizedKeysFile none
PasswordAuthentication no
LogLevel VERBOSE
EOF
root@web:~# sshd -t && systemctl reload ssh; echo "exit $?"
exit 0
ana@admin:~$ ssh web hostname
web
```

`TrustedUserCAKeys` names the authority. `AuthorizedKeysFile none` switches off the old per-user key
files entirely, so a line someone adds to `authorized_keys` does nothing at all: on this server,
**the only way in is a certificate the authority signed**. The login through `jump` still works,
because `ssh` found the certificate beside your key and offered it.

## And when the hour is over

The demonstration does not wait an hour. It signs a certificate that was valid from two hours ago to
one hour ago, and offers it:

```
ana@admin:~$ ssh-keygen -s ~/user-ca -I ana@jatoba-yesterday -n ana -V -2h:-1h ~/.ssh/id_ed25519.pub
Signed user key /home/ana/.ssh/id_ed25519-cert.pub: id "ana@jatoba-yesterday" serial 0 for ana valid from 2026-10-23T06:41:49 to 2026-10-23T07:41:49
ana@admin:~$ ssh -o BatchMode=yes web hostname; echo "exit $?"
ana@web: Permission denied (publickey).
exit 255
```

Refused, with the same short answer a wrong key gets. Nobody had to remove anything from `web`.
Revocation still exists for a certificate stolen before it expires, `RevokedKeys` in the server's
configuration, but with a lifetime of an hour it is the exception rather than the routine.
