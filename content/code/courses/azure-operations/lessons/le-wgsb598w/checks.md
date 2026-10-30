---
title: Approvals and checks, where the deployment lands
version: 1
---

**A check is attached to the thing being deployed to, not to the pipeline.** In Azure Pipelines that is
the environment, or the service connection, or the agent pool. Put an approval in a pipeline and the
team that owns the pipeline can delete it in a pull request; put it on `shop-production` and every
pipeline that targets that environment, written today or next year, waits for it. This is the same
argument lesson 1 made for required templates: protection belongs where the deployment lands.

The shop's production environment carries five. They are configured in Azure DevOps' web interface or
its REST API, and were **not run** here, because the lab has no Azure DevOps organisation. Written out
as a list, they are:

```yaml
# what the environment shop-production carries, as checks
approvals:          # one of the two on-call engineers, never the person who queued the run
business-hours:     # Monday to Friday, 09:00 to 17:00, America/Sao_Paulo
query-alerts:       # Azure Monitor: no fired alert on rg-shop in the last 15 minutes
required-template:  # the run extends secure-build.yml@platform
exclusive-lock:     # one deployment at a time; a newer run supersedes a waiting one
```

When a deployment job reaches the environment, **all checks are evaluated, and the job starts only when
every one passes**. They run in parallel, and a check that fails or times out fails the stage.

**Approval** names who may approve, and how many of them. The useful setting is the one that refuses
the person who queued the run: an approval that the author grants to themselves is a delay rather than
a second pair of eyes. An approval waits for a configurable time and then fails, which is the right
direction; a deployment nobody approved should not happen at three in the morning by itself.

**Business hours** holds the job until a window opens. It encodes a team's rule that nobody deploys
when nobody is around to watch, and costs nothing to keep.

**Query Azure Monitor alerts** is a gate: it asks whether any alert of the kinds you name has fired on a
scope, and passes only if none has. The shop uses it so that a deployment does not start while
production is already in trouble, when a new version would make the incident harder to read. The
alerts themselves are lesson 12's subject. **Invoke Azure Function** and **invoke REST API** are the
general form: a gate that calls your own endpoint and passes on the answer it returns, re-evaluated at
an interval until it passes or times out.

**Exclusive lock** lets one run at a time into the environment. Two deployments racing each other into
the same slot is a failure nobody designs, and nobody notices until the older one wins.
