---
title: Digital signatures, checkable by anyone
version: 1
---

A **digital signature** is made with a private key and checked with the matching public key. Only the
holder of the private key can make one; anybody with the public key can check it. That fixes both
limitations met so far: unlike a bare digest it cannot be recomputed by an attacker, and unlike an
HMAC the checker cannot forge one.

The people who publish the agent sign each release on `admin`, with an **Ed25519** key pair made once:

```
ana@admin:~$ openssl genpkey -algorithm ed25519 -out release.key; openssl pkey -in release.key -pubout -out release.pub; cat release.pub
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEATZYYS8vjlrhJ22IsXQ/grXnj1Llczs89wImxSNp4Bjk=
-----END PUBLIC KEY-----
```

The public key is what gets published, once, somewhere the users already trust: the company's
documentation, its internal wiki, the configuration that installs the agent. Then the release is
signed, on `admin`, after a copy of the agent is put in your home there with
`sudo cp /lab/www/var/www/downloads/agent-2.4.1.tar.gz /lab/admin/home/$USER/` and
`sudo chown $USER: /lab/admin/home/$USER/agent-2.4.1.tar.gz` on your own computer:

```
ana@admin:~$ openssl pkeyutl -sign -rawin -inkey release.key -in agent-2.4.1.tar.gz -out agent-2.4.1.tar.gz.sig; wc -c agent-2.4.1.tar.gz.sig
64 agent-2.4.1.tar.gz.sig
```

The signature is 64 bytes, whatever the size of the file. `laptop` gets the public key, the signature
and an intact copy of the file, the one it downloaded having been altered in the previous section:

```sh
sudo cp /lab/admin/home/$USER/release.pub /lab/admin/home/$USER/agent-2.4.1.tar.gz.sig /lab/admin/home/$USER/agent-2.4.1.tar.gz /lab/laptop/home/$USER/
sudo chown $USER: /lab/laptop/home/$USER/*
```

and checks the file against them:

```
ana@laptop:~$ openssl pkeyutl -verify -rawin -pubin -inkey release.pub -in agent-2.4.1.tar.gz -sigfile agent-2.4.1.tar.gz.sig
Signature Verified Successfully
ana@laptop:~$ printf "x" >> agent-2.4.1.tar.gz; openssl pkeyutl -verify -rawin -pubin -inkey release.pub -in agent-2.4.1.tar.gz -sigfile agent-2.4.1.tar.gz.sig; echo "exit $?"
Signature Verification Failure
exit 1
```

`Signature Verified Successfully` for the file as signed, and `Signature Verification Failure` after
one byte was appended. **Now the check means something against a person**: replacing the file on the
server is no longer enough, because a replacement would need a signature made with a key that never
left `admin`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Three integrity checks compared. A hash uses no key: anybody can compute it, so it catches accidents only. An HMAC uses one shared secret: both holders can compute and check it, so it proves the message came from one of them. A signature uses a key pair: only the private key&#x27;s holder can make it and anybody with the public key can check it, so it proves who signed.\"><defs><marker id=\"hs-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"200\" height=\"170\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"34\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">sha256sum</text><text x=\"34\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no key</text><text x=\"34\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">anybody can make it</text><text x=\"34\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">catches accidents</text><path d=\"M34 132 L206 132\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><rect x=\"260\" y=\"20\" width=\"200\" height=\"170\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"274\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">HMAC</text><text x=\"274\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one shared secret</text><text x=\"274\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">both holders can make it</text><text x=\"274\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">proves: one of the two</text><path d=\"M274 132 L446 132\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><rect x=\"500\" y=\"20\" width=\"200\" height=\"170\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"514\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Ed25519</text><text x=\"514\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a key pair</text><text x=\"514\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">only the private key&#x27;s holder</text><text x=\"514\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">proves: who signed</text><path d=\"M514 132 L686 132\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path></svg>", "caption": "Who can make the value decides what checking it proves."}
```

Signing is not encrypting. The file stayed readable to everybody; the signature only says who stands
behind it and that it is unchanged. In practice a signature is made over the file's digest rather than
the file, which is why both halves of this lesson travel together.

**Everything rests on the public key being the right one.** A user who fetched `release.pub` from the
same compromised server as the file would check a forged release against a forged key, and see
`Signature Verified Successfully`. How to know whose public key you hold, at the scale of the whole internet, is lesson 12.
