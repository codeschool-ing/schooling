---
title: "Incidents in the build: SolarWinds, Codecov, tj-actions"
version: 1
---

Three incidents, five years apart, with one thing in common: **the source code the victims reviewed
was fine.** What went wrong happened after it, in the machinery that builds, ships or tests the
software. Each is told here from the public post-mortems and analyses, at the level of what broke
and what would have caught it; details that are not certain are left out.

### SolarWinds, 2020: the build process (E)

SolarWinds makes Orion, network-monitoring software installed in many companies and government
agencies. Attackers got into SolarWinds' build environment and placed a program there, which the
security firm CrowdStrike later analysed and named SUNSPOT. **It watched for Orion builds and, while
one was running, swapped a source file for a version with a backdoor**, then put the original back.
The repository never contained the backdoor. The compiled product did, and it was signed with
SolarWinds' own certificate, because signing happened after the build.

Updates carrying it were distributed in 2020, and the compromise was made public in December 2020.
SolarWinds put the number of customers who installed an affected version at under 18,000.

What would have caught it:

- **A build that cannot be changed from outside the build**: an isolated, short-lived environment
  created for each run and destroyed after it, which SLSA's higher build levels require. An implant
  that persists between builds has nowhere to live.
- **Provenance**: a signed record, made by the build platform, of exactly which source went in.
  Lesson 14 produces one for linkbox.
- **A second, independent build compared with the first.** A reproducible build that gives different
  bytes on a clean machine is a build that was tampered with somewhere.

**The signature did not help, and that is the lesson of SolarWinds for lesson 14**: a signature
says who published the artefact, not that the artefact is what the source says.

### Codecov, 2021: artefact publication (F)

Codecov offered a Bash script, the Bash Uploader, that many CI pipelines downloaded and ran on every
build, usually with `curl` piped straight into `bash`. An attacker obtained a credential through a
flaw in the way Codecov built one of its Docker images, and from 31 January 2021 used it to modify
the script in Codecov's storage. **The modified script sent the CI environment, secrets included, to
a server outside Codecov.**

It was found on 1 April 2021 by a customer who compared the SHA-256 of the script they had downloaded
with the hash published for it, and saw they differed. Codecov disclosed it on 15 April.

What would have caught it:

- **Checking the hash before running the script**, which is literally how it was found. Every
  pipeline that piped the download into `bash` without that check ran the modified one.
- **Fewer secrets in the CI environment**: a script that only sees a short-lived token for one job
  has little to send. Lesson 17 builds that.
- **Provenance for the published file**: SLSA uses Codecov as its example of letter F, because a
  record of how the official script was built would not have matched the modified one.

### tj-actions/changed-files, 2025: a dependency of the build

`tj-actions/changed-files` is a GitHub Action that lists the files a change touched, used by tens of
thousands of repositories. In March 2025 an attacker with a stolen token **pointed the action's
version tags at a new commit** whose code printed the CI runner's secrets into the build log. For a
public repository, the build log is public. It was given CVE-2025-30066.

The workflows that referred to the action by tag, such as `@v45`, ran the new code without any change
on their side, because a Git tag can be moved. **Workflows that referred to a full commit hash kept
running the old code**, because a commit hash names exactly one tree of files.

What would have caught it:

- **Pinning every action by commit**, with the version in a comment for people to read, which lesson
  16 does to linkbox's workflow and checks with zizmor.
- **Least privilege for the workflow's token**, so that what can leak is worth little.
- **Not printing secrets in logs**, a protection hosted runners apply by masking known secrets, and
  which this attack worked around by encoding them.

The three are the same shape at three places on the chain. Somebody trusted a step they did not
control, in the build, in a downloaded script, in a tag, and the control that would have noticed is
one that compares what arrived with a record of what was meant: provenance, a hash, a commit.
