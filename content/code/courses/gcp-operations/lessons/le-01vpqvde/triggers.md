---
title: Triggers and substitutions
version: 1
---

**A trigger is the rule that starts a build, and a substitution is how the build learns what
started it.** The `cloudbuild.yaml` of the last section says what to do; it says nothing about when.
A trigger joins a source (a repository, a Pub/Sub topic, a webhook, or a person pressing a button)
to a build file, and when the source moves, Cloud Build reads the file at that commit and runs it.
**None of this section can run on your computer**: triggers live in Cloud Build, and nothing
imitates them. It is taught from Google's documentation, and the commands in it were not run.

## Which event starts a build

A trigger connected to a GitHub repository can fire on three kinds of event:

| event | what it matches | what the shop uses it for |
|---|---|---|
| push to a branch | a regular expression on the branch name, such as `^main$` | every merge to `main` builds an image |
| push of a tag | a regular expression on the tag, such as `^v[0-9]+\.[0-9]+\.[0-9]+$` | a release tag builds the image that goes to production |
| pull request | the base branch the pull request targets | the tests run before anybody reviews |

Two more fields decide whether a matching push builds at all. **`includedFiles` and `ignoredFiles`**
are globs on the paths a commit changed: a trigger with `includedFiles: ["api/**"]` ignores a commit
that touched only the documentation. Leaving them out builds on every commit, which is safe and
costs build minutes; getting them wrong means a change to `api/` that never builds, which is the
expensive failure, because nothing reports it.

For a pull request, the trigger can also require a comment, `/gcbrun`, from a collaborator before it
builds. **A pull request from a fork runs code a stranger wrote, with the trigger's service account**,
and that comment is the line between "the tests run" and "anybody may run anything as our build
account".

The shop's trigger, as `gcloud` creates it for a repository already connected to Cloud Build:

```sh
gcloud builds triggers create github \
  --name=shop-api-main \
  --region=southamerica-east1 \
  --repository=projects/planner-dev/locations/southamerica-east1/connections/github/repositories/shop \
  --branch-pattern='^main$' \
  --included-files='api/**,cloudbuild.yaml' \
  --build-config=cloudbuild.yaml \
  --service-account=projects/planner-dev/serviceAccounts/shop-build@planner-dev.iam.gserviceaccount.com
```

It was not run: the emulators have no Cloud Build. `cloudbuild.yaml` is in `--included-files`
because a change to the build itself should be built.

## Substitutions

The build file of the last section wrote three names with a dollar sign. They are replaced before
the build starts, and they come in two kinds.

**Built-in substitutions** are set by Cloud Build from the event: `$PROJECT_ID` and `$BUILD_ID`
always, and from a repository trigger `$COMMIT_SHA`, `$SHORT_SHA` (its first seven characters),
`$BRANCH_NAME`, `$TAG_NAME` and `$REPO_NAME`. A build started by hand with `gcloud builds submit`
has no commit, so `$SHORT_SHA` is empty there; tagging an image with it would produce the name
`api:`, which the registry refuses.

**User-defined substitutions** begin with an underscore, like `_REGION`. The file gives a default
under `substitutions`, and a trigger can override it, which is how one build file serves two
triggers: `_REGION=southamerica-east1` for one, another region for the other.

Two details are where builds break:

- **A dollar sign meant for the shell is written `$$`.** In `args: ["-c", "echo $$HOME"]` the step's
  shell receives `$HOME`. Written `$HOME`, Cloud Build tries to substitute it, finds no such
  substitution, and refuses the build.
- **An unknown substitution is an error unless you say otherwise.** A trigger that passes
  `_REGOIN` with a typo fails the build rather than ignoring it, and that is the default you want.
  `options.substitutionOption: ALLOW_LOOSE` turns the error off, and with it the only check on the
  typo.

## The service account, again

A trigger runs its build as the service account it names, and that account is what decides what
the build can touch: push to one repository in Artifact Registry, write logs, and nothing more for
the shop's build. **A build is code from the repository, run with the account's permissions**, so
whoever can merge to `main` can do anything that account can do. That is the reason the account is
small and the reason `gcp-foundations` lesson 8 spends a lesson on service accounts.
