---
title: How it was built
version: 1
---

**A signature says who vouches for an image. Provenance says how it was made**: from which source,
at which commit, with which builder and which arguments. It is a statement attached to the image, in
a format called SLSA provenance, and Docker's builder has been writing one for every image in this
course without being asked. Lesson 7 found it in the index, as the manifest marked
`attestation-manifest`. Here is what it says about `bulletin:1.2`:

```
ana@laptop:~/signing$ docker buildx imagetools inspect localhost:5001/bulletin:1.2 --format '{{json .Provenance.SLSA}}' | jq '.buildDefinition.externalParameters.request.root.request.args'
{
  "vcs:localdir:context": ".",
  "vcs:localdir:dockerfile": ".",
  "vcs:revision": "eeb36366262959f88c6fc5eecb28bdfc97c04060",
  "vcs:source": "http://localhost:3000/ana/bulletin.git"
}
ana@laptop:~/signing$ git -C ~/bulletin rev-parse v1.2
eeb36366262959f88c6fc5eecb28bdfc97c04060
```

Two lines that matter: `vcs:source`, the repository the build context came from, and `vcs:revision`,
the commit it was at, which is exactly the commit tag `v1.2` names. Docker read both from the `.git`
directory in the build context and wrote them into the image's attestation, so **the image itself
says which commit it was built from**.

**Provenance is only as good as whoever wrote it.** This one was written by the builder on Ana's
laptop, and nothing stops a laptop from writing any statement it likes. It becomes evidence when a
builder that the developer does not control writes it and signs it: a CI service that records the
repository and the commit it checked out, and signs the statement with an identity of its own. That
is what the SLSA levels grade, from "provenance exists" to "provenance is produced by a hardened
build service that the project's own maintainers cannot tamper with".

`cosign` can sign a statement like this as an **attestation**, with `cosign attest`, and check it with
`cosign verify-attestation`, which also checks the statement's contents against a policy: *built from
this repository, on this builder*. The admission controllers at the end of this lesson can require the
same at the cluster's door. This course signs the image and stops there; the attestation is the same
key and the same registry with a statement in place of nothing.
