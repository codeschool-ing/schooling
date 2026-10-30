---
title: Immutable tags, and the images nobody uses any more
version: 1
---

**An Artifact Registry repository can refuse to move a tag.** With immutable tags turned on, a push
that would point an existing tag at a different image is refused, and the tag stays where it was. The
last section's second push of `v1` would have failed instead of succeeding in silence. The registry on
your computer has no such setting, so nothing in this section was run; it is taught from Google's
documentation.

It is a property of the repository, set when it is created or later:

```sh
gcloud artifacts repositories update shop \
  --location=southamerica-east1 \
  --immutable-tags
```

Three things follow, and the first surprises people:

- **It applies to every tag in the repository**, including `latest`. A build that pushes `:latest`
  on every merge fails from its second run once the setting is on. Drop `latest` from the build, or
  keep it in a repository of its own.
- **A tag can still be deleted** by somebody allowed to delete, and then pushed again pointing
  elsewhere. Immutability stops the accident, not a person who wants to move a tag on purpose and has
  `roles/artifactregistry.repoAdmin`.
- **It costs nothing**, and nothing about pulling changes.

The shop turns it on for `shop`. A tag from `$SHORT_SHA` names one commit, so it never needs to
move, and a push that tries to move one is a build that has gone wrong.

## Cleanup policies

Every build pushes an image, and nothing deletes one by itself. At 440 builds a month and some 50 MB
an image, the shop's repository would grow by about 22 GB a month. Storage is billed by the gibibyte
and the hour: the pricing page, read on 30 October 2026, gives 0.000136986 USD per GiB-hour after the
first 0.5 GiB a month, the same for every region, which is 0.10 USD per GiB for a 730-hour month. A
year of keeping everything is about 264 GB and 26 USD a month by the end of it, for images nobody will
ever pull.

A **cleanup policy** is a list of rules on the repository, each one `DELETE` or `KEEP`, with a
condition. Artifact Registry applies them about once a day. `KEEP` wins over `DELETE`, so the usual
shape is one broad deletion and narrow exceptions. The shop's, in a file `cleanup.json`:

```json
[
  {
    "name": "delete-untagged-after-a-week",
    "action": {"type": "Delete"},
    "condition": {"tagState": "untagged", "olderThan": "7d"}
  },
  {
    "name": "delete-tagged-after-90-days",
    "action": {"type": "Delete"},
    "condition": {"tagState": "tagged", "olderThan": "90d"}
  },
  {
    "name": "keep-the-last-ten",
    "action": {"type": "Keep"},
    "mostRecentVersions": {"packageNamePrefixes": ["api"], "keepCount": 10}
  }
]
```

```sh
gcloud artifacts repositories set-cleanup-policies shop \
  --location=southamerica-east1 \
  --policy=cleanup.json \
  --dry-run
```

**`--dry-run` is the first run, always.** In that mode Artifact Registry deletes nothing and writes to
Cloud Logging, which lesson 9 reads, what it would have deleted; a rule written backwards shows up
there instead of in production. Neither command was run here.

What a policy must never delete is an image something is still running. **A policy knows tags and
ages; it does not know your deployments.** An API that has run the same image for four months, with
nobody deploying, is exactly the image the 90-day rule deletes, and the next restart fails to pull.
The `Keep` rule for the last ten versions is the guard for that, and the reason the shop deploys often
enough that ten versions cover anything running.
