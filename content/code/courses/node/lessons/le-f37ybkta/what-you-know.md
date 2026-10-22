---
title: What javascript lesson 21 already covered
version: 1
---

**javascript lesson 21 was about packages from the side of somebody publishing one; this lesson is
about them from the side of somebody running a server on them.** The first half is assumed here, and
worth a reread if any of it is hazy:

| javascript lesson 21 | what it established |
|---|---|
| a package and `package.json` | a folder of code with a name and a version, installed into `node_modules` |
| versions and ranges | `^1.2.0` accepts any 1.x from 1.2.0 up, `~1.2.0` any 1.2.x, and `1.2.0` exactly that |
| the lockfile | `package-lock.json` records the exact version of everything installed, and is committed |
| pnpm and Yarn | two other package managers with the same job and different layouts on disk |
| an install runs code | a package's `install` scripts run with your permissions, and `--ignore-scripts` refuses them |
| publishing | `npm publish`, and what `files` and `private` decide |

That lesson used a registry of its own on your computer, so that nothing it installed came from
anywhere else. **This one uses the public registry, `registry.npmjs.org`**, because a server's
dependencies come from there. So the versions and the counts in the transcripts are what the registry
held on the day this course was recorded, in October 2026; on your machine a count may differ by a
package or two, and the commands will not.

## What changes when the package is a server

A library is installed into other people's projects, so its `package.json` is a promise to strangers:
which versions of Node it supports, which of its files they may import. **A server is installed in one place, by you**, and its `package.json` is a description of how to
run it. It says which commands start it and test it, which packages it needs in production and which
only on your laptop, and the exact versions that were tested together. Each section of this lesson is one of those.
