---
title: Attestations, and asking them questions
version: 1
---

A signature answers one question: did the holder of this key vouch for these bytes? **An
attestation answers a question about the bytes**: what is inside them, or how they were made. It
is a small JSON document called an **in-toto statement**, with three fields that matter. The
`subject` names the artefact by digest. The `predicateType` says what kind of claim the rest is.
The `predicate` is the claim itself. cosign signs the whole statement and stores it in the
registry beside the image, the same way it stores a signature.

### What is attached to the image

The run of the previous section attached three things to the image `main` now points at. `cosign
tree` lists them; it decorates its output with symbols this page does not draw, so `grep` keeps
only the type of each:

```
ana@vm:~/linkbox$ REF=$(docker inspect --format "{{range .RepoDigests}}{{println .}}{{end}}" localhost:5000/linkbox:main | grep ^localhost:5000/); echo $REF
localhost:5000/linkbox@sha256:a0b743b9eaa4d253341ca2509a1e281fb96602c54ca51f102bdf2dbd53ee923b
ana@vm:~/linkbox$ cosign tree $REF 2>/dev/null | grep -o "https://[^ ]*"
https://slsa.dev/provenance/v1
https://cyclonedx.org/bom
https://sigstore.dev/cosign/sign/v1
```

The signature, the bill of materials in CycloneDX and the provenance in SLSA's format, version 1.
**Anybody who can pull the image can find all three**, and nobody needs a second system to keep
them.

### The bill of materials, verified

`cosign verify-attestation` checks a statement's signature exactly as `cosign verify` checks an
image's, and then prints the statement, encoded in base64 inside a JSON envelope:

```
ana@vm:~/linkbox$ cosign verify-attestation --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true --type cyclonedx $REF > ~/sbom.att.json
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the attestation.

Verification for localhost:5000/linkbox@sha256:a0b743b9eaa4d253341ca2509a1e281fb96602c54ca51f102bdf2dbd53ee923b --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The signatures were verified against the specified public key
ana@vm:~/linkbox$ jq -r .payload ~/sbom.att.json | base64 -d | jq -c "{_type, predicateType, subject}"
{"_type":"https://in-toto.io/Statement/v0.1","predicateType":"https://cyclonedx.org/bom","subject":[{"name":"localhost:5000/linkbox","digest":{"sha256":"a0b743b9eaa4d253341ca2509a1e281fb96602c54ca51f102bdf2dbd53ee923b"}}]}
ana@vm:~/linkbox$ jq -r .payload ~/sbom.att.json | base64 -d | jq ".predicate.components | length"
2190
ana@vm:~/linkbox$ jq ".components | length" ~/ci/runs/1/logs/sbom.cdx.json
2190
```

The subject is the image's digest, so the statement cannot be moved to other bytes. **The count of
components matches the file the run wrote**, which is the point of attaching it: lesson 13 kept the
bill of materials beside the run's logs, where it lives as long as somebody keeps `~/ci/runs`. Now
it travels with the image to every registry the image is copied to, and its signature says it was
written by the CI that pushed it, not edited later by somebody else.

### The provenance, verified

The provenance is read the same way, and the interesting part is the predicate:

```
ana@vm:~/linkbox$ cosign verify-attestation --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true --type slsaprovenance1 $REF 2>/dev/null | jq -r .payload | base64 -d | jq .predicate
{
  "buildDefinition": {
    "buildType": "https://example.org/linkbox/ci/pipeline/v1",
    "externalParameters": {
      "ref": "refs/heads/main",
      "repository": "ci/linkbox.git"
    },
    "resolvedDependencies": [
      {
        "digest": {
          "gitCommit": "076438617306c7ef0715a479cdbd40d2c26b558c"
        },
        "uri": "git+file:ci/linkbox.git"
      }
    ]
  },
  "runDetails": {
    "builder": {
      "id": "https://example.org/linkbox/ci/post-receive"
    },
    "metadata": {
      "finishedOn": "2026-10-23T12:33:49Z",
      "invocationId": "/home/ana/ci/runs/1/logs"
    }
  }
}
ana@vm:~/linkbox$ git rev-parse HEAD
076438617306c7ef0715a479cdbd40d2c26b558c
```

The commit in `resolvedDependencies` is the commit `git rev-parse` names, character for character.
**The image now says which commit it was built from, and the CI's key vouches for the saying.**
`docker build` writes a provenance of its own too, the `attestation-manifest` the first section
found in the image index, and `gitops` lesson 8 reads one. That one is written by the builder and
signed by nobody, which is the difference this section adds.

### A question with a yes or a no

Reading a predicate by eye does not scale to a deployment. cosign can check a statement's contents
against a **policy**, written in CUE or in Rego, and refuse when it does not hold. A policy is a
shape the predicate must fit. Save this one as `~/deploy.cue`:

```
// What a deployment of linkbox accepts: an image whose provenance says it
// was built by the CI server's hook, from the main branch of its repository.
predicate: {
	buildDefinition: externalParameters: {
		repository: "ci/linkbox.git"
		ref:        "refs/heads/main"
	}
	runDetails: builder: id: "https://example.org/linkbox/ci/post-receive"
}
```

And, to see a refusal, a policy that expects a different builder, as `~/hosted.cue`:

```
// The same question, asked by a deployment that accepts only images built by
// a hosted builder, which this laptop is not.
predicate: runDetails: builder: id: "https://ci.example.org/hosted-builder"
```

Both, against the image `main` points at:

```
ana@vm:~/linkbox$ cosign verify-attestation --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true --type slsaprovenance1 --policy ~/deploy.cue $REF > /dev/null
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the attestation.
will be validating against CUE policies: [/home/ana/deploy.cue]

Verification for localhost:5000/linkbox@sha256:a0b743b9eaa4d253341ca2509a1e281fb96602c54ca51f102bdf2dbd53ee923b --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The signatures were verified against the specified public key
ana@vm:~/linkbox$ cosign verify-attestation --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true --type slsaprovenance1 --policy ~/hosted.cue $REF > /dev/null; echo "exit status $?"
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the attestation.
will be validating against CUE policies: [/home/ana/hosted.cue]
There are 1 number of errors occurred during the validation:

- predicate.runDetails.builder.id: conflicting values "https://example.org/linkbox/ci/post-receive" and "https://ci.example.org/hosted-builder"
Error: 1 validation errors occurred
error during command execution: 1 validation errors occurred
exit status 1
```

The first passes. The second names the field and the two values that disagree, and exits with an
error, so a deployment script stops there. **This is the check a deployment makes, rather than a
person reading JSON**: the image is signed by the key we trust, and the statement signed with that
key says main, this repository, this builder.

### Deploy the digest you verified

The last rule is about order. A verification answers for the digest it checked, so **what is
deployed is that digest, never the tag that pointed at it a moment ago**. The shortest form of the
rule, on this machine:

```
ana@vm:~/linkbox$ cosign verify --key ~/ci/keys/cosign.pub --insecure-ignore-tlog=true $REF > /dev/null 2>&1 && docker pull -q $REF
localhost:5000/linkbox@sha256:a0b743b9eaa4d253341ca2509a1e281fb96602c54ca51f102bdf2dbd53ee923b
```

`docker pull` prints the reference it pulled, the digest and nothing else. The same pattern holds
for the cluster of lesson 10: verify the reference, then hand that exact reference to `kubectl set
image`, so the tag cannot move between the check and the pull. That last step was not run in this
lesson; the cluster is lesson 10's, and the next section is about doing the check inside it.
