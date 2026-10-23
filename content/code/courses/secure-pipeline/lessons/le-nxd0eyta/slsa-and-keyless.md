---
title: SLSA levels, keyless signing and the cluster's door
version: 1
---

Lesson 12 drew the supply chain with SLSA's letters on it, the places where a source, a build or a
package can be tampered with. **SLSA, Supply-chain Levels for Software Artifacts, is also a ladder**:
a short list of levels, each a set of requirements on how an artefact is built and what it carries
about its build. Version 1.0 of the specification has one track, the Build track, and it is the one
this lesson's provenance belongs to.

### The Build track, and where this pipeline stands

| level | the requirement, in short | what it stops |
|---|---|---|
| Build L0 | none | nothing |
| Build L1 | provenance exists, describing how the artefact was built | mistakes: a release built from the wrong commit can be found out |
| Build L2 | the build runs on a hosted build platform, which writes and signs the provenance itself | tampering after the build: a forged provenance fails its signature |
| Build L3 | the platform is hardened: runs cannot influence one another, and the key that signs the provenance is out of reach of the build's own steps | tampering during the build, by whoever controls a build's steps |

**Be precise about this pipeline, because it is tempting to claim more than it does.** It produces
provenance for every image, so it meets Build L1. It signs that provenance, which is the shape of
Build L2 without its substance: the builder is a hook on a laptop, run by the same person who writes
the code, so the signature says "Ana's machine vouches for Ana's build". And it is plainly not Build
L3, for the reason the pipeline section named: `ci/sign.sh` comes from the commit being built, so a
build's own steps can read the key.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" data-fig=\"sp-l14-levels\" aria-label=\"The four levels of SLSA's Build track from L0 to L3. This pipeline meets Build L1: provenance exists. It has the shape of L2, a signed provenance, without a hosted build platform. L3 needs the signing key out of reach of the build's own steps, which this pipeline does not do.\"><defs><marker id=\"sp-l14-levels-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l14-levels-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"160\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Build L0</text><text x=\"100.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no guarantees</text><path d=\"M180 77 L198 77\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-levels-ah-paper-dim)\"></path><rect x=\"198\" y=\"50\" width=\"160\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"278.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Build L1</text><text x=\"278.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">provenance exists</text><path d=\"M358 77 L376 77\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-levels-ah-paper-dim)\"></path><rect x=\"376\" y=\"50\" width=\"160\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"456.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Build L2</text><text x=\"456.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">hosted platform signs it</text><path d=\"M536 77 L554 77\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-levels-ah-paper-dim)\"></path><rect x=\"554\" y=\"50\" width=\"160\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"634.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Build L3</text><text x=\"634.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">hardened, key out of reach</text><text x=\"278\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">this pipeline</text><path d=\"M278 38 L278 48\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l14-levels-ah-phosphor)\"></path><text x=\"456\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">the shape only: signed, but on a laptop</text><text x=\"712\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">ci/sign.sh comes from the commit</text></svg>", "caption": "Each level adds a requirement on who builds and who signs. A signature made by the developer's own machine does not climb the ladder."}
```

Reaching L2 is a matter of moving the build to a platform the developer does not control, such as a
hosted CI. Reaching L3 needs that platform to keep the signing out of the job: the job asks, and the
platform signs. GitHub's documentation describes its **artifact attestations**, made by the action
`actions/attest-build-provenance`, as provenance at Build L2, and at L3 when the build runs in a
reusable workflow that the calling repository cannot edit. **None of that was run for this course**:
GitHub's hosted runners are not reachable from the recording machine, and nothing here can be
signed by GitHub.

### Keyless signing, from Sigstore's documentation

`cosign.key` is a secret that lasts for years, with every problem lesson 17 describes for secrets
that last: it has to be stored, rotated, and revoked when it leaks, and every verifier has to learn
the new public key when it changes. Sigstore's answer is **keyless** signing, where there is still a
key but it lives for minutes:

1. The CI job proves who it is to an OpenID Connect provider. On GitHub Actions that is a
   short-lived token the job can request when its workflow grants `id-token: write`, naming the
   repository, the workflow and the ref.
2. **Fulcio**, Sigstore's certificate authority, exchanges the token for a certificate valid for
   ten minutes, which binds a fresh key pair to that identity.
3. The job signs the digest with the fresh key and throws the key away.
4. **Rekor**, the public transparency log, records the signature and the certificate, so anybody
   can check later that the signature was made while the certificate was valid.

Verification then names an identity and an issuer instead of a key:

```sh
cosign verify ghcr.io/example/linkbox@sha256:<digest> \
  --certificate-identity=https://github.com/example/linkbox/.github/workflows/ci.yml@refs/heads/main \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

**That command was not run**, and it could not be: Fulcio, Rekor and the trust root that verification
fetches are Sigstore's public services, and the recording machine reaches none of them. The
repository `example/linkbox` is an illustration. `gitops` lesson 8 walks through the same four steps
in more detail. What changes for the pipeline is the trade: with a key pair you trust whoever holds
`cosign.key`; with keyless you trust the identity provider, Sigstore's services, and a public log in
which every signature made in your name is visible, including one you did not make.

### Verification at the cluster's door

Everything this lesson verified, it verified by hand or in a script. **The place that sees every
pod before it runs is admission**, and lesson 10's ValidatingAdmissionPolicy cannot do this job: its
CEL rules read the object being admitted and cannot fetch a signature from a registry. Two admission
controllers can, and both are taught here from their documentation, **not run**:

| | how a rule is written | what it checks |
|---|---|---|
| **Kyverno** | a `ClusterPolicy` with a `verifyImages` rule: which images, which key or identity, which attestations | the signature, and an attestation's predicate against conditions; it can rewrite a tag in the pod to the digest it verified |
| **Sigstore policy-controller** | a `ClusterImagePolicy`: which images, which authorities | the signature, and attestations against a CUE or Rego policy, only in namespaces labelled `policy.sigstore.dev/include=true` |

`gitops` lesson 8 shows a Kyverno `verifyImages` rule for a key like this lesson's. Both projects
publish their images on registries the recording machine cannot reach, which is why neither ran
here. Two properties matter before you install either. They must verify **digests**, so the pod runs
exactly what was checked. And a rule that refuses every unsigned image also refuses the controller's
own image on its next restart unless the system namespaces are excluded, which is why both are
tried in an audit mode first.

The policy in `~/deploy.cue` is the question such a controller asks, and so is lesson 10's rule about
which registry an image may come from. The difference is that a signature check needs the
registry's answer, and so it lives in a controller that can fetch one.
