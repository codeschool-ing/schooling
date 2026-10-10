---
title: A key pair of your own
version: 1
---

**`cosign` is the tool this lesson signs and verifies with.** It belongs to Sigstore, an open project
under the Linux Foundation, and it stores a signature in the registry beside the image it signs, so
nothing new has to be run to hold them. It installs like every tool in this course, the binary and
the checksum file from the release page:

```
ana@laptop:~/setup$ ARCH=$(dpkg --print-architecture)
ana@laptop:~/setup$ curl -fsSLO https://github.com/sigstore/cosign/releases/download/v3.1.3/cosign-linux-$ARCH
ana@laptop:~/setup$ curl -fsSL https://github.com/sigstore/cosign/releases/download/v3.1.3/cosign_checksums.txt | grep " cosign-linux-$ARCH$" | sha256sum --check
cosign-linux-amd64: OK
ana@laptop:~/setup$ sudo install -m 0755 cosign-linux-$ARCH /usr/local/bin/cosign && rm cosign-linux-$ARCH
ana@laptop:~/setup$ cosign version | grep GitVersion
GitVersion:    v3.1.3
```

A key pair is two files. The private key signs and is encrypted with a password; the public key
verifies and can be published anywhere. The password is a secret like the Gitea tokens of lesson 2,
so it goes in a file only you can read, and `cosign` reads it from the `COSIGN_PASSWORD` variable
instead of asking:

```
ana@laptop:~/signing$ openssl rand -base64 24 > ~/cosign.password && chmod 600 ~/cosign.password
ana@laptop:~/signing$ export COSIGN_PASSWORD=$(cat ~/cosign.password)
ana@laptop:~/signing$ cosign generate-key-pair
Private key written to cosign.key
Public key written to cosign.pub
ana@laptop:~/signing$ stat -c '%A %n' cosign.key cosign.pub
-rw------- cosign.key
-rw-r--r-- cosign.pub
ana@laptop:~/signing$ cat cosign.pub
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEYXwkkNjIbexO6LJqHvdwoQMjliUC
LXaA1zXL8TKAHvpvgVMUlXou3Uz277HIUfzoZaz3FasGS2+L2KUSZnJuLA==
-----END PUBLIC KEY-----
```

`cosign.key` is readable by its owner only, which `cosign` arranged on its own. **It is the file this
lesson's whole guarantee rests on**: whoever holds it and the password can sign anything in your name,
and every verifier will accept it. In a team it does not live on a laptop. It lives in the CI system's
secret store, or better, in a key management service that signs on request and never lets the key
out; `cosign` can use one in place of the file with `--key` set to an address such as
`awskms://`, `gcpkms://`, `azurekms://` or `hashivault://`. Lesson 9 is about where secrets like this
one live.

`cosign.pub` is the opposite: it is useless to an attacker and has to be everywhere a verification
happens. It goes into the fleet repository later in this lesson.
