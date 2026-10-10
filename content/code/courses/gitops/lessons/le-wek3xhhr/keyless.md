---
title: Signing without a key to lose
version: 1
---

**A private key is a secret that lasts for years**, and everything this course says about secrets in
lessons 9 to 11 applies to it: it has to be stored, protected, rotated, and revoked when it leaks, and
a key that signed releases for three years cannot be rotated without every verifier learning the new
one. Sigstore, the project `cosign` belongs to, offers a way around the long-lived key, called
**keyless** signing. There is still a key; it lives for a few minutes.

1. The signer, usually a CI job, proves who it is to an OpenID Connect provider: GitHub Actions,
   GitLab, Google, a company's own. The proof is a short-lived token naming the identity, such as
   *the release workflow of repository X, on tag v1.3*.
2. **Fulcio**, Sigstore's certificate authority, exchanges that token for a certificate valid for ten
   minutes, binding a fresh key pair to the identity.
3. The signer signs the digest with that key, and the key is thrown away.
4. **Rekor**, a public transparency log, records the signature and the certificate, with a timestamp
   proving the signing happened while the certificate was valid.

Verifying then asks a different question from this course's `--key cosign.pub`: not "was this
signed by this key?" but **"was this signed by this identity, according to this issuer?"**. For a
release built by GitHub Actions, the check names the workflow and GitHub's token issuer:

```sh
cosign verify ghcr.io/fluxcd/source-controller:v1.9.6 \
  --certificate-identity-regexp='^https://github.com/fluxcd/' \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

**That command was not run for this course**: the recording machine cannot reach Sigstore's public
services, Fulcio, Rekor and the trust root that verification fetches. It is how you check that a
Flux image you are about to run was built by Flux's own release workflow, and nothing else in this
lesson changes for keyless: the signature still sits beside the artefact, and Flux and the admission
controllers in the coming sections take an identity and an issuer in place of a public key.

The trade is one of trust. With a key pair you trust whoever holds the private key. With keyless you
trust the identity provider and Sigstore's services, and the transparency log lets anybody check
after the fact that no signature was made in a name without being recorded. **For open-source
projects keyless has become the norm**, because there is no key for a maintainer to lose. A company
can run its own Fulcio and Rekor for the same arrangement inside its walls.
