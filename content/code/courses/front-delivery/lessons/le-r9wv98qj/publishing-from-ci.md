---
title: Publishing from CI, with a token and a provenance
version: 1
---

**In a team, nobody publishes from their own computer: a workflow publishes when a release is tagged,
with a token that lives only in the repository's secrets.** That makes every published version the output
of a known commit, built on a clean machine, and it means no person's laptop holds a token that can publish
the company's design system.

**This workflow was not run for this course**; it needs a repository and a registry on the internet. It
publishes to **GitHub Packages**, GitHub's registry, which needs no account beyond the repository:

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags: ['v*']

permissions:
  contents: read
  packages: write
  id-token: write

jobs:
  publish:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          persist-credentials: false
      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version: 22.22.0
          registry-url: https://npm.pkg.github.com
          scope: '@planner'
      - run: npm ci
      - run: npm run build
      - run: npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

What each part is for:

- **`on: push: tags`** runs it when a `v…` tag is pushed, which is what `npm version` created.
- **`permissions: packages: write`** lets the workflow's own token publish to GitHub Packages, and nothing
  more; `id-token: write` is for provenance, below.
- **`registry-url` and `scope`** make `setup-node` write an `.npmrc` on the machine pointing `@planner` at
  GitHub's registry, reading the token from `NODE_AUTH_TOKEN`. The token never appears in a file in the
  repository.
- **`npm publish`** then behaves exactly as it did against Verdaccio.

On GitHub Packages the scope has to be the name of the GitHub user or organisation that owns the
repository, so a real `@planner` scope belongs to an organisation called `planner`. That is the registry's
rule, and the one thing about the package's name that changes between a registry on your computer and one
on the internet.

## Provenance

`npm publish --provenance`, run from a supported CI service, attaches a signed statement saying which
repository, which commit and which workflow built the package; the public npm registry shows it on the
package's page and `npm audit signatures` checks it. It answers the question a consumer cannot otherwise
ask: was this version built from the code I can read, or from somebody's laptop? npm documents it for
publishing to the public registry from GitHub Actions and GitLab CI; it is the reason `id-token: write` is
in the permissions, since the statement is signed with a short-lived identity the CI service issues.
