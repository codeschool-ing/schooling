---
title: What verification refuses
version: 1
---

A check that has only ever been seen passing is a check nobody has tested. **The value of `cosign
verify` is in what it refuses**, and two refusals matter in practice: an image nobody signed under
a name you trust, and a signature made with a key you do not trust. Both are on this machine
already, because the first section moved `main` to an image of its own.

### The tag that moved

`main` points at the image with the extra label, which nobody signed. Ask about it by tag:

```
ana@vm:~/linkbox$ cosign verify --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true localhost:5000/linkbox:main; echo "exit status $?"
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.
Error: no signatures found
error during command execution: no signatures found
exit status 10
ana@vm:~/linkbox$ cosign verify --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true localhost:5000/linkbox:$(git rev-parse --short HEAD) > /dev/null
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.

Verification for localhost:5000/linkbox:de3591e --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The signatures were verified against the specified public key
```

`cosign` resolved `main` to its digest, looked for a signature over that digest, found none, and
exited with status 10. **The signature over the original image did not follow the tag**, because
it was never about the tag. The second command asks about the commit's tag, which still points at
the signed digest, and passes; a verification by tag is a verification of whatever digest the tag
names at that moment, which is the question a deployment asks.

That is the result the rules in the first section's table were for. A deployment that runs `cosign
verify` against `linkbox:main` before every pull refuses the moved tag on the next attempt,
whoever moved it and however good their access to the registry was.

### A key that is not the CI's

Make a second key pair, as somebody who wanted their own image accepted might, and verify the real
signature against its public key:

```
ana@vm:~/linkbox$ mkdir ~/other-key && cd ~/other-key && COSIGN_PASSWORD= cosign generate-key-pair && cd ~/linkbox
Private key written to cosign.key
Public key written to cosign.pub
ana@vm:~/linkbox$ cosign verify --key ~/other-key/cosign.pub --insecure-ignore-tlog=true $REF; echo "exit status $?"
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.
Error: no matching attestations: failed to verify signature: could not verify envelope: accepted signatures do not match threshold, Found: 0, Expected 1
error during command execution: no matching attestations: failed to verify signature: could not verify envelope: accepted signatures do not match threshold, Found: 0, Expected 1
exit status 1
```

The signature is there and it is valid, for the other key. **`Found: 0, Expected 1` means no
signature on the image verified against the key given**, and the exit status is 1. The message
mentions attestations because `cosign` 3 stores a signature in the same envelope format it uses
for attestations; the check is the same either way.

This is the reason `cosign.pub` has to come from somewhere the verifier trusts, never from the
registry beside the image. Somebody able to push an image could push a public key next to it just
as easily. In this course the key sits in `~/ci/keys`; in a team it is published once, in a
repository with protected review, or held by the cluster's admission controller, and the
section on SLSA and keyless signing says what replaces it altogether.

### What each answer means

| what `cosign verify` reports | what it means | what a deployment does |
|---|---|---|
| verification passes | the digest was signed by the holder of this key | deploys that digest |
| `no signatures found`, status 10 | nobody signed these bytes, whatever tag they carry | refuses |
| `Found: 0, Expected 1`, status 1 | somebody signed, but not with this key | refuses |

**Every answer but the first is a refusal, and a deployment treats them alike.** It does not need
to know which of the two went wrong to know that it must not pull.

### What a signature does not say

**A valid signature says who vouched, never that the image is safe.** The CI signs whatever passed
its stages. If the scan in lesson 8 had a gap, the signed image has the same gap, and the signature
makes it look more trustworthy, not less vulnerable. Nor does a signature say what is inside the
image or how it was built: the image could have been built from any commit, on any branch, by any
script the commit contained. Those are questions about the bytes, and the CI can answer them too,
as signed statements of their own. The next two sections make the CI sign every image it pushes
and attach those statements to it.
