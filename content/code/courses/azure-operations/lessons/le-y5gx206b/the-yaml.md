---
title: Stages, jobs and steps
version: 1
---

**An Azure Pipelines definition is a YAML file in the repository**, usually `azure-pipelines.yml` at
its root, and Azure DevOps reads it from the commit it runs. That is the point of it: the pipeline is
reviewed in the same pull request as the code it builds, and an old commit rebuilds with the pipeline
it had then. The older "classic" pipelines, drawn in a web editor, still exist and are not taught here,
because a pipeline nobody can diff is a pipeline nobody reviews.

This is the shop's. It was **not run**: running it needs an Azure DevOps organisation, a project, and a
service connection to a subscription, none of which exists in the lab.

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include: [main]

pool:
  vmImage: ubuntu-24.04

variables:
  image: crshop.azurecr.io/shop/api

stages:
  - stage: Build
    jobs:
      - job: test_and_push
        steps:
          - script: python -m pip install -r requirements.txt
            displayName: Install
          - script: python -m unittest discover -s tests
            displayName: Test
          - task: Docker@2
            displayName: Build and push
            inputs:
              containerRegistry: crshop
              repository: shop/api
              command: buildAndPush
              tags: $(Build.SourceVersion)

  - stage: Deploy
    dependsOn: Build
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - deployment: web
        environment: shop-production
        strategy:
          runOnce:
            deploy:
              steps:
                - task: AzureWebAppContainer@1
                  inputs:
                    azureSubscription: shop-production
                    appName: app-shop-api
                    deployToSlotOrASE: true
                    resourceGroupName: rg-shop
                    slotName: staging
                    containers: $(image):$(Build.SourceVersion)
```

Read it as three levels nested inside each other.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A pipeline drawn as a tree. The pipeline holds two stages, Build and Deploy, with an arrow from Build to Deploy marked dependsOn. Build holds one job, test_and_push, which holds three steps. Deploy holds one deployment job, web, tied to the environment shop-production. Each job runs on a fresh agent.\"><defs><marker id=\"ah-tree\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"210\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"40\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">pipeline: azure-pipelines.yml</text><rect x=\"40\" y=\"55\" width=\"300\" height=\"160\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">stage Build</text><rect x=\"380\" y=\"55\" width=\"300\" height=\"160\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"530\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">stage Deploy</text><path d=\"M340 72 L378 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah-tree)\"></path><text x=\"360\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">dependsOn</text><rect x=\"55\" y=\"88\" width=\"270\" height=\"115\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"190\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">job test_and_push</text><text x=\"190\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">step: Install</text><text x=\"190\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">step: Test</text><text x=\"190\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">step: Build and push</text><text x=\"190\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">one fresh agent</text><rect x=\"395\" y=\"88\" width=\"270\" height=\"115\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"530\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">deployment web</text><text x=\"530\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">environment: shop-production</text><text x=\"530\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">step: AzureWebAppContainer</text><text x=\"530\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">another fresh agent</text></svg>", "caption": "Stages run in order, jobs run on agents, steps run inside a job. Only a job owns a machine."}
```

**A stage** is a phase with a name: `Build`, `Deploy`. Stages run in order unless `dependsOn` says
otherwise, and a stage whose `condition` is false is skipped rather than failed. The `Deploy` stage
above runs only after `Build` succeeded and only for `main`; a pull request builds and tests, and
deploys nothing.

**A job** is the unit that gets a machine. Each job is sent to an **agent** from the `pool`: here
`ubuntu-24.04`, one of Microsoft's hosted images, a fresh virtual machine per job that is thrown away
afterwards. Two jobs never share a disk, so a file built in one job is not in the next unless it was
published as an **artifact** and downloaded again. Jobs inside a stage run in parallel when there are
agents free, which is a matter of how many parallel jobs the organisation pays for.

**A step** runs inside a job, in order, on that job's agent. `script` runs a shell command; `task` runs
a packaged step, such as `Docker@2`, with inputs. The number after `@` is the task's major version,
and pinning it matters for the same reason pinning anything does.

## Where the identity comes from

The deploy step names `azureSubscription: shop-production`. That is not a subscription id: it is the
name of a **service connection**, an object in the Azure DevOps project that holds how to sign in to
Azure. Created with **workload identity federation**, it holds no secret at all, and lesson 2 explains
how that works for GitHub Actions, where the mechanism is the same. The step never sees a password;
the agent asks for a token as the connection's identity, and gets one only for the pipeline that was
authorised to use it.

## Paying for agents

Microsoft-hosted agents are billed as **parallel jobs**, not minutes: an organisation has a number of
jobs that may run at the same time, and a free tier with a monthly cap of minutes for private projects.
A self-hosted agent is your own machine running Microsoft's agent program, with its own parallel-job
allowance. The figures change, and this course could not read them from the price list (lesson 1
section 03 says why); check them on Azure DevOps' pricing page before you plan a team around them.
