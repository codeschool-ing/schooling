---
title: What a preview must never hold
version: 1
---

**A preview is a public website.** Its address is long and unlisted, and that is all: anybody who has the
link can open it, the link is pasted into pull requests, chat threads and tickets, and nothing stops it
travelling further. Cloudflare's documentation says so plainly: preview deployments are public by
default, and access to them is something you turn on. Treat every preview as published, because it is.

## Four rules that follow

1. **No production secrets, and no production data.** A preview built with production's values talks
   to production's API, as whoever opens it. A preview gets the staging values, set per environment at
   the host as lesson 2 showed, and a staging API with staging data.
2. **No unfinished secrets either.** A feature announced next month, a price not yet public, a partner's
   name: a preview of that branch publishes it today. Put such a preview behind the host's access
   control, which all three offer in some form, or do not preview it.
3. **Not in search engines.** A preview indexed by a search engine competes with the real site and shows
   people a version that no longer exists. Cloudflare Pages adds the header `X-Robots-Tag: noindex` to
   preview addresses for this reason; check whether your host does, and add it in the host's rules file
   for previews if not.
4. **Not from strangers, unattended.** A pull request from a fork can change the build itself, and a
   build runs whatever its `package.json` says. Hosts and GitHub both hold back secrets from such builds,
   as lesson 2 showed, and some ask a maintainer to approve the build first. Leave those defaults on.

## And what to check before saying a preview is fine

A preview proves that the branch builds and that its pages look right **at the preview's address**. Two
things it does not prove, and both come up in lesson 4: that the redirects and rewrites behave the same
under the production domain, and that a direct visit to a deep address works on the host's production
settings. Most hosts apply the same rules file to both, which is why the rules belong in the repository
and not in a dashboard.
