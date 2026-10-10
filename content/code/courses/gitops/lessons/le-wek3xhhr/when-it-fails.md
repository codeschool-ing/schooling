---
title: When it fails
version: 1
---

A verification has two ways to fail, and they mean different things. **No signature at all** is the
image nobody signed:

```
ana@laptop:~/signing$ cosign verify --key cosign.pub --insecure-ignore-tlog=true localhost:5001/bulletin:1.1
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.
Error: no signatures found
error during command execution: no signatures found
```

`no signatures found`: there is nothing stored beside 1.1's digest. Nobody signed it, which in this
course is true, because signing started at 1.2.

**A signature from somebody else** is the more serious one, because somebody did sign; just not with
the key you trust. Here a second key pair, made for the purpose, stands in for that somebody:

```
ana@laptop:~/signing$ cosign verify --key /tmp/other/cosign.pub --insecure-ignore-tlog=true localhost:5001/bulletin@$DIGEST
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.
Error: no matching attestations: failed to verify signature: could not verify envelope: accepted signatures do not match threshold, Found: 0, Expected 1
error during command execution: no matching attestations: failed to verify signature: could not verify envelope: accepted signatures do not match threshold, Found: 0, Expected 1
```

This time a signature exists, and the error is different: the signature found does not verify with
the key given. `Found: 0, Expected 1` is `cosign` counting the signatures that matched.

And the flag this lesson keeps passing matters. Without `--insecure-ignore-tlog=true`, `cosign` expects
every signature to be recorded in Rekor, fetches Sigstore's trust root to check that, and fails a
key-only signature that was never logged. That run is not recorded here: this machine cannot reach
Sigstore at all, so it fails one step earlier, at fetching the trust root, which is not the failure
you would meet.

| what you see | what it means | what to do |
|---|---|---|
| `no signatures found` | the digest carries no signature in this registry | sign it, or find out why the pipeline did not |
| `accepted signatures do not match threshold` | a signature exists, none of them made by your key | find out who signed it; never answer by trusting their key |
| `no matching signatures were found` in `flux get sources` | Flux checked the chart's signature and refused it | the same two questions, asked about the chart |

**The wrong answer to every one of these is the same**: turning the check off. A verification that is
disabled on the day it fails was never a check, only a delay. Each failure above names an artefact
and a key, and the question to answer is always which of the two is wrong.

## Rotating the key

Keys have to change: a person leaves, a laptop is lost, a policy says every year. Rotation with a key
pair is three steps, and the order matters:

1. publish the new public key **beside** the old one, so verifiers accept both. Flux's Secret can
   hold several `.pub` files, and a signature by any of them passes;
2. sign new releases with the new key, and re-sign the images that are still deployed;
3. remove the old public key once nothing running carries only its signature.

A leaked key skips the patience: its public half is removed at once, and every image it signed is
re-signed with the new key or rebuilt. That is why **re-signing must be routine** before it is ever
an emergency, and one more reason keyless signing appeals: there is no long-lived key to rotate.
