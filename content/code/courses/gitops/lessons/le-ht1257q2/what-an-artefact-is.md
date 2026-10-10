---
title: What an artefact is, and what it promises
version: 1
---

**An artefact is the output of a build, kept so that it never has to be built again.** A container
image, a Helm chart, a `.jar`, an npm package, a tarball of a static site: each is produced once, from
one commit, and from then on it is fetched, never rebuilt. Lesson 5 built `bulletin:1.1` once and
ran the same bytes in staging and in production, and that is the whole idea.

Three properties make an artefact worth the name, and each of the next sections tests one of them:

- **It is immutable.** Once published, the bytes behind a reference do not change. If they can, a
  test in staging says nothing about what production pulls an hour later.
- **It is addressable.** There is a name that means exactly these bytes. A tag is a name somebody
  chose and can move; a **digest**, the SHA-256 of the content, is a name the content chose and
  nobody can move.
- **It has provenance.** Somebody can say which source, which commit and which build produced it.
  Lesson 5's three matching 1.0s were the start of that, and lesson 8 makes it something a machine
  can check rather than something people agree on.

**Where artefacts live is a registry or a repository manager.** An OCI registry, like the one this
course runs on port 5001, stores images and anything else packaged the OCI way, Helm charts
included. A repository manager, Artifactory or Nexus, stores those and every other format a company
uses, and adds the things a company needs around them: caches of public repositories, access rules,
retention. A GitOps setup depends on one of them as much as on Git: **Git says which artefact, the
registry holds it**, and if either one lies, the cluster runs something nobody decided.
