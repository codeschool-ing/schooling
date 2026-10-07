---
title: Signatures, when the two sides share nothing
version: 1
---

**When the people checking a message do not share a secret with its author, the check has to be a
signature: made with the author's private key, verified with a public key everybody may hold.**
Lesson 3 showed the operation with `openssl pkeyutl`. This section uses the tool many teams already
have installed for it: OpenSSH's `ssh-keygen -Y`, which signs any file with an SSH key, and which
Git uses to sign commits and tags.

## Ana's key, and who it belongs to

Ana's Ed25519 key is the one from lessons 2 and 3, and OpenSSH wants it in a format of its own. A
short tool writes it that way, from the same label:

```py
# ~/lab/tools/sshkey.py
"""vcrypt sshkey LABEL FILE [COMMENT]: an Ed25519 key derived from LABEL, in
OpenSSH's own format, as FILE; with a COMMENT, its public half as FILE.pub."""
import os
import sys

from cryptography.hazmat.primitives import serialization

import keys

label, path = sys.argv[1], sys.argv[2]
k = keys.ed25519_key(label)
open(path, "wb").write(k.private_bytes(serialization.Encoding.PEM,
                                       serialization.PrivateFormat.OpenSSH,
                                       serialization.NoEncryption()))
os.chmod(path, 0o600)  # ssh refuses a private key others can read
if len(sys.argv) > 3:
    pub = k.public_key().public_bytes(serialization.Encoding.OpenSSH,
                                      serialization.PublicFormat.OpenSSH).decode()
    open(path + ".pub", "w").write(f"{pub} {sys.argv[3]}\n")
```

The commands write Ana's key and its public half, and then the list of who signs with which key,
which the next paragraphs explain:

```sh
cd ~/lab
vcrypt sshkey keys/ed25519-ana keys/ana_ssh ana@vereda.example
echo "ana@vereda.example $(cut -d' ' -f1,2 keys/ana_ssh.pub)" > data/allowed_signers
```

The public half:

```
ana@lab:~/lab$ cat keys/ana_ssh.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKbrVbLEHhq6u+cmCobYboWrP2Yp4hGI5xXLgb45i5Jn ana@vereda.example
```

A public key says nothing about whose it is, as lesson 2 warned, so verification needs a list that
binds names to keys. OpenSSH calls it an *allowed signers* file, and Vereda's is the one line the
`echo` above wrote:

```
ana@lab:~/lab$ cat data/allowed_signers
ana@vereda.example ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKbrVbLEHhq6u+cmCobYboWrP2Yp4hGI5xXLgb45i5Jn
```

That file is the trust decision. Whoever controls it decides which keys count as Ana's, which is why
in a real team it lives in the repository, changes by review, and is checked out from a protected
branch.

## Signing the release notes

```
ana@lab:~/lab$ ssh-keygen -Y sign -f keys/ana_ssh -n file data/release/NOTES.txt
Signing file data/release/NOTES.txt
Write signature to data/release/NOTES.txt.sig
ana@lab:~/lab$ cat data/release/NOTES.txt.sig
-----BEGIN SSH SIGNATURE-----
U1NIU0lHAAAAAQAAADMAAAALc3NoLWVkMjU1MTkAAAAgputVssQeGrq75yYKhthuhas/Zi
niEYjnFcuBvjmLkmcAAAAEZmlsZQAAAAAAAAAGc2hhNTEyAAAAUwAAAAtzc2gtZWQyNTUx
OQAAAEADd1SxSwEYGJ/0ZgrdyQP7euO/cAIriRPu0ZVod9poXFyFyZFoK9OvCm2gzkRTfY
idFunf2DuuDHYxa9Om1a8D
-----END SSH SIGNATURE-----
```

`-n file` is the **namespace**, a label signed together with the content, so that a signature made
for one purpose cannot be reused for another: a signature over a file in the `file` namespace will
not verify as a Git commit signature, which uses `git`. The signature block holds the public key,
the namespace, the hash algorithm (`sha512`) and the Ed25519 signature itself. Ed25519 is
deterministic, so signing the same notes again gives these exact bytes.

## Verifying, and a change

Anybody with the allowed signers file can verify, and nobody needs Ana's private key:

```
ana@lab:~/lab$ ssh-keygen -Y verify -f data/allowed_signers -I ana@vereda.example -n file -s data/release/NOTES.txt.sig < data/release/NOTES.txt
Good "file" signature for ana@vereda.example with ED25519 key SHA256:WQC0xcZGw6I14/kTQfeosQeRcxSG8diqypQPqXgm3DI
```

`SHA256:WQC0…` is the key's **fingerprint**, the SHA-256 of the public key, short enough to read
aloud on a phone call when somebody wants to confirm that the key in the file is really Ana's. Change
one word of the notes and the same signature fails:

```
ana@lab:~/lab$ sed 's/SMS/e-mail/' data/release/NOTES.txt | ssh-keygen -Y verify -f data/allowed_signers -I ana@vereda.example -n file -s data/release/NOTES.txt.sig
Signature verification failed: incorrect signature
Could not verify signature.
```

## Choosing between the two

| situation | use | because |
|---|---|---|
| a gateway notifying your server | HMAC | the two sides already share a key, and speed matters |
| a session cookie your own server issued | HMAC | the issuer and the verifier are the same party |
| a software release, a container image | a signature | thousands verify, none share a secret with the author |
| a commit, a contract, an invoice | a signature | a third party may need to know who signed |
| a token one service issues and others verify | a signature | the verifiers must not be able to issue |

The last row is the one designs get wrong. If several services verify tokens with a shared HMAC
key, every one of them can also mint tokens, and the weakest service holds the key to all the others.
A signature splits the two powers: one service signs, the rest only verify.
