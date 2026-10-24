---
title: Caching, and what it may and may not keep
version: 1
---

**A CI machine starts empty every time, so every run downloads every dependency again, unless something
keeps the downloads between runs.** `cache: npm` in the workflow is that something: it saves npm's
download cache at the end of a run and restores it at the start of the next, keyed by a hash of
`package-lock.json`. Same lockfile, same cache.

The difference is easy to measure on your own computer, because npm keeps the same kind of cache in your
home folder. Install with an empty cache, which is a CI machine's first run, then with a warm one:

```
ana@dev:~/planner$ rm -rf node_modules /tmp/empty-cache && time npm ci --cache /tmp/empty-cache > /dev/null

real	0m2.767s
user	0m2.623s
sys	0m1.421s
ana@dev:~/planner$ rm -rf node_modules && time npm ci --cache /tmp/empty-cache > /dev/null

real	0m1.812s
user	0m1.644s
sys	0m1.016s
```

The first run fetched every package from the registry; the second found them in the cache and only
unpacked them. Here the gap is about a second, because this machine sits close to the registry and the
planner has a few dozen packages. On a slower network, or a project with hundreds of packages, the same
gap is minutes per run, multiplied by every push.

## What is cached, and what is not

**The cache holds downloads, never `node_modules`.** `npm ci` still deletes `node_modules` and builds it
again from the lockfile on every run; the cache only spares it the network. That is deliberate. A cached
`node_modules` is a folder from an earlier run with whatever state it was left in, which is the exact
thing a clean checkout exists to rule out.

Three rules follow from the key being the lockfile:

- **a changed lockfile is a fresh cache.** Upgrading a dependency costs one slow run, then the new
  cache is warm.
- **the cache cannot change what is installed.** If it holds a package the lockfile does not name, `npm
  ci` ignores it, and integrity hashes in the lockfile reject a download that was tampered with.
- **nothing secret goes in a cache.** Caches are shared across the branches of a repository in ways the
  platform documents and few people read; treat one as public within the repository.

The build's own output, `dist/`, is not cached either. It is the thing being checked, so it is made
fresh on every run.
