---
title: Controls, mapped to the chain
version: 1
---

Seven incidents can leave the impression that every link fails in its own unique way and needs its
own unique tool. The opposite is closer to true. **Most of the controls that would have caught them are one idea, applied at different links.** Compare what arrived with an independent record of what was meant. A hash is that record for a file, a commit hash for an action, provenance for a build, a
lockfile diff for a dependency tree, a signature for a publisher.

### Every incident, its letter and its control

| incident | where on the chain | the control that would have caught it | in this course |
|---|---|---|---|
| SolarWinds | E, the build process | isolated, short-lived builds; provenance; a second build compared | lesson 14 (provenance), lesson 16 (the build) |
| Codecov | F, publication of a script | check the hash before running; few secrets in CI | this lesson (hashes), lesson 17 (secrets) |
| tj-actions | a dependency of the build | pin actions by commit; least-privilege tokens | lesson 16 |
| event-stream | a dependency's own chain | read the lockfile diff; provenance to source | lessons 13 and 15 |
| ua-parser-js | F, publication by a stolen account | locked versions; a cooling-off period | lessons 15 and 18 |
| torchtriton | H, package selection | one index; hashes; claimed names | this lesson, lesson 15 |
| xz-utils | B and D, a maintainer and a tarball | build from source; compare tarball and repository; project health | lesson 15 |

Two letters have almost nothing in the table, and that is honest rather than an omission. **A, the
producer, and I, usage, are outside what a pipeline can check.** No control in a build tells you that
the person who wrote the software meant harm, and none tells you that the deployed service was then
configured with a default password. The first is a question about whom you trust; the second is
lessons 9 and 10's territory, and the admission policies there.

### What a team can do this week

The table reads like a programme of work, and most of it is. Ordered by how much each step costs
against how many rows it covers:

1. **One index, and `--index-url` to it.** It removes dependency confusion as a class, and it is a
   configuration change.
2. **A lock with hashes for every dependency.** It turns any changed file, on any index, into a
   refused install. Lesson 15 does it to linkbox in one command.
3. **Actions and base images pinned to a commit and a digest**, which turns a moved tag into nothing.
4. **A cooling-off period** on new releases, so that a release published by a stolen account an hour
   ago is not installed before anybody has looked at it.
5. **A record of what each artefact contains**, so that the morning a dependency is reported as
   compromised, the question "do we have it, and where?" takes minutes. That record is the SBOM, and
   it is lesson 13.
6. **Signed artefacts and provenance**, verified before deployment, which lesson 14 adds.

### What the record has to answer

The incidents share one more thing, which is about the day after rather than the day before. Each
victim spent days or weeks finding out whether it was affected: which builds used the Bash Uploader,
which images had xz 5.6.1, which machines had installed the nightly between two dates. **The
organisations that answered fastest were those that already had a list of what was in each artefact,
made when it was built.** Without that list, the answer is a search through every image and every
server, done in a hurry, while the advisory is in the news.

For linkbox the list would already have answered one question that nobody has asked yet: the image
contains a package, `packaging`, that `requirements.txt` never mentions. Lesson 13 makes the list,
finds it, and explains why it is there.
