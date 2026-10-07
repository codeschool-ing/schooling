---
title: An environment per pull request
version: 1
---

Shared staging has a scheduling problem: two teams want to try two changes at once, and one waits or
both test a mix of the two. A **preview environment**, also called an *ephemeral* or *review*
environment, solves it by creating a fresh environment for each pull request, deploying that pull
request's build to it, and destroying it when the pull request closes.

In the lab an environment is a directory and a port, so a preview for pull request 42 is cheap to
show:

```
ana@laptop:~/shipquote$ cat ~/envs/pr-42/config.env
SHIPQUOTE_PORT=8442
ana@laptop:~/shipquote$ time ops/deploy.sh pr-42 dist/shipquote-1.5.0.tar.gz
smoke: http://127.0.0.1:8442 is up and running 1.5.0

real	0m0.168s
user	0m0.035s
sys	0m0.032s
ana@laptop:~/shipquote$ kill $(cat ~/envs/pr-42/pid) && rm -rf ~/envs/pr-42 && ls ~/envs
dev
production
staging
```

One line of configuration, one deploy, and the smoke test passed: **0.168 seconds** to create an
environment and prove it answers. Then it is stopped and deleted, and `~/envs` holds the three
permanent ones again. On a real platform the steps are the same, and slower: create the
infrastructure, often from the same definition as staging; deploy; post the address on the pull
request so reviewers can click it; tear everything down on merge.

## What they buy, and what they cost

Preview environments let a reviewer **see** a change rather than imagine it, and let several changes
be tried at once without stepping on each other. They also force a useful discipline: if an
environment must be created from nothing for every pull request, its definition has to be complete
and automated, which closes most of the drift of section 07 as a side effect.

The cost is in the parts that do not scale down. A preview needs data, which should be seeded, never
copied from production; it needs integrations, usually sandboxes shared by every preview; and it
needs a budget, because forty open pull requests can mean forty environments. Teams set a lifetime,
destroy previews of inactive pull requests, and keep previews of the parts that matter to reviewers
rather than of the whole system.

## The rule the lab's preview follows

The preview ran **the same artifact** as staging and production, `shipquote-1.5.0.tar.gz`, with its
own configuration. A preview that builds its own special version, with debugging switched on or a
fake carrier compiled in, would show reviewers something that will never be deployed. The pull
request's build is what goes to the preview, built the same way as a release.
