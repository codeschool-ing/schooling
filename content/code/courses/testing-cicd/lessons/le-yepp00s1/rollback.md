---
title: Going back to the release before
version: 2
---

Not every environment has two sides and a router. Lesson 7's production is one directory with a
`current` link and a `previous` link, and `ops/rollback.sh` swaps them. Lesson 7 section 06 shows
the script whole; this is its working part:

```sh
[ -L "$root/previous" ] || { echo "rollback: $env has no previous release" >&2; exit 1; }
before=$(readlink "$root/previous")
ln -sfn "$(readlink "$root/current")" "$root/previous"
ln -sfn "$before" "$root/current"
"$(dirname "$0")/restart.sh" "$env"
set -a; . "$root/config.env"; set +a
"$(dirname "$0")/smoke.sh" "http://127.0.0.1:$SHIPQUOTE_PORT" "${before#releases/shipquote-}"
```

Here production has just received 1.6.0, with 1.5.0 before it. To get there, the router goes
first, with Ctrl-C in its terminal, then the two sides, so that port 8300 is the single
production's again, and then the two deploys:

```sh
kill $(cat ~/envs/production-blue/pid ~/envs/production-green/pid)
ops/deploy.sh production dist/shipquote-1.5.0.tar.gz
ops/deploy.sh production dist/shipquote-1.6.0.tar.gz
```

What it looks like:

```
ana@laptop:~/shipquote$ readlink ~/envs/production/current ~/envs/production/previous
releases/shipquote-1.6.0
releases/shipquote-1.5.0
ana@laptop:~/shipquote$ curl -s "http://127.0.0.1:8300/quote?cep=57020-050&weight=700&subtotal=8990"; echo
{"error": "internal error"}
ana@laptop:~/shipquote$ time ops/rollback.sh production
smoke: http://127.0.0.1:8300 is up and running 1.5.0

real	0m1.941s
user	0m0.091s
sys	0m0.047s
ana@laptop:~/shipquote$ readlink ~/envs/production/current ~/envs/production/previous
releases/shipquote-1.5.0
releases/shipquote-1.6.0
ana@laptop:~/shipquote$ curl -s "http://127.0.0.1:8300/quote?cep=57020-050&weight=700&subtotal=8990"; echo
{"cep": "57020-050", "zone": "NE", "cents": 2940, "price": "R$ 29,40"}
```

The quote to Alagoas fails, `rollback.sh` runs, and the same quote succeeds. `current` and
`previous` have changed places, and the smoke test confirms the version that is now answering.

## What made it fast

1.94 seconds, and almost all of it was the restart, the recreate gap of lesson 10. Nothing was
built, downloaded or unpacked:

- **The old release was still on disk**, in `releases/`, exactly as it was deployed. Rolling back
  meant pointing at it, not reconstructing it.
- **It was the same artifact** that had run before, with the same checksum. Rebuilding 1.5.0 from
  its tag would give a new artifact that has never run anywhere, and lesson 7 explained why that
  is a different thing.
- **The configuration did not move.** `config.env` belongs to the environment, not to the release,
  so going back changed the code and nothing else.

A team that rolls back by reverting a commit and waiting for the pipeline to build and deploy the
result is rolling forward to a new release that happens to look like an old one. It can be the
right move, as section 07 explains, but it is not fast, and during an incident speed is what
rollback is for.
