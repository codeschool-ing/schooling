---
title: A policy that admits only attested images
version: 1
---

**Binary Authorization is a check at the moment of deployment: an image is admitted only if it
carries the attestations a policy asks for.** Lesson 2 ended with scanning that reports and refuses
nothing. This is the part that refuses. A policy names **attestors**, each one a public key and a
name; an **attestation** is a signature, made with an attestor's private key, over one image digest.
When Cloud Run or GKE is asked to run an image, Binary Authorization looks for an attestation by each
required attestor over that exact digest, and if one is missing the deployment is refused. Nothing in
this section can run on your computer; it is taught from Google's documentation and was not run.

The wrong picture is that Binary Authorization inspects the image: that it scans it, reads its
labels, or decides whether it is safe. It does none of that. **It checks signatures.** Every decision
about safety was made earlier, by whoever held a private key and chose to sign. The policy only
enforces that somebody did.

## The shop's policy

A project has one policy, written in YAML and imported with `gcloud`:

```yaml
# policy.yaml
globalPolicyEvaluationMode: ENABLE
defaultAdmissionRule:
  evaluationMode: REQUIRE_ATTESTATION
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  requireAttestationsBy:
    - projects/planner-dev/attestors/built-by-cloud-build
    - projects/planner-dev/attestors/scan-passed
```

```sh
gcloud container binauthz policy import policy.yaml
```

Line by line:

- **`globalPolicyEvaluationMode: ENABLE`** exempts the images Google itself runs for GKE's system
  components, so turning the policy on does not stop the cluster's own pods.
- **`evaluationMode`** is one of `ALWAYS_ALLOW`, `ALWAYS_DENY` or `REQUIRE_ATTESTATION`. The first is
  where every project starts.
- **`enforcementMode`** decides what a failure does. `ENFORCED_BLOCK_AND_AUDIT_LOG` refuses the
  deployment and writes it to the audit log. `DRYRUN_AUDIT_LOG_ONLY` refuses nothing and writes the
  same entry, which is how a policy is introduced: a week of dry run shows every image that would have
  been refused, before any of them is.
- **`requireAttestationsBy`** lists the attestors. Both are required: one says the image came out of
  the shop's build, the other that its scan had no fixable critical finding. The order means nothing;
  all of them must be present.

## Enforcement is per platform

The policy is only consulted where it is turned on:

| platform | how it is turned on |
|---|---|
| GKE | `--binauthz-evaluation-mode=PROJECT_SINGLETON_POLICY_ENFORCE` on the cluster |
| Cloud Run | `--binary-authorization=default` on the service, or an organisation policy requiring it |

A Cloud Run service deployed without the flag runs any image, policy or no policy. So the
organisation policy constraint `run.allowedBinaryAuthorizationPolicies` is what turns "the shop's
services use it" into "no service in the project can be deployed without it", and `gcp-foundations`
lesson 4 is about organisation policies.

## Break-glass, and what keeps it honest

An incident at 3 a.m. may need an image that nobody has signed yet. Binary Authorization allows
**break-glass**: a deployment annotated as such is admitted whatever the policy says, and the
admission is written to the audit log as a break-glass event. It is not hidden and not silent, and
that is the whole design: the door exists, and opening it leaves a record somebody reviews in the
morning. A log-based alert on that entry, lesson 10's subject, is what makes sure somebody does.
