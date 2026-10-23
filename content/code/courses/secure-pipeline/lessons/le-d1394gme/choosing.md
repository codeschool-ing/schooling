---
title: One finding through two tools, and which tool for which question
version: 1
---

Two scanners pointed at the same thing rarely print the same number, and the first reaction is to
decide that one of them is wrong. Usually neither is. **They count different things, under
different names, from different databases**, and the way to see it is to follow one finding through
both.

### Gunicorn 21.2.0, twice

linkbox pins gunicorn 22.0.0. The version before it, 21.2.0, has two published advisories, which
makes it a good specimen. Put it alone in a scratch requirements file, outside the project, and ask
Trivy and then pip-audit, the tool lesson 5 put in the pipeline:

```
ana@vm:~/linkbox$ mkdir -p ~/scratch/old && cd ~/scratch/old
ana@vm:~/scratch/old$ printf "gunicorn==21.2.0\n" > requirements.txt
ana@vm:~/scratch/old$ trivy fs -q --format json . | jq -r ".Results[].Vulnerabilities[] | [.VulnerabilityID, .Severity, .FixedVersion] | @tsv"
CVE-2024-1135	HIGH	22.0.0
CVE-2024-6827	HIGH	22.0.0
ana@vm:~/scratch/old$ pip-audit --aliases on -r requirements.txt
Found 4 known vulnerabilities in 1 package
Name     Version ID              Fix Versions Aliases
-------- ------- --------------- ------------ ----------------------------------
gunicorn 21.2.0  PYSEC-2026-1434 22.0.0       CVE-2024-1135, GHSA-w3h3-4rj7-4ph4
gunicorn 21.2.0  PYSEC-2026-1433 22.0.0       GHSA-hc5x-x2vx-497g, CVE-2024-6827
gunicorn 21.2.0  PYSEC-2026-1434 22.0.0       CVE-2024-1135, GHSA-w3h3-4rj7-4ph4
gunicorn 21.2.0  PYSEC-2026-1433 22.0.0       GHSA-hc5x-x2vx-497g, CVE-2024-6827
```

Trivy says two, pip-audit says four. Read the rows instead of the headline:

- Trivy names each advisory by its **CVE** identifier: CVE-2024-1135 and CVE-2024-6827, both high,
  both fixed in 22.0.0.
- pip-audit names them by their **PYSEC** identifiers, from the Python advisory database it reads
  through PyPI, and `--aliases on` prints the other names of each: PYSEC-2026-1434 is
  CVE-2024-1135 and GHSA-w3h3-4rj7-4ph4, and PYSEC-2026-1433 is CVE-2024-6827 and
  GHSA-hc5x-x2vx-497g.
- pip-audit printed each of the two advisories twice, and its headline counted the rows.

**Two problems, three naming schemes, and a count of four.** Anyone comparing the headlines would
report that pip-audit found twice as much. Anyone comparing by alias finds the two tools agree
exactly: the same two advisories, the same fixed version. That is the habit worth keeping: compare
findings by advisory, through the aliases, never by the number at the top.

### Why two scanners disagree

The gunicorn case shows two of the causes. The others are just as ordinary:

| cause | what happens |
|---|---|
| identifiers | one advisory under a CVE, a GHSA and a PYSEC name, counted once or three times |
| counting | one CVE in four packages of the same Debian source is four rows to one tool and one to another, as lesson 8 saw |
| databases | each tool reads its own sources and updates on its own schedule, so a new advisory reaches one before the other |
| package identity | a distribution publishes advisories by **source** package (`glibc`), a scanner sees **binary** packages (`libc6`); a tool that cannot map one to the other matches nothing |
| defaults | one includes advisories with no fix, another hides them; one uses the vendor's severity, another NVD's |

The fourth row is the dangerous one, because it does not produce a different count. It produces a
count of zero that looks exactly like a clean result. Lesson 13 meets it.

### Which tool for which question

The families of this lesson, and the modes of Trivy, line up with questions. Start from the
question, not from the tool somebody already bought.

| the question | the tool | where it runs |
|---|---|---|
| what is inside the image we are about to ship? | an artefact scanner: `trivy image` | the pipeline, every push (lesson 8) |
| do our pins have advisories? | `pip-audit`, `trivy fs` | the pipeline, every push (lesson 5) |
| do the Dockerfile and manifests set what we decided? | `trivy config`, and our own policies | the pipeline (lesson 19) |
| what is running in the cluster today? | `trivy k8s` | on a schedule, against the cluster |
| what is listening on our network, including what nobody listed? | a network scanner, unauthenticated | on a schedule, with written authorisation |
| which hosts are missing a patch? | a network scanner with credentials, or agents | on a schedule, across the estate |
| is the laptop that never sits on the office network patched? | an agent | continuously, from the host |
| are we affected by the advisory published this morning? | the stored SBOMs | on demand (lesson 13) |

**The pipeline owns the first three rows, and this course builds them.** The rest belong to whoever
runs the estate, with Nessus, OpenVAS or Qualys and the authorisation that comes with them. A team
that only has the pipeline's half knows its next release and not its servers; a team that only has
the other half finds out about a vulnerable library a month after it shipped.
