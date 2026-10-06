---
title: GitHub Actions and GitLab CI, term by term
version: 1
---

Most of what you learn on one service carries over to the other, and to Jenkins, CircleCI, Azure
Pipelines or Bitbucket Pipelines. The names change; the loop of lesson 5 does not. This is the
dictionary for the two the course used:

| idea | GitHub Actions | GitLab CI |
|---|---|---|
| the pipeline file | `.github/workflows/*.yml`, one workflow per file | `.gitlab-ci.yml`, one per repository, with `include` for more |
| what starts it | `on:` | `workflow: rules:` and per-job `rules:` |
| a unit of work on one machine | job | job |
| ordering | `needs:` between jobs | `stages:` in order, or `needs:` for a graph |
| a command | a step with `run:` | a line of `script:` |
| a reusable packaged step | an action, `uses: owner/repo@sha` | a CI/CD component, or `include:` of a template |
| where it runs | `runs-on:` a hosted or self-hosted runner | a runner, chosen by `tags:`, usually inside `image:` |
| matrix | `strategy: matrix:` | `parallel: matrix:` |
| run after failure | `if: always()` | `when: always` |
| files between jobs | upload and download artifact actions | `artifacts:`, passed to later stages |
| cache | `actions/cache`, or a setup action's `cache:` | `cache:` with a `key:` |
| test report on the page | uploaded as an artifact, or by an action that annotates | `artifacts: reports: junit:` |
| secrets | `${{ secrets.NAME }}`, per repository or environment | CI/CD variables, masked and protected |
| reusing a pipeline | `workflow_call` | `include:` and `trigger:` |
| one run at a time | `concurrency:` | `resource_group:`, and interruptible jobs |

## Differences that change how you write it

Three differences are more than vocabulary.

**Containers by default.** A GitLab job usually runs inside the image it names, so its environment is
the image; a GitHub-hosted job runs on a full virtual machine and installs what it needs with setup
actions. The GitLab file chose the Python version through the image; the GitHub file through
`setup-python`.

**Stages versus a graph.** GitLab's stages are a simple line: everything in a stage waits for the
whole previous stage. GitHub has only the graph of `needs`. GitLab also offers `needs` for when the
line is too strict.

**Artifacts flow by default in GitLab.** A later stage receives earlier artifacts without asking; on
GitHub every hand-over is an explicit upload and download.

What does not differ is the substance of this course. Both run each job from a clean checkout, both
decide success by exit status, both can keep reports and gate a merge on a check. **Learn the loop
once; look the syntax up.**
