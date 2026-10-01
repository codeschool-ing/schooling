---
title: "Vercel and Netlify: a website from a git push"
version: 1
---

Vercel and Netlify are listed beside Lambda as serverless platforms, and they are, but they sell a
different thing. **They are platforms for front-end websites: you connect a git repository, and
every push is built and deployed without you touching a server.** In lesson 1's terms they are PaaS
for the web, with functions as one feature among several.

The workflow is the product:

1. You connect the repository and say which framework it uses, or the platform detects it: a static
   site generator, Next.js (which Vercel makes), Astro, SvelteKit and others.
2. Each push to the main branch runs the build and publishes the result as the live site. The static
   files are served from a CDN.
3. **Each pull request gets a preview URL of its own**: a complete copy of the site built from that
   branch, which a reviewer can open and click through before anything is merged.
4. Rolling back is pointing the live address at an earlier build, which already exists and does not
   have to be built again.

The third step is the one teams adopt these platforms for. **A change to a page is reviewed as a
page, by whoever needs to see it, rather than as a diff by whoever can read one.**

## The functions ride along

The API part of a site lives in the same repository. **A file in a conventional folder becomes a
function, deployed with the site and answering under the same domain**: `api/` on Vercel,
`netlify/functions/` on Netlify. A contact form, a login callback or a search endpoint is a few
lines beside the pages that use it, with no separate service to deploy. Both platforms also run code
at the edge, before a request reaches the cache, for redirects and the like.

Those functions are the model of this lesson, with its limits: a maximum duration, no state between
calls, cold starts where the runtime has them. Both platforms price by plan, with allowances for
bandwidth, builds and function use and a charge for what goes over them. The terms change, and they
are on each platform's own pages.

## Where they fit, and where they do not

They fit a marketing site, a documentation site, a portfolio, the front end of an application whose
back end lives elsewhere, and a small product whose whole API is a handful of functions.

**They fit badly when the back end is most of the product.** Long jobs, queues, heavy work against a
database and anything needing its own network belong on a platform built for them, with the front
end on Vercel or Netlify calling it. And each platform's conventions, its folders and its
configuration file are its own, so **moving between the two is a small migration rather than a
copy.**
