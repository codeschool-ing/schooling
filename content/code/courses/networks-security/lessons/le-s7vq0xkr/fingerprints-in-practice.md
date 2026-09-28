---
title: Fingerprints you are asked to check
version: 1
---

Signatures and digests are all over the network, mostly invisible:

| where | what is signed or hashed | lesson |
|---|---|---|
| TLS | the server signs the handshake with the key in its certificate | 12, 13 |
| DNSSEC | the zone's records | 8 |
| package managers | the list of packages and their digests, signed by the distribution | this section |
| SSH | the server signs each connection with its host key | this section |
| WireGuard | the handshake, with each peer's static key | 10 |

A package manager is the pattern of the previous section at scale: `apt` downloads a list of every
package's digest, checks the list's signature against the distribution's keys already on the machine,
and checks each package against its digest. A mirror that serves a modified package cannot also
produce a valid signature, so the modification is refused.

**SSH is where a person is asked to do the check**, and usually does not. The first connection to a
server shows a fingerprint of its host key and asks whether to trust it. The server's own fingerprint,
read on `app` by its administrator:

```
root@app:~# ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
256 SHA256:D69NpujcgW9pCTbA68lgiwW9k9fCvqO2C3xgQ55NwQk root@app (ED25519)
```

And what `admin` receives when it asks `app` for its key over the network:

```
ana@admin:~$ ssh-keyscan -t ed25519 app 2>/dev/null | ssh-keygen -lf -
256 SHA256:D69NpujcgW9pCTbA68lgiwW9k9fCvqO2C3xgQ55NwQk app (ED25519)
```

**The same fingerprint**, so the key on the wire is `app`'s. That comparison is the whole point of
the question SSH asks, and it only works when the fingerprint was obtained another way: from the
administrator, from a configuration system, from DNS signed with DNSSEC. Answering *yes* without
comparing trusts whoever answered first.

A client that has never seen the key and cannot ask a person refuses:

```
ana@admin:~$ ssh -o BatchMode=yes app true 2>&1 | head -3
Host key verification failed.
```

That refusal, in a script that runs unattended, is correct, and the fix is to distribute the
servers' host keys to the clients in advance, not to turn the check off.
