---
title: What GitOps is not
version: 1
---

The word travels further than the idea, so it is worth saying what does not count.

**It is not "we keep our YAML in Git".** Nearly everybody keeps manifests in Git. If a person or a
pipeline still runs `kubectl apply` from a laptop or a CI job, the repository is a record of what
somebody intended, and the cluster can drift from it for months. The principles that make it
GitOps are the third and fourth: the state is pulled, and the pulling never stops.

**It is not continuous deployment.** Continuous deployment is a decision about *when* changes go to
production: every merge, automatically. GitOps is about *how* they get there. A team can use GitOps
and still release once a week, by merging into the production directory once a week; lesson 5
shows how environments and promotion fit into a repository.

**It does not replace CI.** Something still has to test the code, build the image and push it to a
registry. In a GitOps setup that pipeline stops at the registry, or at a commit that names the new
image; it no longer touches the cluster. `testing-cicd` is the course about that pipeline.

**It does not make a bad change safe.** A reconciler applies a broken manifest exactly as faithfully
as a good one, and faster than a person would. What it changes is what happens next: the broken
change is a commit with an author, it can be reverted with another commit, and the revert is
applied by the same loop. Lesson 2 is about catching it before the merge, and lesson 3 about
seeing it after.

**And it does not cover everything.** Some state does not belong in Git: the data in a database,
the secrets themselves, anything generated at run time. Lessons 9 to 11 are about the most
important of those, the secrets, and about how to keep a reference to them in the repository
without keeping the secret there.

## When it is worth it

The costs from the push-and-pull section are real: an agent to run, a delay between merge and
deploy, a repository that must be guarded like production. They pay off in proportion to how many
people change the system and how much it hurts to not know what is running. One person deploying
one service to one cluster gains little. Ten teams deploying to staging and production, with an
auditor asking who changed what, is the case the rest of this course is written for, and lesson 12
answers the auditor.
