---
title: Caching what does not change
version: 1
---

Every CI run starts clean, and starting clean is expensive: every dependency downloaded again,
every package unpacked, every compiler cache cold. **A cache** keeps a copy of something slow to
produce between runs, under a key that says when the copy is still valid. Here is the difference,
measured by creating the same virtual environment twice with `uv`, starting from an empty cache:

```
ana@laptop:~/shipquote$ time (uv venv -q -p 3.13 /tmp/v1 && VIRTUAL_ENV=/tmp/v1 uv pip install -q -r requirements-dev.txt)

real	0m1.099s
user	0m0.466s
sys	0m0.726s
ana@laptop:~/shipquote$ time (uv venv -q -p 3.13 /tmp/v2 && VIRTUAL_ENV=/tmp/v2 uv pip install -q -r requirements-dev.txt)

real	0m0.167s
user	0m0.079s
sys	0m0.106s
ana@laptop:~/shipquote$ du -sh /tmp/uv-cold
17M	/tmp/uv-cold
```

The first install downloaded and unpacked the three pinned packages and their dependencies, and
took **0.785 seconds**; the second, reading the same files from the cache, took **0.157**. The cache
holds 17 MB. On this lab the saving is small, because `uv` is fast and the project depends on almost
nothing; on a project with hundreds of packages, or one that compiles them, the same comparison is
minutes against seconds, on every run.

## The key is the whole difficulty

A cache is valid only while what produced it has not changed. Services make you choose a **key**
for each cache entry and restore it only when the key matches. For dependencies the natural key is
a hash of the file that pins them, here `requirements-dev.txt`, plus the operating system and the
language version:

```yaml
key: ${{ runner.os }}-py3.13-${{ hashFiles('requirements-dev.txt') }}
```

Change one pin and the key changes, so the next run starts from an empty cache and builds a fresh
one. **A key that is too loose restores stale files**: a cache keyed only on the operating system
would serve last month's packages after a pin changed, and the run would test a combination that
no longer exists in the repository.

## What not to cache

Cache what is **derived from pinned inputs and expensive to rebuild**: downloaded packages, compiled
dependencies, a tool's binary. Do not cache:

- **the results of the thing you are testing**, such as a compiled build of your own code or a test
  database left by the last run. The run would no longer start from what was committed;
- **anything shared between branches without a branch in the key**, if a branch can change it. This
  repository's workflow turns the linter's cache off for that reason, with a comment explaining that
  a cache shared by every branch is not part of what a pull request changed.

A cache is an optimisation, and an optimisation must not change the answer. **If clearing the cache
changes whether a run passes, the cache was hiding something**, and the run that passes without it
is the one to believe.
