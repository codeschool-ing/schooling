---
title: Artifactory and Nexus
version: 1
---

**An OCI registry stores OCI artefacts. A company stores more than that**: Maven jars, npm and PyPI
packages, Go modules, Debian packages, Helm charts, plain tarballs. A **repository manager** is one
server that speaks all of those formats, and the two that most companies run are JFrog Artifactory
and Sonatype Nexus Repository. Both have a free edition and a paid one.

They organise repositories the same way, with different words:

| what it does | Nexus calls it | Artifactory calls it |
|---|---|---|
| stores what your builds publish | hosted | local |
| fetches from a public source on first use, then serves its copy | proxy | remote |
| one address in front of several of the above | group | virtual |

**The proxy is the part that changes how a company works.** Every build fetches `busybox`, `requests`
or `lodash` through the company's own server, which keeps a copy. Builds stop depending on Docker
Hub's rate limits or on a public registry being up; a package that disappears upstream, or is
replaced by a malicious version, does not disappear or change inside the company; and there is one
place to see every third-party artefact the company uses. The recording machine of this course is a
small instance of the same idea: its cluster pulls everything through one registry that holds
copies.

**The group is what makes it convenient.** Developers and builds point at one address, say
`https://repo.example.com/npm/`, and the group answers from the hosted repository for the company's
own packages and from the proxy for everybody else's.

Around that, both add what an organisation needs and a bare registry does not have: users and
permissions per repository, **write-once policies** that refuse to overwrite a published version,
retention rules, and an audit log of who published what. Nexus calls the write-once policy *deployment
policy: disable redeploy*; Artifactory calls it *immutable* or simply refuses to overwrite
releases by default.

## Why this course does not run one

Both run as a container, and Nexus was tried on the recording machine: it needs about 2 GiB of
memory and a minute to start, and the free edition asks the person installing it to accept its
licence through its API before it will store anything. **That acceptance is yours to give, not a
course's**, so the hands-on part of this lesson stays on the OCI registry, which is everything a
GitOps setup needs from a repository manager: a place images and charts are published once and
pulled by digest. If your company runs Artifactory or Nexus, the registry address in your manifests
is theirs, and everything else in this lesson is the same.
