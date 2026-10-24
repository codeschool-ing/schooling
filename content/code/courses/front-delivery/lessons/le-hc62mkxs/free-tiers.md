---
title: Free tiers, and choosing one
version: 1
---

**All four hosts serve a site like the planner for nothing, and all four can change that on their own
schedule.** A free plan is a business decision somebody else makes, and it is revised: limits move,
features go to paid plans, products are renamed or replaced. That is why this course quotes no limits
and no prices. A number written here in October 2026 would be wrong somewhere before you read it.

**The walk-through of putting a project on a free tier, with a domain, is portfolio-project lesson
15**, and that lesson is the one to follow when you publish the planner, or anything else, for people
to see. It says what to check on a provider's own current pages before you trust a free tier: whether
it sleeps, whether it expires, whether it needs a card, where your data lives, and how you leave.
This section adds only what is particular to a static front end.

## What a static site spends

A static site has no process to keep running, so the limits a back end hits first (memory, hours of
uptime, a server that sleeps) do not apply. What a static host counts instead is:

- **bandwidth**: how many bytes leave its CDN in a month. The planner is a few kilobytes and never comes
  near it; a site full of large pictures or videos can.
- **build minutes**: how long its machines spend running your build. Every push to every branch is a
  build when previews are on, which is the reason lesson 3 runs the checks before the deploy and not
  after.
- **how many sites, members or deployments** an account may have.
- **what the free plan may be used for.** Read the terms rather than the pricing page. Vercel has
  described its free plan as being for personal, non-commercial projects; GitHub has written that Pages
  is not meant to run an online business. A portfolio is fine on all four; a shop is a different
  question.

## Choosing

For this course's app the choice is about how you want to work, not about what the host can do:

| if you want | take |
|---|---|
| every step in your own repository, and no second account | GitHub Pages, with the workflow from two sections back |
| a preview for every pull request, with no workflow to write | Vercel, Netlify or Cloudflare Pages |
| the same `_redirects` file to work on two hosts | Netlify or Cloudflare Pages |
| to build in your own CI and upload the result | any of the three with a command-line tool |

## Keep the way out open

**The project is portable as long as the host's rules live in the repository.** `dist/` is the same
folder on every host; what ties a site to one is configuration typed into a dashboard: a redirect, an
environment variable, a build setting. Each of those is a fact about your site that lives only in
somebody else's database, where nobody reviews it and nobody can see it change.

So the rule for the rest of this course is the one the four hosts make possible: **what can be a file in
the repository is a file in the repository**. `netlify.toml`, `vercel.json`, `_redirects`, the GitHub
Pages workflow. Lesson 2 is about the one thing that should not be: a secret.
