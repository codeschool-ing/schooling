---
title: Three specifications
version: 1
---

**"Docker" names a company, a set of tools and, loosely, the whole idea of containers, and the
idea no longer belongs to any of them.** What makes an image built on Ana's laptop run unchanged
on a Kubernetes cluster that has never had Docker installed is a set of three public
specifications, kept by the **Open Container Initiative** (OCI).

## How it got here

Docker was released in 2013 and made containers easy enough for everyone to use. Its image format
and the program that started containers were Docker's own, so in 2015 Docker and others founded
the OCI under the Linux Foundation, and Docker gave it the code that starts containers, which
became **runc**. Version 1.0 of the image and runtime specifications came out in 2017, and the
distribution specification followed in 2021.

## What each one fixes

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"An image travels left to right. A build tool such as docker build, BuildKit or Podman writes an image in the format of the image specification. A registry such as Docker Hub, GHCR or ECR stores it and serves it as the distribution specification says. On a host, a runtime such as runc or crun starts it from a bundle, as the runtime specification says.\"><defs><marker id=\"l3specs-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"40\" width=\"200\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">build</text><text x=\"110\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">docker build · BuildKit · Podman</text><rect x=\"260\" y=\"40\" width=\"200\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">store and serve</text><text x=\"360\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Docker Hub · GHCR · ECR</text><rect x=\"510\" y=\"40\" width=\"200\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">run</text><text x=\"610\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">runc · crun</text><path d=\"M212 77 L256 77\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l3specs-ah-amber)\"></path><path d=\"M462 77 L506 77\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l3specs-ah-amber)\"></path><text x=\"234\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">push</text><text x=\"484\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">pull</text><rect x=\"15\" y=\"150\" width=\"190\" height=\"58\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"110\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">image spec</text><text x=\"110\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">manifest, config, layers</text><path d=\"M110 146 L110 120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"265\" y=\"150\" width=\"190\" height=\"58\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">distribution spec</text><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the HTTP API of a registry</text><path d=\"M360 146 L360 120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"515\" y=\"150\" width=\"190\" height=\"58\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"610\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">runtime spec</text><text x=\"610\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a rootfs plus config.json</text><path d=\"M610 146 L610 120\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path></svg>", "caption": "Each arrow is a format somebody agreed on, so each box can be replaced by another tool that speaks the same format."}
```

- **The image specification** says what an image is on disk and on the wire: a manifest listing
  the pieces, a configuration with the default command and environment, and layers that are
  ordinary compressed tar archives. Any tool that writes this format produces an image every other
  tool can run. The next section opens one.
- **The runtime specification** says how to start a container from a directory: a root
  filesystem plus a file called `config.json` describing the process, its namespaces and its
  limits. runc is the reference implementation, and the last section of this lesson drives it by
  hand.
- **The distribution specification** says how a registry stores images and hands them out over
  HTTP: which URL returns a manifest, which returns a layer. Docker Hub, GitHub's registry and every
  cloud provider's registry speak it, which is why `docker push` works against all of them.
  Lesson 15 runs a registry and talks to it.

Ana's own machine shows which runtime Docker uses, and which version of the runtime
specification that runtime implements:

```
ana@vm:~$ docker info --format "{{.DefaultRuntime}}"
runc
ana@vm:~$ runc --version
runc version 1.5.1
commit: v1.5.1-0-g8f2685a4
spec: 1.3.0
go: go1.27.1
libseccomp: 2.5.5
```

`runc`, implementing version 1.3.0 of the runtime specification. When Ana types `docker run`, the
last step, after the image has been found and the filesystem prepared, is runc creating the
process. Lesson 6 follows the whole chain from the `docker` command down to it.

## Why the specification matters to you

**A standard format means the image is the deliverable, and the tool that made it is a detail.**
Three things follow from that, and each one has already happened:

- **The tools can be swapped.** Podman, Buildah, BuildKit and kaniko all build images; containerd,
  CRI-O and Podman all run them. Lesson 28 runs one of the alternatives against the same image.
- **An orchestrator can drop Docker without dropping your images.** Kubernetes removed its built-in
  support for the Docker Engine in version 1.24, in 2022, and talks to containerd or CRI-O
  directly. Images built with `docker build` kept running, because they were OCI images all along.
- **The registry is interchangeable.** An image pushed to Docker Hub can be copied to a cloud
  provider's registry byte for byte, and its digest stays the same. The next section shows what a
  digest is.
