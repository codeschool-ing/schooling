---
title: Scanning, and what a scan can and cannot tell you
version: 1
---

An image is the base it was built on plus your code, and the base is most of it: the shop's `web`
image is a Debian system with Python inside, carrying hundreds of packages nobody on the team chose
one by one. **Vulnerability scanning reads the list of packages in an image and compares it with
published advisories**, so that a known flaw in one of them becomes a finding with a name rather
than a surprise.

## What Artifact Registry offers

Scanning on Google Cloud belongs to **Artifact Analysis**, which works with Artifact Registry in
two ways, both documented by Google and **neither run in this lab**, which has no registry of
Google's to scan:

- **automatic scanning**: turned on per project, it scans each image when it is pushed, then keeps
  re-evaluating images that were pushed or pulled recently as new advisories appear;
- **on-demand scanning**: a command that scans an image you name, including one on your own
  machine, and returns the findings without storing them in the registry.

The on-demand form, as Google documents it, is one command against an image:

```sh
gcloud artifacts docker images scan \
  southamerica-east1-docker.pkg.dev/planner-dev/shop/web:1.4.1 --remote
```

Each finding names the package, the version installed, the advisory, its severity and, when there
is one, the version that fixes it. Both forms are billed per image scanned, at prices on Artifact
Analysis's own page.

## Reading findings without panicking

A base image of a general-purpose distribution carries findings almost always, and most of them
are in packages the application never loads. **The questions to ask of a finding are three**: is
the package used at run time, is there a fixed version, and is the flaw reachable from how the
service is exposed. A critical flaw in a compression library the web server uses is urgent; the
same severity in a manual-page tool that is never run is noise.

The cheapest reduction is the one before any scan: **a smaller base**. `python:3.12.13-slim`, the
base of every image in this course, already leaves out the compilers and documentation of the full
image; distroless and Alpine-based images go further, at the price of tools you may want when
debugging. Fewer packages means fewer findings, and the remaining ones are more likely to matter.

## Where scanning stops

**A scan says what is known to be wrong with the packages, not that the image is safe.** It does
not read your code, it does not know a flaw that has not been published, and it does not see
configuration: a secret baked into a layer passes every vulnerability scan. Those need other
checks, a secret scanner in the build and a review of what the `Dockerfile` copies, and the build
pipeline is the place for them, before the push rather than after.

Scanning also connects to the rest of the platform. **Binary Authorization**, a GKE and Cloud Run
feature, can refuse to run an image that lacks an attestation, for example one recording that it
passed scanning; that is how "we scan everything" becomes "nothing unscanned runs". Setting it up
is beyond this course; `gcp-operations` gives it lesson 4, and returns to this registry, its
immutable tags and its scanning, in lesson 2.
