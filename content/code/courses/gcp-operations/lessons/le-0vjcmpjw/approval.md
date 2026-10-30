---
title: Approval gates, rollback and who may promote
version: 1
---

**A target with `requireApproval: true` will not deploy a promoted release until a person approves
it.** The promotion creates a rollout in the state `PENDING_APPROVAL`, Cloud Deploy publishes a
message saying so, and the rollout waits. Approving or rejecting it is a separate permission from
promoting it, and that separation is the gate. Nothing here could run on your computer; it is taught
from Google's documentation, and the commands were not run.

## Promote, then approve

```sh
gcloud deploy releases promote --release=rel-a1b2c3d \
  --delivery-pipeline=shop-api --region=southamerica-east1 --to-target=prod
gcloud deploy rollouts approve rel-a1b2c3d-to-prod-0001 \
  --release=rel-a1b2c3d --delivery-pipeline=shop-api --region=southamerica-east1
```

The two commands need two different roles. `roles/clouddeploy.releaser` may create releases and
promote them; `roles/clouddeploy.approver` may approve or reject rollouts. **Somebody who holds both
can approve their own promotion**, which is a gate with one person standing on both sides of it. In
a team of two, as this platform is, that is sometimes unavoidable; what the record then shows is who
did it and when, which is still more than a deploy from a laptop shows.

An approval is a judgement about evidence, so the evidence should exist before anybody is asked: the
release has run in `dev`, the tests of lesson 1 passed in its build, and lesson 2's scan has no
fixable critical finding on its digest. An approval asked for before those exist is a signature on a
blank page.

## Rollback is a promotion backwards

Rolling back `prod` deploys the release that ran there before, which already exists, rendered and
pinned by digest:

```sh
gcloud deploy targets rollback prod --delivery-pipeline=shop-api --region=southamerica-east1
```

It creates a new rollout of the previous release to `prod`. **Nothing is rebuilt**, so the rollback
cannot fail because a build tool changed overnight, and it lands on exactly the image that ran before.
It also goes through the gate: a rollback to a target with `requireApproval` waits for an approval like
any other rollout, which is worth knowing before the night it is needed.

## Canary, briefly

A stage can also say how to deploy, not only where. With a canary strategy, a Cloud Run target moves a
share of traffic to the new revision in steps you list, `percentages: [10, 50]`, and pauses after each
one until the rollout is advanced. `gcp-compute` lesson 9 covers the traffic split itself; what Cloud
Deploy adds is the order, the pauses, and the same approval and rollback around them.

| Cloud Deploy word | what it is |
|---|---|
| delivery pipeline | the ordered list of stages |
| target | one place to deploy: a Cloud Run region, a GKE cluster |
| release | the manifests for every target, rendered once, images by digest |
| rollout | one release going to one target |
| promotion | creating the rollout to the next target |
