---
title: Releases, cache and platforms
version: 1
---

**A release is a Git tag, and the pipeline turns it into the tags of lesson 16.** Ana tags the commit
and runs the pipeline as CI would for that tag. First she empties her build cache, so that the build
has only what a fresh CI runner would have:

```
ana@vm:~/shelf$ git tag v1.8.0
ana@vm:~/shelf$ docker builder prune -af | tail -1
Total:	2.277GB
ana@vm:~/shelf$ REF_NAME=v1.8.0 REGISTRY=localhost:5000 TRIVY_CACHE=~/trivy-cache TRIVY_FLAGS="--skip-db-update --skip-version-check --offline-scan" sh ci/pipeline.sh; echo "exit $?"
--- unit tests
--- integration tests
--- scan

Report Summary

┌─────────────────────────────┬──────────┬─────────────────┐
│           Target            │   Type   │ Vulnerabilities │
├─────────────────────────────┼──────────┼─────────────────┤
│ shelf-ci.tar (debian 12.15) │  debian  │        0        │
├─────────────────────────────┼──────────┼─────────────────┤
│ probe                       │ gobinary │        0        │
├─────────────────────────────┼──────────┼─────────────────┤
│ shelf                       │ gobinary │        0        │
└─────────────────────────────┴──────────┴─────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)

--- build and push
pushed localhost:5000/shelf@sha256:5ff1336be28eeba819643a434850b2f86cd580d6f24c5b3981476d00d2cb2168
exit 0
ana@vm:~/shelf$ grep -cE "^#[0-9]+ CACHED" build.log
7
ana@vm:~/shelf$ curl -s localhost:5000/v2/shelf/tags/list | jq -c .tags
["1","1.8","1.8.0","buildcache","main","sha-cb7eee2"]
```

**`1.8.0`, `1.8` and `1` now exist**, from the `case` in the script, alongside the commit's tag. The
digest is not the one the `main` build pushed, although the commit is the same: the version is a build
argument, it is compiled into the binary, and different bytes have a different digest.

## The cache lives in the registry

**Seven steps came back `CACHED`, with the local cache emptied a moment before.** They came from
`buildcache`, the image the previous run wrote with `--cache-to type=registry,…,mode=max`, read back
with `--cache-from`. A CI runner is usually a fresh machine with no cache of its own; without this,
every run downloads the modules and compiles everything, as lesson 12 measured. `mode=max` keeps the
build stage's layers too, not only the final image's, which is where the expensive steps are.

## Two platforms, one tag

```
ana@vm:~/shelf$ docker buildx imagetools inspect localhost:5000/shelf:1.8.0 | grep -E "Platform"
  Platform:    linux/amd64
  Platform:    linux/arm64
  Platform:    unknown/unknown
  Platform:    unknown/unknown
ana@vm:~/shelf$ docker buildx imagetools inspect localhost:5000/shelf:1.8.0 --format "{{json .Provenance}}" | jq -c keys
["linux/amd64","linux/arm64"]
```

**One tag, two images, `linux/amd64` and `linux/arm64`**, and each with its own attestations, the two
`unknown/unknown` entries of lesson 20. A server on an ARM processor pulls `shelf:1.8.0` and gets the
`arm64` image without asking; nothing in a deployment file names the architecture.

## What the deployment receives

The workflow's output is the digest the script printed. A deployment job that reads it runs exactly
the image that passed the tests and the scan, whatever happens to `1.8` or `main` afterwards. That is
where lesson 27 starts: what takes that digest and keeps it running.
