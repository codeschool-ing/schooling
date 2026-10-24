---
title: Four hosts, and what each one asks of you
version: 1
---

**Vercel, Netlify, Cloudflare Pages and GitHub Pages all serve a folder of static files from a CDN over
HTTPS, and for the planner any of them will do.** Where they differ is in how the folder reaches them,
where their rules live, and what they do with a branch that is not the main one. Those three
differences decide which configuration file sits in your repository, so they are worth knowing before
you pick.

## How the build reaches them

Three of them **build for you**. You connect the repository once, through their dashboard, and from
then on they watch it: each push is checked out on their machine, `npm ci` and the build command run,
and the output folder is published. For a Vite project, Vercel and Cloudflare Pages offer a preset
that fills in `npm run build` and `dist` for you; Netlify detects the same two values, or reads them
from a file you commit.

**GitHub Pages builds nothing by itself.** It publishes either a branch as it is, or whatever a GitHub
Actions workflow uploads. A Vite project needs a build, so it needs the workflow, and the next section
shows the one Vite's documentation gives. That makes GitHub Pages the most work to set up and the one
whose every step you can read in your own repository.

All four can also be handed a folder you built yourself. Vercel, Netlify and Cloudflare each have a
command-line tool for it, and that is how a CI pipeline you control deploys to them instead of letting
them build.

## Where the rules live

A static host does more than map a path to a file: it redirects old addresses, rewrites some to
others, and adds headers. Lesson 4 writes those rules for the planner. What matters here is that each
host reads them from a different place:

| host | rules for redirects and headers |
|---|---|
| Vercel | `vercel.json`, at the root of the repository |
| Netlify | `netlify.toml` at the root, or `_redirects` and `_headers` files in the published folder |
| Cloudflare Pages | `_redirects` and `_headers` files in the published folder |
| GitHub Pages | none: no redirects, no rewrites, no headers you can set |

`_redirects` started as Netlify's format and Cloudflare Pages reads the same one, so a file written for
one mostly works on the other. **GitHub Pages has no rules file at all**, and lesson 4 shows what that
costs an app whose addresses are real paths.

## What a branch gets

**Vercel, Netlify and Cloudflare Pages build every branch, or every pull request, at an address of its
own**, so a reviewer can open the change before it is merged. They call it a preview deployment or a
deploy preview, and lesson 3 is about it. The main branch, or whichever branch you call production,
goes to the site's real address.

GitHub Pages has one site per repository and publishes one thing to it. A preview of a pull request is
something you build yourself, with a workflow and a second place to put it.

## Where they sit

| | Vercel | Netlify | Cloudflare Pages | GitHub Pages |
|---|---|---|---|---|
| builds from the repository | yes | yes | yes | only through Actions |
| rules file | `vercel.json` | `netlify.toml` or `_redirects` | `_redirects`, `_headers` | none |
| a preview per branch or pull request | yes | yes | yes | no |
| a site at the root of its own address | yes | yes | yes | only for `<user>.github.io` or a custom domain |
| a command-line deploy | `vercel` | `netlify deploy` | `wrangler pages deploy` | none: through Actions |

**Vite's guide now lists Cloudflare Workers ahead of Cloudflare Pages**: Workers is a newer product that
serves the same folder and can run code beside it, and Pages still works and is what most tutorials
show. Hosting products move like that, which is the subject of this lesson's last section.

None of this was run for this course. The table is what Vite's deployment guide and Cloudflare's own
documentation said in October 2026, and the next section quotes the steps.
