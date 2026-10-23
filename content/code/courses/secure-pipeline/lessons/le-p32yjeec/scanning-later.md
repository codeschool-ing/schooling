---
title: Scanning the SBOM later, and what the scanner can read
version: 1
---

The second promise of an SBOM is that it can be scanned again without the image. An image deleted
from the registry six months ago still has its SBOM beside the run that built it, and today's
advisories can be matched against that list. Lesson 11 tried it with an SBOM written by Trivy and got
exactly the image's count. This section tries it with the SBOM syft wrote, which is the one the
pipeline will keep.

### The baseline

What Trivy finds in the image itself, today:

```
ana@vm:~/linkbox$ trivy image -q --format json localhost:5000/linkbox:main | jq "[.Results[] | {Target, n: (.Vulnerabilities // [] | length)}]"
[
  {
    "Target": "localhost:5000/linkbox:main (debian 13.7)",
    "n": 162
  },
  {
    "Target": "Python",
    "n": 0
  }
]
```

### The same image, through syft's SBOM

```
ana@vm:~/linkbox$ trivy sbom --format json -o ~/sbom/scan.json ~/sbom/linkbox.cdx.json
2026-10-23T08:54:39-03:00	INFO	[vuln] Vulnerability scanning is enabled
2026-10-23T08:54:39-03:00	INFO	Detected SBOM format	format="cyclonedx-json"
2026-10-23T08:54:39-03:00	WARN	Third-party SBOM may lead to inaccurate vulnerability detection
2026-10-23T08:54:39-03:00	WARN	Recommend using Trivy to generate SBOMs
2026-10-23T08:54:39-03:00	INFO	Detected OS	family="debian" version="13.7"
2026-10-23T08:54:39-03:00	INFO	[debian] Detecting vulnerabilities...	os_version="13" pkg_num=38
2026-10-23T08:54:39-03:00	INFO	Number of language-specific files	num=1
2026-10-23T08:54:39-03:00	INFO	[python-pkg] Detecting vulnerabilities...
ana@vm:~/linkbox$ jq "[.Results[] | {Target, n: (.Vulnerabilities // [] | length)}]" ~/sbom/scan.json
[
  {
    "Target": "/home/ana/sbom/linkbox.cdx.json (debian 13.7)",
    "n": 0
  },
  {
    "Target": "Python",
    "n": 0
  }
]
```

**Zero.** Trivy found the operating system, Debian 13.7, and the 38 Debian packages, and matched no
advisory against any of them, where the image gives 162. It said why it might, in its own log: a
third-party SBOM may lead to inaccurate detection, and it recommends using Trivy to generate SBOMs.
The Python half agrees with the image, zero and zero, because there were no Python findings to miss.

A zero that looks exactly like a clean result is the dangerous kind of disagreement lesson 11
warned about. Here is where it comes from:

```
ana@vm:~/linkbox$ jq -r ".components[] | select(.name == \"libc6\") | .purl" ~/sbom/linkbox.cdx.json
pkg:deb/debian/libc6@2.41-12%2Bdeb13u4?arch=amd64&distro=debian-13.7&upstream=glibc
ana@vm:~/linkbox$ trivy image -q --format cyclonedx localhost:5000/linkbox:main | jq -r ".components[] | select(.name == \"libc6\") | .purl, (.properties[] | select(.name == \"aquasecurity:trivy:SrcName\") | .value)"
pkg:deb/debian/libc6@2.41-12%2Bdeb13u4?arch=amd64&distro=debian-13.7
glibc
```

Debian publishes its advisories by **source** package: the advisory is for `glibc`, and `libc6` is
one of the binary packages built from it. Trivy's own SBOM records the source name in a property of
its own, `aquasecurity:trivy:SrcName`, and Trivy reads it back. syft records the same fact in the
purl, as `upstream=glibc`, a qualifier the package URL specification defines, and this version of
Trivy did not use it. **Each SBOM is correct; the pair does not work for Debian packages.**

The SPDX file goes further:

```
ana@vm:~/linkbox$ trivy sbom -q --format json ~/sbom/linkbox.spdx.json | jq "[.Results[] | {Target, n: (.Vulnerabilities // [] | length)}]"
[
  {
    "Target": "Python",
    "n": 0
  }
]
```

From syft's SPDX, Trivy did not even identify the operating system, so it scanned only the Python
packages.

### What to do with that

The lesson is not that syft is wrong or that Trivy is. It is that **an SBOM is a message, and a message is only as good as the reader that will receive it.**

- **Test the pair you will rely on**, the generator and the scanner, on an image whose findings you
  already know, as this section just did. A zero from the pair, where the image has 162, is a result
  you want to see in a lesson rather than in an incident.
- **Keep the SBOM for what it does well.** syft's list answered every question of the last section
  correctly, and a query like the glibc one needs no scanner at all.
- **Scan with a reader made for the writer, or write for the reader.** Anchore's own scanner, Grype,
  is built to read syft's output. It was not run for this course, because this machine cannot reach
  the database Grype downloads, so this lesson does not show that it closes the gap. Trivy's own
  CycloneDX, made with `trivy image --format cyclonedx` as in lesson 11, scans back to 162.
- **Keep the image's digest beside the SBOM**, so that when a result looks wrong the image can still
  be scanned directly, while the registry keeps it.

linkbox's pipeline keeps syft's SBOM, in both formats, because it is the better list: it records
licences, suppliers, the files it read, and the relationships between packages. The scan of record
stays `ci/image.sh` from lesson 8, on the image itself, on every push.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"sp-l13-pair\" aria-label=\"One image, four ways for Trivy to read it. Reading the image directly: 162 Debian findings. Reading Trivy's own CycloneDX SBOM of it: 162. Reading syft's CycloneDX SBOM: Debian detected, 38 packages, 0 findings, because the source package name is in a purl qualifier Trivy did not use. Reading syft's SPDX SBOM: the operating system is not detected at all.\"><defs><marker id=\"sp-l13-pair-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l13-pair-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l13-pair-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"270\" y=\"75\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">trivy</text><text x=\"345.0\" y=\"109.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Debian findings</text><rect x=\"20\" y=\"15\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the image itself</text><path d=\"M210 33 L268 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-pair-ah-paper-dim)\"></path><rect x=\"510\" y=\"15\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">162</text><path d=\"M420 100 L508 33\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-pair-ah-phosphor)\"></path><rect x=\"20\" y=\"63\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Trivy's CycloneDX</text><path d=\"M210 81 L268 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-pair-ah-paper-dim)\"></path><rect x=\"510\" y=\"63\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">162</text><path d=\"M420 100 L508 81\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-pair-ah-phosphor)\"></path><rect x=\"20\" y=\"111\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">syft's CycloneDX</text><path d=\"M210 129 L268 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-pair-ah-paper-dim)\"></path><rect x=\"510\" y=\"111\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"129.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">0</text><path d=\"M420 100 L508 129\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-pair-ah-amber)\"></path><rect x=\"20\" y=\"159\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">syft's SPDX</text><path d=\"M210 177 L268 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-pair-ah-paper-dim)\"></path><rect x=\"510\" y=\"159\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">no OS found</text><path d=\"M420 100 L508 177\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l13-pair-ah-amber)\"></path></svg>", "caption": "The same image, the same scanner, the same database. What changes is who wrote the list the scanner reads."}
```
