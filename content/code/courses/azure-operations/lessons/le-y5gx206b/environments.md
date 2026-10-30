---
title: Environments, and the deployment job
version: 1
---

**An environment in Azure Pipelines is a named target that remembers what was deployed to it.** It is
an object in the project, `shop-production` here, and it does three things a plain job cannot. It keeps
a **history**: every run that deployed to it, with the commit and the pipeline, so "what is in production
now, and since when" has an answer that is not somebody's memory. It carries **checks**: approvals,
business hours, a required template, which lesson 3 sets up. And it is what a **deployment job**
targets.

A deployment job is written `deployment:` instead of `job:`, names its environment, and has a
**strategy**. The pipeline in this lesson uses `runOnce`: every step once, in order. Two more exist:

- **`rolling`** replaces the application on a set of virtual machines a few at a time, for an
  environment whose resources are VMs registered with it;
- **`canary`** deploys to a growing share, with hooks for what to do at each increment and on failure.

```yaml
      - deployment: web
        environment: shop-production
        strategy:
          canary:
            increments: [10, 50]
            deploy:
              steps:
                - script: ./deploy.sh --percent $(strategy.increment)
            on:
              failure:
                steps:
                  - script: ./deploy.sh --percent 0
```

The hooks (`preDeploy`, `deploy`, `routeTraffic`, `postRouteTraffic`, and `on: failure` or
`on: success`) are places to put steps. **Azure Pipelines does not move traffic by itself**: the
`deploy.sh` above is yours, and the strategy only calls it with `10`, then `50`. Moving traffic belongs to
the thing receiving it, which for the shop is App Service and its slots, and lesson 3 does it there.

## What the environment does not know

An environment records that a run deployed to it, not that the deployment worked. A deployment job
that pushed a broken image and exited 0 is a green line in the history. That is why the shop's checks
after a deployment, and lesson 12's alert rules, are queries about what the application is doing rather
than about what the pipeline said.
