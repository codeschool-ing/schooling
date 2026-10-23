---
title: Trivy, one engine and several ways in
version: 1
---

Lesson 8 used Trivy on images and lesson 5 on a requirements file, which can leave the impression
of two tools that happen to share a name. **Trivy is one engine with several front doors.** Every
mode does the same two things: find the records of what is installed (a Debian package database,
a `METADATA` file, a lockfile) and match them against one vulnerability database. What changes
between modes is only where the files come from.

| mode | reads | where it fits |
|---|---|---|
| `image` | an image, from Docker or a registry, layer by layer | the pipeline, after the build |
| `rootfs` | a filesystem already unpacked on disk | a machine's or a container's root, mounted for inspection |
| `fs` | a directory of source: lockfiles, requirements, manifests | the pipeline, before the build; the editor |
| `sbom` | a bill of materials somebody made earlier | later, without the artefact itself |
| `config` | Dockerfiles, Kubernetes manifests, Terraform | the pipeline, beside the code that holds them |
| `k8s` | a live cluster: its workloads, their images, their settings | on a schedule, against what is running |

The way to believe that it is one engine is to give it the same image through four different
doors and watch the count. The first door, the image itself:

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

### The same files, unpacked

`rootfs` reads a filesystem that is already on disk. That is what a scanner gets when it is handed
a mounted disk or a container's root rather than an image, and you can make one from linkbox's
image: create a container without starting it and export its filesystem.

```
ana@vm:~/linkbox$ mkdir -p ~/scratch/rootfs
ana@vm:~/linkbox$ docker create --name linkbox-rootfs localhost:5000/linkbox:main
0a1e3e40d9bf737d7a2cd5446d0e2755e59f386df54050e6004c2cb348a84f98
ana@vm:~/linkbox$ docker export linkbox-rootfs | tar -xf - -C ~/scratch/rootfs
ana@vm:~/linkbox$ docker rm linkbox-rootfs
linkbox-rootfs
ana@vm:~/linkbox$ ls ~/scratch/rootfs
app
bin
boot
data
dev
etc
home
lib
lib64
packages
proc
root
run
sbin
sys
tmp
usr
var
ana@vm:~/linkbox$ trivy rootfs -q --format json ~/scratch/rootfs | jq "[.Results[] | {Target, n: (.Vulnerabilities // [] | length)}]"
[
  {
    "Target": "/home/ana/scratch/rootfs (debian 13.7)",
    "n": 162
  },
  {
    "Target": "Python",
    "n": 0
  }
]
```

The same 162 in Debian's packages, and nothing in the Python ones. **No layers, no image metadata,
no registry, and the same answer**, because the answer was always in two places inside those files:
`/var/lib/dpkg/status.d` for Debian and the `dist-info` directories under `/packages` for Python.

### The same files, described

`sbom` scans a list of components instead of the files themselves. Ask Trivy to write that list
for the image in CycloneDX, one of the two formats lesson 13 compares, and scan the list:

```
ana@vm:~/linkbox$ trivy image -q --format cyclonedx -o ~/scratch/linkbox.cdx.json localhost:5000/linkbox:main
ana@vm:~/linkbox$ trivy sbom -q --format json ~/scratch/linkbox.cdx.json | jq "[.Results[] | {Target, n: (.Vulnerabilities // [] | length)}]"
[
  {
    "Target": "/home/ana/scratch/linkbox.cdx.json (debian 13.7)",
    "n": 162
  },
  {
    "Target": "Python",
    "n": 0
  }
]
```

162 again, from a file with no image behind it. That is the promise of a bill of
materials, an answer to "are we affected" long after the image is gone, and lesson 13 tests the
promise with a list made by a different tool.

### The source, before the build

`fs` reads the repository the way it stands, which for linkbox means `requirements.txt`:

```
ana@vm:~/linkbox$ trivy fs -q --table-mode summary .

Report Summary

┌──────────────────┬──────┬─────────────────┬─────────┐
│      Target      │ Type │ Vulnerabilities │ Secrets │
├──────────────────┼──────┼─────────────────┼─────────┤
│ requirements.txt │ pip  │        0        │    -    │
└──────────────────┴──────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)
```

**Zero is right, and it is a different zero from the image's.** It says the pins lesson 5 chose
have no advisory today. It says nothing about the Debian packages, which only exist once the base
image is pulled, so `fs` and `image` are two checks rather than one check run twice.

### The cluster, as it runs

`k8s` asks the Kubernetes API what is deployed, then scans each workload's image and settings.
With the cluster of lesson 10 running and linkbox applied:

```
ana@vm:~/linkbox$ kubectl get deployments -n linkbox
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
linkbox   0/1     0            0           0s
ana@vm:~/linkbox$ trivy k8s -q --include-namespaces linkbox --report summary

Summary Report for kind-linkbox
===============================

Workload Assessment
┌───────────┬────────────────────┬──────────────────────┬───────────────────┬───────────────────┐
│ Namespace │      Resource      │   Vulnerabilities    │ Misconfigurations │      Secrets      │
│           │                    ├───┬────┬────┬────┬───┼───┬───┬───┬───┬───┼───┬───┬───┬───┬───┤
│           │                    │ C │ H  │ M  │ L  │ U │ C │ H │ M │ L │ U │ C │ H │ M │ L │ U │
├───────────┼────────────────────┼───┼────┼────┼────┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┼───┤
│ linkbox   │ Deployment/linkbox │   │ 26 │ 87 │ 49 │   │   │   │ 1 │ 3 │   │   │   │   │   │   │
└───────────┴────────────────────┴───┴────┴────┴────┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘
Severities: C=CRITICAL H=HIGH M=MEDIUM L=LOW U=UNKNOWN


Infra Assessment
┌───────────┬──────────┬───────────────────┬───────────────────┬───────────────────┐
│ Namespace │ Resource │  Vulnerabilities  │ Misconfigurations │      Secrets      │
│           │          ├───┬───┬───┬───┬───┼───┬───┬───┬───┬───┼───┬───┬───┬───┬───┤
│           │          │ C │ H │ M │ L │ U │ C │ H │ M │ L │ U │ C │ H │ M │ L │ U │
└───────────┴──────────┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘
Severities: C=CRITICAL H=HIGH M=MEDIUM L=LOW U=UNKNOWN


RBAC Assessment
┌───────────┬──────────┬───────────────────┐
│ Namespace │ Resource │  RBAC Assessment  │
│           │          ├───┬───┬───┬───┬───┤
│           │          │ C │ H │ M │ L │ U │
└───────────┴──────────┴───┴───┴───┴───┴───┘
Severities: C=CRITICAL H=HIGH M=MEDIUM L=LOW U=UNKNOWN
```

The vulnerabilities column is the image again: 26 high, 87 medium and 49 low, which add up to the
same 162. The misconfigurations column, one medium and three low, is what `config` says about the
same Deployment in the next section. **The value of this mode is not a new finding, it is the
question it answers**: what is running in the cluster today, whoever deployed it and however. A
Deployment applied by hand last month, with an image that never went through the pipeline, shows
up here and nowhere else. That makes `k8s` the artefact scanner's closest relative to a network
scan, and it belongs on the same kind of calendar.

The deployment shows `0/1` ready because the scan ran seconds after the apply. The scan reads the
Deployment's specification and pulls its image, so it does not need the pod to be running.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" data-fig=\"sp-l11-ways\" aria-label=\"One image given to Trivy through four modes, and the repository through a fifth. The image, its exported filesystem, Trivy's CycloneDX bill of materials and the Deployment in the kind cluster each give 162 Debian findings. The repository's requirements.txt gives 0, because the Debian packages only exist in the image.\"><defs><marker id=\"sp-l11-ways-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">trivy image</text><text x=\"185\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linkbox:main</text><path d=\"M345 38 L418 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path><rect x=\"600\" y=\"20\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">162</text><rect x=\"20\" y=\"64\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">trivy rootfs</text><text x=\"185\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">~/scratch/rootfs</text><path d=\"M345 82 L418 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path><rect x=\"600\" y=\"64\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">162</text><rect x=\"20\" y=\"108\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">trivy sbom</text><text x=\"185\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">linkbox.cdx.json</text><path d=\"M345 126 L418 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path><rect x=\"600\" y=\"108\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">162</text><rect x=\"20\" y=\"152\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">trivy k8s</text><text x=\"185\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Deployment/linkbox</text><path d=\"M345 170 L418 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path><rect x=\"600\" y=\"152\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">162</text><rect x=\"20\" y=\"196\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">trivy fs</text><text x=\"185\" y=\"214\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requirements.txt</text><path d=\"M345 214 L418 125\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path><rect x=\"600\" y=\"196\" width=\"100\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">0</text><rect x=\"420\" y=\"100\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"495.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">one engine, one database</text><text x=\"650\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Debian findings</text><path d=\"M570 125 L598 38\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path><path d=\"M570 125 L598 82\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path><path d=\"M570 125 L598 126\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path><path d=\"M570 125 L598 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path><path d=\"M570 125 L598 214\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l11-ways-ah-paper-dim)\"></path></svg>", "caption": "Four doors into the same files give the same 162. The fifth reads different files and answers a different question."}
```

### Why one engine matters

When four doors give the same count, a difference between two runs means something changed in the
artefact or in the database, not in the tool. That is what makes the stored SBOM of lesson 13
worth keeping. It also marks the edge of the guarantee: the agreement holds between Trivy's own
modes, reading Trivy's own database. Another tool, or an SBOM written by another tool, is a
different measurement, and the last section of this lesson shows how far apart two of them can be
on a single package.
