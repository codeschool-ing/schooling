---
title: What an image scanner reads
version: 1
---

The common picture of an image scanner is an antivirus: it opens every file in the image, looks
inside, and recognises what is dangerous. **It does nothing of the kind. An image scanner reads
lists.** It finds the records that package managers leave behind, the list of what was installed
and at which version, and looks each entry up in a database of advisories. A file that no list
mentions is a file it does not know is there.

That one fact explains most of what this lesson finds, both the alarming numbers and the quiet
gaps. `docker` lesson 20 ran a scanner on an image and read its report; this lesson asks what the
report is made of, so that the pipeline's image stage can decide on it.

### The database comes first

Trivy, the scanner of this course, keeps its advisories in a local database that it downloads and
refreshes once a day. The first scan on a machine downloads it on its own. To see that step by
itself:

```
ana@vm:~$ TRIVY_SKIP_DB_UPDATE=false trivy image --no-progress --cache-dir /tmp/trivy-db --download-db-only
2026-10-23T09:39:54-03:00	INFO	[vulndb] Need to update DB
2026-10-23T09:39:54-03:00	INFO	[vulndb] Downloading vulnerability DB...
2026-10-23T09:39:54-03:00	INFO	[vulndb] Downloading artifact...	repo="mirror.gcr.io/aquasec/trivy-db:2"
2026-10-23T09:40:10-03:00	INFO	[vulndb] Artifact successfully downloaded	repo="mirror.gcr.io/aquasec/trivy-db:2"
ana@vm:~$ trivy version --cache-dir /tmp/trivy-db
Version: 0.75.0
Vulnerability DB:
  Version: 2
  UpdatedAt: 2026-10-23 07:12:39.66827463 +0000 UTC
  NextUpdate: 2026-10-24 07:12:39.668274239 +0000 UTC
  DownloadedAt: 2026-10-23 12:40:10.310745067 +0000 UTC
```

**About 130 MB, from a registry rather than from a website**: the database is published as an
OCI artefact, the same kind of object as an image, and this machine fetched it through
`mirror.gcr.io`. `UpdatedAt` is when Trivy's builders last assembled it from the sources it
merges, among them the Debian security tracker, GitHub's advisory database and the advisories of
each language's package index. `NextUpdate` is a day later, and a scan after that time downloads
again.

The recording used one database for every count in this course, which is why this download went to
a directory of its own and was thrown away. On your machine, leave out `--cache-dir` and the
variable in front: plain `trivy image --download-db-only` puts the database in `~/.cache/trivy`,
where every later scan finds it. **Your database will be newer than this one, so every count you
get will differ from the ones printed here.** The shape of the results will not.

### Three scans, saved

Scan the three base images this lesson compares, and keep each report as JSON, which can be
queried afterwards without scanning again:

```
ana@vm:~$ mkdir ~/scans && cd ~/scans
ana@vm:~/scans$ trivy image --quiet --format json -o full.json python:3.13
ana@vm:~/scans$ trivy image --quiet --format json -o slim.json python:3.13-slim
ana@vm:~/scans$ trivy image --quiet --format json -o distroless.json gcr.io/distroless/python3-debian13:nonroot
```

A table is easy to read and hard to count with, so the lesson counts with `jq` and a small filter
that prints one line per part of a report. Save it as `~/scans/count.jq`:

```
# One line per part of a Trivy JSON report: its type, how many findings,
# by severity, and how many of them name a fixed version.
.Results[] | (.Vulnerabilities // []) as $v
| if ($v | length) == 0 then "\(.Type): nothing found" else
  "\(.Type): \($v | length) found (\($v | group_by(.Severity)
  | map("\(.[0].Severity) \(length)") | join(", "))), \([$v[] | select(.FixedVersion)] | length) with a fix"
  end
```

### What it read

A report is divided into targets, one per kind of list the scanner found. The distroless image has
one:

```
ana@vm:~/scans$ jq -r '.Results[] | "\(.Target)  \(.Packages | length) packages"' distroless.json
gcr.io/distroless/python3-debian13:nonroot (debian 13.7)  38 packages
ana@vm:~/scans$ jq -r '.Results[].Packages[] | .AnalyzedBy' full.json | sort | uniq -c
    469 dpkg
      1 python-pkg
     18 sbom
```

**The 38 packages of the distroless image all come from one list**, the Debian package database,
which `dpkg` keeps in `/var/lib/dpkg`. `python:3.13` is a full Debian system and has 469 entries
there. Its other 19 packages came from two places that are worth knowing. One is pip's own
`METADATA` file, the record Python writes for every installed package in its `.dist-info`
directory. The other 18 came from a file called `bom.cdx.json`: pip ships a copy of the libraries
it depends on inside itself, under `pip/_vendor`, and lists them in a CycloneDX software bill of
materials (lesson 13's subject). Trivy read that list and so knows that pip carries its own urllib3:

```
ana@vm:~/scans$ docker run --rm --entrypoint cat python:3.13-slim /usr/local/lib/python3.13/site-packages/pip/_vendor/bom.cdx.json | jq -r '.components[] | select(.name == "urllib3") | "\(.name) \(.version)"'
urllib3 2.7.0
```

### What it cannot see

A file copied into an image with no record beside it is invisible. The same directory of urllib3
code, copied once on its own and once with the list that names it, makes the point. Neither image
is part of the project; they live in a scratch directory and are deleted afterwards. The first
copies urllib3 alone. Save it as `~/blind/Dockerfile.code`:

```dockerfile
FROM python:3.13-slim AS source
FROM gcr.io/distroless/python3-debian13:nonroot
COPY --from=source /usr/local/lib/python3.13/site-packages/pip/_vendor/urllib3 /packages/urllib3
```

The second copies the whole `_vendor` directory, `bom.cdx.json` included. Save it as
`~/blind/Dockerfile.listed`:

```dockerfile
FROM python:3.13-slim AS source
FROM gcr.io/distroless/python3-debian13:nonroot
COPY --from=source /usr/local/lib/python3.13/site-packages/pip/_vendor /packages/_vendor
```

Build both and scan both with the filter:

```
ana@vm:~/scans$ cd ~/blind
ana@vm:~/blind$ docker build -q -f Dockerfile.code -t blind:code . >/dev/null
ana@vm:~/blind$ docker build -q -f Dockerfile.listed -t blind:listed . >/dev/null
ana@vm:~/blind$ trivy image --quiet --format json blind:code | jq -r -f ~/scans/count.jq
debian: 162 found (HIGH 26, LOW 49, MEDIUM 87), 0 with a fix
ana@vm:~/blind$ trivy image --quiet --format json blind:listed | jq -r -f ~/scans/count.jq
debian: 162 found (HIGH 26, LOW 49, MEDIUM 87), 0 with a fix
python-pkg: 6 found (HIGH 4, MEDIUM 2), 6 with a fix
```

**The same urllib3 2.7.0 is in both images, and only one of the two reports mentions it.** Without
the list, the scan of `blind:code` says what it says about the distroless base and nothing about
the code that was added. This is not a defect of Trivy; every image scanner works this way, because
recognising code from its bytes is a much harder and much less reliable problem than reading a
version number from a record.

It matters wherever something reaches an image without a package manager:

- **a binary downloaded with `curl` in a `RUN` line**, a common way to install a tool that is not
  packaged for the distribution;
- **code copied from another project** into the repository, a vendored library with no metadata;
- **a program compiled during the build** and copied into the final stage. Go records its module
  dependencies inside the binary, and Trivy reads that record; a C program records nothing.

The defence is not a better scanner. It is keeping everything in the image on a list: installing
through a package manager, or, where that is impossible, writing the component into the SBOM by
hand, which lesson 13 does. **A clean report is a statement about the lists, not about the image.**
