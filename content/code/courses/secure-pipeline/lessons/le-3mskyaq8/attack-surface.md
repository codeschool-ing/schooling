---
title: The pipeline is a target, because it holds the keys
version: 1
---

Fifteen lessons have treated the pipeline as the thing that checks: it scans the code, the
dependencies, the secrets and the image, and lesson 14 made it the only party that signs. **Every
one of those jobs makes the pipeline worth attacking.** A CI job holds what a developer's laptop
should not: a token that can write to the repository, credentials for the registry, the key that
signs releases, and often a route to production. Somebody who can make the job run a line of their
choosing gets all of it, for the length of that job, without touching a single production machine.

### What a job holds, and who can steer it

The common picture is that a pipeline runs "our code". It runs whatever the event that started it
says to run. On most platforms several of those events can be started by people outside the team:

| what the job holds | where it comes from | who can influence what runs |
|---|---|---|
| a repository token | the CI platform, for each job | whoever wrote the workflow file, and whoever's code the job checks out |
| registry credentials | the platform's secret store | the same, plus every action the job uses |
| a signing key | the CI server's own files, as in lesson 14 | every script the build runs, since `ci/sign.sh` comes from the commit |
| network reach | the runner's place on the network | anything the job executes |

**The right-hand column is the attack surface**, and it is longer than it looks: a pull request
from a stranger, the title somebody typed on that pull request, the author of an action the
workflow names by tag, and the person who controls the machine the runner is on.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"sp-l16-surface\" aria-label=\"A CI job in the middle, holding a repository token, registry credentials, a signing key and network reach. Four parties can influence what it runs: the author of a pull request, whoever typed text into the pull request, the author of an action named by tag, and whoever controls the runner machine.\"><defs><marker id=\"sp-l16-surface-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l16-surface-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"20\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pull request author</text><text x=\"110.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the code it checks out</text><path d=\"M210 42 L268 130\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l16-surface-ah-amber)\"></path><rect x=\"10\" y=\"80\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pull request text</text><text x=\"110.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">title, branch name, body</text><path d=\"M210 102 L268 130\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l16-surface-ah-amber)\"></path><rect x=\"10\" y=\"140\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">action author</text><text x=\"110.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a tag they can move</text><path d=\"M210 162 L268 130\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l16-surface-ah-amber)\"></path><rect x=\"10\" y=\"200\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">runner owner</text><text x=\"110.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the machine itself</text><path d=\"M210 222 L268 130\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l16-surface-ah-amber)\"></path><rect x=\"270\" y=\"95\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a CI job</text><text x=\"350.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ci/pipeline.sh</text><text x=\"600\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what it holds</text><rect x=\"500\" y=\"25\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">repository token</text><path d=\"M430 130 L498 45\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l16-surface-ah-paper-dim)\"></path><rect x=\"500\" y=\"80\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">registry credentials</text><path d=\"M430 130 L498 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l16-surface-ah-paper-dim)\"></path><rect x=\"500\" y=\"135\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">signing key</text><path d=\"M430 130 L498 155\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l16-surface-ah-paper-dim)\"></path><rect x=\"500\" y=\"190\" width=\"200\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">network reach</text><path d=\"M430 130 L498 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l16-surface-ah-paper-dim)\"></path></svg>", "caption": "Everything on the left can change what the job runs, and the job holds everything on the right while it runs."}
```

### Incidents that went through the pipeline

Lesson 12 placed real incidents on the supply chain. Two of them went through exactly this door,
and they are worth reading again from the pipeline's side.

- **Codecov, 2021.** The Bash uploader that thousands of pipelines downloaded and ran on every job
  was altered at its source to send the job's environment variables elsewhere. Every pipeline that
  ran it handed over whatever credentials its jobs held. Nothing in those repositories changed.
- **tj-actions/changed-files, 2025.** A widely used GitHub Action had its version tags moved to a
  commit that printed the runner's secrets into the job's log. Every workflow that named the action
  by tag ran the new commit on its next run; workflows that named it by commit did not.

Neither incident needed a flaw in the victims' own code. **Both turned on what a job trusted
without checking**: a script fetched at run time, and a tag somebody else could move.

### What this lesson does about it

Four controls, each a few lines, and each one shown on linkbox:

1. **Least privilege for the job's token**: declare the permissions the job needs, and nothing
   else.
2. **Untrusted input stays data**: what a pull request's author wrote reaches a shell through an
   environment variable, never pasted into the script.
3. **Third-party code by commit**: every action pinned to a full commit hash, with the version in a
   comment for the reader.
4. **The runner is part of the trust**: a fresh machine per job where possible, and a clear account
   of what the machine itself lets a job do.

The first three are properties of a workflow file, which is why the next section writes linkbox's
pipeline for GitHub Actions and lets a scanner read it. The fourth is about machines, and this
course's own CI is the example. **GitHub's hosted runners are not used anywhere in this lesson**:
the recording machine cannot run them, so every workflow here is read and audited, never executed,
and what GitHub does with one is taken from GitHub's documentation.
