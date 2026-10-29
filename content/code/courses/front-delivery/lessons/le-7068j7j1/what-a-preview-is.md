---
title: What a preview environment is
version: 1
---

**A preview is the site built from a pull request's branch and published at an address of its own,
while the real site carries on unchanged.** A reviewer opens a link instead of checking the branch out,
installing and building it; a designer sees the change on a phone; a product manager clicks through the
new screen before anybody calls it done. It is the review of what the change *does*, beside the review
of what the code *says*.

The common mistake is to think of a preview as a smaller staging site. A staging site is one place,
shared, that the main branch reaches before production. **A preview is one per pull request**, made when
the pull request opens, rebuilt on every push to it, and thrown away when it closes. Ten open pull
requests are ten previews, side by side, none of them disturbing the others.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"The main branch builds to the production address. Three open pull requests each build to an address of their own, side by side, none of them touching production or each other. When a pull request closes, its preview goes.\"><rect x=\"20\" y=\"30\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">main</text><line x1=\"170\" y1=\"52\" x2=\"300\" y2=\"52\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"300.0,52.0 292.6,55.1 292.6,48.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"302\" y=\"30\" width=\"398\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">planner.pages.dev</text><text x=\"690\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">production</text><rect x=\"20\" y=\"86\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">PR #12</text><text x=\"160\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fix-week</text><line x1=\"170\" y1=\"100\" x2=\"300\" y2=\"100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"300.0,100.0 292.6,103.1 292.6,96.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"302\" y=\"86\" width=\"398\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">a1b2c3d4.planner.pages.dev</text><text x=\"690\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">preview</text><rect x=\"20\" y=\"122\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">PR #13</text><text x=\"160\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">green-heading</text><line x1=\"170\" y1=\"136\" x2=\"300\" y2=\"136\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"300.0,136.0 292.6,139.1 292.6,132.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"302\" y=\"122\" width=\"398\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">e5f6a7b8.planner.pages.dev</text><text x=\"690\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">preview</text><rect x=\"20\" y=\"158\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">PR #14</text><text x=\"160\" y=\"172\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">durations</text><line x1=\"170\" y1=\"172\" x2=\"300\" y2=\"172\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><polygon points=\"300.0,172.0 292.6,175.1 292.6,168.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"302\" y=\"158\" width=\"398\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">c9d0e1f2.planner.pages.dev</text><text x=\"690\" y=\"172\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">preview</text></svg>", "caption": "One preview per pull request, each at its own address; production moves only when main does."}
```

## How the hosts do it

Vercel, Netlify and Cloudflare Pages all build previews once the repository is connected, as lesson 1
said, and each posts the preview's address on the pull request, as a comment or as the link of a check.
Their addresses follow a pattern:

| host | a preview's address |
|---|---|
| Vercel | a unique address per deployment under `.vercel.app`, plus one that follows the branch |
| Netlify | `deploy-preview-<number>--<site>.netlify.app`, the pull request's number |
| Cloudflare Pages | `<hash>.<project>.pages.dev` per deployment, and `<branch>.<project>.pages.dev` following the branch |

Two kinds of address appear there, and the difference matters. **A deployment address never changes
what it shows**: it is that one build, forever, so a link in a review comment still shows what was
reviewed. **A branch address follows the latest push**, which is the one to send somebody who should
see the current state. Neither is the production address, and none of them are run here; they are what
the hosts' documentation describes.

## What a preview is not

It is not a test environment with its own data. The planner's previews read the same `courses.json`
their branch carries, which is fine. An app that talks to an API has to decide which API a preview
talks to, and the answer is never production's: lesson 2 gave previews the staging values, and the last
section of this lesson says why that decision is a security one.
