---
title: Verifying, and what it prints
version: 1
---

Verifying needs three things: the image, the public key, and the decision about the transparency log.
**`--insecure-ignore-tlog=true` says that no public log entry is expected**, which is true of every
signature in this course and is the reason the flag has that name: for a signature that was meant to
be logged, skipping the log check removes the proof of when it was made.

```
ana@laptop:~/signing$ cosign verify --key cosign.pub --insecure-ignore-tlog=true localhost:5001/bulletin@$DIGEST | jq .
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.

Verification for localhost:5001/bulletin@sha256:55e5248439fc0bf682f42be50a3503363a3de9421bf967a7876a97eb920fab18 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The signatures were verified against the specified public key
[
  {
    "critical": {
      "identity": {
        "docker-reference": "localhost:5001/bulletin@sha256:55e5248439fc0bf682f42be50a3503363a3de9421bf967a7876a97eb920fab18"
      },
      "image": {
        "docker-manifest-digest": "sha256:55e5248439fc0bf682f42be50a3503363a3de9421bf967a7876a97eb920fab18"
      },
      "type": "https://sigstore.dev/cosign/sign/v1"
    },
    "optional": {}
  }
]
```

Three things to read. The `WARNING` is `cosign` saying, correctly, that a signature checked without
a log has no public record of when it was made; for this course's signatures that is the design, and
for a public project's it would be a reason to stop. The list of checks is the one `cosign` always
prints. And the JSON is **what was actually signed**: a small document naming the image's digest,
which is why the signature cannot be moved to other bytes.

Verifying by tag works too, and is not the weaker check it looks like:

```
ana@laptop:~/signing$ cosign verify --key cosign.pub --insecure-ignore-tlog=true localhost:5001/bulletin:1.2 > /dev/null
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.

Verification for localhost:5001/bulletin:1.2 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The signatures were verified against the specified public key
```

`cosign` resolves the tag to a digest first and verifies that. **What it proves is that the digest
the tag points at right now was signed**, which is the question a deployment asks. If the tag moves
to an unsigned image, the next verification fails.
