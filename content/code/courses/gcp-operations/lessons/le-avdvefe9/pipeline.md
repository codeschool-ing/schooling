---
title: Who signs, and when, in the shop's pipeline
version: 1
---

**A signature is worth exactly as much as the decision behind it.** A policy that requires a signature
from a key the build holds says "this image came out of our build", and nothing more. If the same
build signs every image it makes, a vulnerable image is signed too. So each attestor stands for one
decision, and the step that signs is the step that made it. This section is taught from Google's
documentation; none of it ran.

## Two attestors, two decisions

| attestor | signed by | what the signature asserts |
|---|---|---|
| `built-by-cloud-build` | the last step of the build of lesson 1 | this digest was built from the repository by the shop's trigger, after its tests passed |
| `scan-passed` | a step that reads the scan of lesson 2 | this digest's scan had no high or critical finding with a fix |

The second step waits for the scan, reads the occurrences for the digest, and signs only if they pass.
Written as a build step, with the key in Cloud KMS:

```yaml
  - id: attest-scan
    name: gcr.io/google.com/cloudsdktool/cloud-sdk:slim
    entrypoint: bash
    args:
      - -c
      - |
        gcloud artifacts docker images describe "$$IMAGE" --show-package-vulnerability \
          --format=json > /workspace/scan.json
        python3 /workspace/ci/scan_gate.py /workspace/scan.json
        gcloud beta container binauthz attestations sign-and-create \
          --artifact-url="$$IMAGE" --attestor=scan-passed \
          --keyversion=projects/planner-dev/locations/southamerica-east1/keyRings/binauthz/cryptoKeys/scan-passed/cryptoKeyVersions/1
```

`$$IMAGE` is written with two dollar signs because it is the shell's variable, not a substitution
(lesson 1). `scan_gate.py` is the shop's own rule, which exits with 1 when the scan fails it, and with
that exit the build stops and `sign-and-create` never runs: no attestation, so no deployment. The rule
lives in the repository, where a change to it is reviewed like a change to the code.

## The key is the attestor

Whoever can use the private key can attest. That is why it lives in Cloud KMS, and why only the build's
service account has `roles/cloudkms.signerVerifier` on it, on that one key. **A person who can sign
with that key can admit any image**, and the policy cannot tell the difference, because it checks a
signature and not the hand that made it. The audit log of the key's use (lesson 18) is the only place
that difference shows.

## Continuous validation

Admission is checked once, when a pod or a revision is created. An image admitted on Monday whose scan
turns critical on Thursday is still running on Friday. GKE's **continuous validation** re-evaluates
running pods against the policy and writes a log entry for each one that would no longer be admitted.
It reports and does not stop anything, and that is deliberate: killing a running service because an
advisory was published overnight is a decision for a person, made from the report.
