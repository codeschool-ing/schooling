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

@@CAPTURE tree@@

The signature, the bill of materials in CycloneDX and the provenance in SLSA's format, version 1.
**Anybody who can pull the image can find all three**, and nobody needs a second system to keep
them.

### The bill of materials, verified

`cosign verify-attestation` checks a statement's signature exactly as `cosign verify` checks an
image's, and then prints the statement, encoded in base64 inside a JSON envelope:

@@CAPTURE sbom-attestation@@

The subject is the image's digest, so the statement cannot be moved to other bytes. **The count of
components matches the file the run wrote**, which is the point of attaching it: lesson 13 kept the
bill of materials beside the run's logs, where it lives as long as somebody keeps `~/ci/runs`. Now
it travels with the image to every registry the image is copied to, and its signature says it was
written by the CI that pushed it, not edited later by somebody else.

### The provenance, verified

The provenance is read the same way, and the interesting part is the predicate:

@@CAPTURE provenance@@

The commit in `resolvedDependencies` is the commit `git rev-parse` names, character for character.
**The image now says which commit it was built from, and the CI's key vouches for the saying.**
`docker build` writes a provenance of its own too, which lesson 13 found in the image index as an
`attestation-manifest`, and `gitops` lesson 8 read it; that one is written by the builder and
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

@@CAPTURE policy@@

The first passes. The second names the field and the two values that disagree, and exits with an
error, so a deployment script stops there. **This is the check a deployment makes, rather than a
person reading JSON**: the image is signed by the key we trust, and the statement signed with that
key says main, this repository, this builder.

### Deploy the digest you verified

The last rule is about order. A verification answers for the digest it checked, so **what is
deployed is that digest, never the tag that pointed at it a moment ago**. The shortest form of the
rule, on this machine:

@@CAPTURE deploy@@

`docker pull` prints the reference it pulled, the digest and nothing else. The same pattern holds
for the cluster of lesson 10: verify the reference, then hand that exact reference to `kubectl set
image`, so the tag cannot move between the check and the pull. That last step was not run in this
lesson; the cluster is lesson 10's, and the next section is about doing the check inside it.
