---
title: Scanning for known vulnerabilities
version: 2
---

**A vulnerability scanner does two things: it lists what is inside an image, and it looks each item
up in a database of published advisories.** It does not test the program or attack it. A finding
means "this version of this package is named in an advisory", nothing more and nothing less.

Ana uses **Trivy**, an open-source scanner that runs as an image itself, the way lesson 10 ran
tools. A function keeps the long command short:

```
ana@vm:~$ trivy() { docker run --rm -v ~/trivy-cache:/cache -v "$PWD":/work -w /work aquasec/trivy:0.75.0 "$@" --cache-dir /cache --skip-db-update --skip-version-check --offline-scan --scanners vuln --quiet; }
ana@vm:~$ jq -c "{UpdatedAt}" ~/trivy-cache/db/metadata.json
{"UpdatedAt":"2026-10-06T13:07:05.606377799Z"}
```

**The database is the scanner's knowledge, and it has a date.** Trivy downloads a fresh one every
day by default. The lab's containers have no network, so this one was fetched before the lab
started, from the same place Trivy fetches it, and the flags tell Trivy not to look for another.
Every number below is true as of that `UpdatedAt`; the same scan tomorrow can find more.

On your own machine, leave `--skip-db-update` and `--offline-scan` out. The first scan then
downloads the database into `~/trivy-cache`, which takes a minute, and later scans refresh it once a
day:

```sh
trivy() { docker run --rm -v ~/trivy-cache:/cache -v "$PWD":/work -w /work aquasec/trivy:0.75.0 "$@" --cache-dir /cache --skip-version-check --scanners vuln --quiet; }
```

That version was not run here, for the reason above, and your counts will differ from these by
whatever was published between the two databases.

## Three images, side by side

Trivy reads an image from a running daemon or from a file. Ana saves three to files, the two Linux
bases lesson 14 compared and `shelf` itself:

```
ana@vm:~$ cd shelf && docker build -q --build-arg VERSION=1.6.0 -t shelf:1.6.0 . && cd ..
sha256:6c207f0417d7a903ea3ac43fee126be5c845ce5f76704699e9e436e82a7a47ef
ana@vm:~$ docker save debian:trixie-slim -o debian.tar; docker save alpine:3.22 -o alpine.tar; docker save shelf:1.6.0 -o shelf.tar
```

```
[.Results[]?.Vulnerabilities[]?.Severity]
| group_by(.) | map("\(.[0])=\(length)") | join(" ")
| if . == "" then "none" else . end
```

```
ana@vm:~$ for i in debian alpine shelf; do printf "%-7s " $i; trivy image --input $i.tar --format json | jq -r -f severities.jq; done
debian  HIGH=43 LOW=60 MEDIUM=58 UNKNOWN=2
alpine  none
shelf   HIGH=1 UNKNOWN=1
```

**163 known vulnerabilities in `debian:trixie-slim`, none in `alpine:3.22`, and two in `shelf`.**
Lesson 14 counted 78 packages in the Debian image and 16 in Alpine: more packages, more advisories
that can name one of them. None of the 163 is critical; 43 are high.

## What a scanner sees in distroless

Lesson 14 said that distroless has no package manager to ask what it contains. Trivy does not ask a
package manager; it reads the files that describe the packages, and the Go binaries' own build
information:

```
ana@vm:~$ trivy image --input shelf.tar

Report Summary

┌──────────────────────────┬──────────┬─────────────────┐
│          Target          │   Type   │ Vulnerabilities │
├──────────────────────────┼──────────┼─────────────────┤
│ shelf.tar (debian 12.15) │  debian  │        1        │
├──────────────────────────┼──────────┼─────────────────┤
│ probe                    │ gobinary │        0        │
├──────────────────────────┼──────────┼─────────────────┤
│ shelf                    │ gobinary │        1        │
└──────────────────────────┴──────────┴─────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


shelf.tar (debian 12.15)
========================
Total: 1 (UNKNOWN: 1, LOW: 0, MEDIUM: 0, HIGH: 0, CRITICAL: 0)

┌─────────┬───────────────┬──────────┬────────┬───────────────────┬─────────────────┬────────────────────────────────┐
│ Library │ Vulnerability │ Severity │ Status │ Installed Version │  Fixed Version  │             Title              │
├─────────┼───────────────┼──────────┼────────┼───────────────────┼─────────────────┼────────────────────────────────┤
│ tzdata  │ DLA-4792-1    │ UNKNOWN  │ fixed  │ 2026b-0+deb12u1   │ 2026c-0+deb12u1 │ tzdata - new timezone database │
└─────────┴───────────────┴──────────┴────────┴───────────────────┴─────────────────┴────────────────────────────────┘

shelf (gobinary)
================
Total: 1 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 1, CRITICAL: 0)

┌───────────────────┬────────────────┬──────────┬────────┬───────────────────┬───────────────┬─────────────────────────────────────────────────────────────┐
│      Library      │ Vulnerability  │ Severity │ Status │ Installed Version │ Fixed Version │                            Title                            │
├───────────────────┼────────────────┼──────────┼────────┼───────────────────┼───────────────┼─────────────────────────────────────────────────────────────┤
│ golang.org/x/text │ CVE-2026-56852 │ HIGH     │ fixed  │ v0.29.0           │ 0.39.0        │ golang.org/x/text: golang.org/x/text: Denial of Service via │
│                   │                │          │        │                   │               │ invalid UTF-8 input                                         │
│                   │                │          │        │                   │               │ https://avd.aquasec.com/nvd/cve-2026-56852                  │
└───────────────────┴────────────────┴──────────┴────────┴───────────────────┴───────────────┴─────────────────────────────────────────────────────────────┘
```

Three targets in one image. **`debian 12.15`** is the distroless base: it is built from Debian
packages and keeps their records, so Trivy finds `tzdata` and its advisory. **`shelf` and `probe`**
are `gobinary` targets: every Go binary carries the list of modules it was built from, and Trivy
reads it. That is how it found `golang.org/x/text` v0.29.0, which `shelf` never imports directly; it
came with `pgx`. The next section decides what to do about each.
