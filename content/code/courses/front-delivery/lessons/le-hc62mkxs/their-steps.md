---
title: Their steps, as they document them
version: 1
---

**Nothing in this section was run for this course.** Each host needs an account, and each one's
screens change more often than a course can follow. What is quoted here is the shape of the steps as
Vite's deployment guide and the hosts' own documentation gave them in October 2026; where a screen and
this text disagree, the screen is right. The files are the part that lasts, because they live in your
repository and you can read them in a year.

Every one of them starts from the same place: **the planner pushed to a repository on GitHub**, with
`npm run build` writing `dist/`.

## Vercel

1. Sign in at vercel.com with your GitHub account and choose to import a project.
2. Pick the repository. Vercel detects Vite and fills in the build command, `npm run build`, and the
   output directory, `dist`.
3. Deploy. The site is published at an address ending in `.vercel.app`.

From then on, a push to the production branch, `main` unless you change it, updates the site, and a push
to any other branch gets a preview deployment of its own. The planner needs no `vercel.json` to be
served; lesson 4 adds one for its addresses. Vercel's command-line tool deploys a folder from your own
machine: `npx vercel` for a preview, `npx vercel --prod` for production, after `npx vercel login`.

## Netlify

1. Sign in at netlify.com and choose to import an existing project from Git.
2. Pick the repository and the branch, and check the two values Netlify detected.
3. Deploy. The site is published at an address ending in `.netlify.app`.

The two values can also live in the repository, which is better, because then they are reviewed like
code and survive a change of account:

```toml
# netlify.toml
[build]
  command = "npm run build"
  publish = "dist"
```

Pull requests get a **deploy preview**, and the production branch updates the site. The command-line
tool is `netlify-cli`: `npx netlify deploy` uploads a folder to a draft address, and
`npx netlify deploy --prod` to the site.

## Cloudflare Pages

1. In the Cloudflare dashboard, under **Workers & Pages**, create a project, choose **Pages**, and
   connect the Git repository.
2. Choose the framework preset for Vite, or enter `npm run build` and `dist` yourself.
3. Save and deploy. The site is published at `<project>.pages.dev`.

Each push to another branch gets a preview at `<hash>.<project>.pages.dev`, plus an alias named after the
branch. Cloudflare calls the other route **Direct Upload**, where you build and it only serves:

```sh
npx wrangler pages project create
npx wrangler pages deploy dist
```

Its documentation warns that a project created this way cannot be switched to the Git integration later,
so choose before the first deploy.

## GitHub Pages

1. In the repository, open **Settings**, then **Pages**, and under **Build and deployment** set the
   **Source** to **GitHub Actions**.
2. Commit a workflow that builds the site and hands `dist/` to Pages.

This is the workflow from Vite's guide, with two changes for this course: Node 22, as everywhere else
here, and the `--base` flag that the next section explains.

```yaml
# .github/workflows/deploy.yml
name: Deploy static content to Pages

on:
  push:
    branches: ['main']
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: 'pages'
  cancel-in-progress: true

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - name: Set up Node
        uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0
        with:
          node-version: 22
          cache: 'npm'
      - name: Install dependencies
        run: npm ci
      - name: Build
        run: npm run build -- --base=/planner/
      - name: Setup Pages
        uses: actions/configure-pages@45bfe0192ca1faeb007ade9deae92b16b8254a0d # v6.0.0
      - name: Upload artifact
        uses: actions/upload-pages-artifact@fc324d3547104276b827a68afc52ff2a11cc49c9 # v5.0.0
        with:
          path: './dist'
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@368f82528645a54fb793d4d04e342629a3f51346 # v5.0.1
```

You do not need to follow every line yet; lesson 3 takes a workflow apart, including why each `uses:`
names a forty-character commit rather than a version. In outline: on every push to `main`, a fresh
Ubuntu machine checks the repository out, installs Node 22 and the exact dependencies in the lockfile,
builds, and passes `dist/` to the two Pages steps, which publish it at
`https://<user>.github.io/planner/`. The `permissions` block gives the workflow the right to publish and
nothing else.

## What all four have in common

Read the four lists again and the same three values appear in every one: **the repository, the command
`npm run build` and the folder `dist`**. That is the contract between your project and any host, and it
is why the project is portable: nothing in `dist/` knows which of them serves it. What is not portable is
the rules file, which is why lesson 4 writes the planner's rules for each of them.
