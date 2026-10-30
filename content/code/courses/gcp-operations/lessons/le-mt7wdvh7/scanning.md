---
title: Vulnerability scanning, and reading a finding
version: 1
---

**Artifact Analysis scans an image when it is pushed and reports the known vulnerabilities in the
packages inside it.** It reads the operating system's package database and the language packages it
recognises, compares their versions with published advisories, and attaches one occurrence per
vulnerability to the image's digest. It does not run the image, and it finds nothing that is not
already a published advisory. Nothing on your computer imitates it, so this section was not run; it
is taught from Google's documentation.

## Turning it on, and what it costs

Scanning is an API, `containerscanning.googleapis.com`. With it enabled, every image pushed to a
repository in the project is scanned on push, and then **re-scanned for 30 days** as new advisories
are published: an image that was clean on Monday can carry a critical finding on Thursday, without
anybody touching it. After 30 days an image that has not been pulled is no longer kept up to date.

The pricing page, read on 30 October 2026, charges **0.26 USD per scan** for automatic scanning. The
shop's 440 pushes a month would cost 440 × 0.26 = 114.40 USD, about a hundred times what the builds
of lesson 1 cost. Two ways keep that down:

- **scan only the repositories that deploy**: scanning can be switched off per repository, and a
  repository of throwaway branch images does not need it;
- **push less**: a pull request whose build pushes an image on every commit pays for a scan on every
  commit. Pushing only from `main` pays once per merge.

## Reading what it found

The findings of one image, as `gcloud` lists them:

```sh
gcloud artifacts docker images list southamerica-east1-docker.pkg.dev/planner-dev/shop/api \
  --show-occurrences --occurrence-filter='kind="VULNERABILITY"'
gcloud artifacts docker images describe \
  southamerica-east1-docker.pkg.dev/planner-dev/shop/api@sha256:7f5d… \
  --show-package-vulnerability
```

Each occurrence names the CVE, the package and the version installed, the version that fixes it if
one exists, and two severities: **the advisory's own** (from the CVSS score) and **the distribution's
effective severity**, which says how it affects this distribution's build of the package. They
disagree often, and the effective one is the one to sort by: a critical CVE in a library feature that
Debian compiles out is low for Debian.

**What to act on first** is the finding that is high or critical, has a fixed version, and sits in an
image that runs. The first two say there is something you can do; the third says doing it matters.
For the shop that is nearly always the base image: `python:3.12.16-slim` brings Debian's packages,
and the fix is a newer patch release of the image rebuilt and redeployed, not a change to `app.py`.
A finding with no fix is recorded, watched, and judged against what the package is used for; it is
not a reason to stop every deployment.

## Scanning is a report, not a gate

**Nothing about a finding stops an image from being pulled or deployed.** Scanning writes a report;
it refuses nothing. Turning a report into a refusal takes something that reads it at the moment of
deployment, and that is lesson 4's subject: a policy that admits only images carrying an attestation,
and a build step that only signs an image whose scan passed.
