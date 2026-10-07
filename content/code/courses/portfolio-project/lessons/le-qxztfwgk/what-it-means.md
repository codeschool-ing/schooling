---
title: What deploy means for your project
version: 2
---

For a portfolio, deployed means **a reviewer can see the project working without installing anything**,
and can do it again next month. What that looks like depends on what you built:

::: track frontend mobile
For you it is a page at an address, or a build somebody can install. A static site needs no server at
all: a static host serves the files, and the deploy is a push. An app needs a store listing, a test
build or, at least, a video on a real device. The rest of this lesson is the back half you may not
need; its HTTPS and *stays up* sections still apply to whatever your front end calls.
:::

::: track backend ai prompt
For you it is exactly this lesson: a service at an address, answering over HTTPS, restarted when it
crashes, with a health check. If the service calls a model, the key lives in the server's environment,
lesson 14, and the health check should not spend money every thirty seconds.
:::

::: track data data-science bi
For you it is the result on a schedule: a pipeline that runs every night and a place its output can be
seen, a rendered report, or a dashboard at a link. The *stays up* half of this lesson becomes *runs
again*: a scheduled job that fails loudly when it fails.
:::

::: track devops devsecops cloud-engineering
For you this lesson is the centre of the project. Everything below is done by hand once so it can be
seen; your project is the version where a commit does it, the infrastructure is code, and a bad deploy
rolls back. Record both: the manual run is how a reviewer understands what the pipeline automates.
:::

::: track it-support networks-infra dba
For you it is an environment someone else can rely on: a service or a lab that keeps running, is
documented well enough to rebuild, and has a restore that was tested. This lesson's commands are a
runbook in the making; write them down as one.
:::

::: track qa security
For you it is the target, running where your tests or your assessment can reach it, and reset to a
known state between runs. Deploy the system under test exactly as this lesson does, in a lab you
control, so every finding can be reproduced.
:::

::: track *
Whatever you built, deployed means somebody can see it working without you, next month as well as
today. Read the rest of this lesson for the parts that apply.
:::

Everything that follows happens in a lab you build in the next section: **srv** is a server on a private
network between it and your computer, not on the internet, and its address, `loans.lab`, is a name only
your computer knows. That is deliberate. A lab deploy can be repeated by anybody, forever, and costs
nothing; the last section says what changes when the server is public.
