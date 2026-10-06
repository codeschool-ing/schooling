---
title: The workflow that runs it
version: 1
---

**With the work in a script, the CI configuration only has to prepare a machine and call it.** For
GitHub Actions, that is one file in the repository:

```yaml
name: image

on:
  push:
    branches: [main]
    tags: ["v*.*.*"]

permissions:
  contents: read
  packages: write

jobs:
  image:
    runs-on: ubuntu-24.04
    outputs:
      digest: ${{ steps.pipeline.outputs.digest }}
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0

      - name: Use the containerd image store, which multi-platform builds need
        run: |
          f=/etc/docker/daemon.json
          { sudo cat "$f" 2>/dev/null || echo '{}'; } \
            | jq '.features["containerd-snapshotter"] = true' > daemon.json
          sudo mv daemon.json "$f" && sudo systemctl restart docker

      - name: Log in to GHCR with this job's own token
        run: echo "$TOKEN" | docker login ghcr.io -u "${{ github.actor }}" --password-stdin
        env:
          TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - id: pipeline
        run: sh ci/pipeline.sh
        env:
          REGISTRY: ghcr.io/${{ github.repository_owner }}
          REF_NAME: ${{ github.ref_name }}

      - name: Log out
        if: always()
        run: docker logout ghcr.io
```

**This workflow was not run**: the lab has no GitHub, and its registry stands in for GHCR. Every
command it calls was run, by `ci/pipeline.sh` above. Read it step by step:

- **`on`** runs it for every push to `main` and every tag that looks like a version.
- **`permissions`** gives the job's token what it needs and no more: read the repository, write
  packages. Without it, the token gets whatever the repository's settings grant, which can be more,
  and lesson 15 said who may push is the decision that matters.
- **`actions/checkout` is pinned to a commit**, with the version as a comment. A tag like `v7` can be
  moved by whoever controls that repository, which is lesson 16's argument applied to the pipeline's
  own tools; this repository's workflows pin every action the same way.
- **The containerd image store** is switched on, because a multi-platform build with the default
  builder needs it. Docker Engine 29, the lab's, uses it by default; a runner with an older
  configuration may not.
- **The login uses `GITHUB_TOKEN`**, a token GitHub creates for this job and revokes when it ends,
  passed on standard input, never on the command line. Lesson 15's advice for CI, exactly: a short-lived
  token, and a logout in a step marked `if: always()`, so that it runs even when the pipeline fails.
- **`outputs.digest`** takes the digest the script wrote to `$GITHUB_OUTPUT`, so that a later job, a
  deployment, can run exactly what was pushed, by digest (lesson 16).

GHCR also wants the owner's name in lower case, which a `repository_owner` with capitals would break;
it is one of the details the lab cannot show and the first run on GitHub would.

**Nothing else is in the file, on purpose.** Marketplace actions exist for every step here, logging in,
setting up Buildx, building and pushing, and they are convenient. Each one is code from another
repository running with this job's token, and each hides the command it runs. Plain `docker` commands
run identically on Ana's laptop, which is the whole point of the previous section.
