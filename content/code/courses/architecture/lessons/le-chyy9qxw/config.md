---
title: III, config in the environment
version: 1
---

**Config is everything that changes between deploys of the same code**: the database's address, the
port, credentials for other services, the name of the bucket files go to. It is not the routes, the
business rules or the list of products; those are code, and they are the same everywhere.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"One image in the middle, the same bytes, deployed to three environments: on a laptop, in staging and in production. Each environment gives the process a different DATABASE_URL and a different PORT; the image does not change.\"><defs><marker id=\"l4-config-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"240\" y=\"24\" width=\"240\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">quitanda/catalogue:1.0.0</text><rect x=\"30\" y=\"110\" width=\"204\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"132\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">laptop</text><text x=\"132\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">DATABASE_URL</text><text x=\"132\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">db:5432</text><path d=\"M360 70 L132 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-config-ah-amber)\"></path><rect x=\"258\" y=\"110\" width=\"204\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">staging</text><text x=\"360\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">DATABASE_URL</text><text x=\"360\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pg-stg:5432</text><path d=\"M360 70 L360 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-config-ah-amber)\"></path><rect x=\"486\" y=\"110\" width=\"204\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"588\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">production</text><text x=\"588\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">DATABASE_URL</text><text x=\"588\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pg-prod:5432</text><path d=\"M360 70 L588 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l4-config-ah-amber)\"></path></svg>", "caption": "One image, three environments. What differs between them is in the environment, never in the image, so the image that passed the tests is the image that runs."}
```

The factor says config lives in environment variables, and the catalogue reads two of them. The
running container has them:

```
ana@vm:~/lab/twelve$ docker compose exec catalogue printenv DATABASE_URL PORT
postgresql://quitanda:quitanda@db:5432/quitanda
8000
```

The useful test the twelve-factor text gives is this: **could the code be published as open source
right now, without leaking a single credential?** If a password is in a file that is committed, the
answer is no, and so is the answer to "can staging use a different database without a code change".

## Failing fast

A setting that is missing should stop the program at start-up, with a sentence that says what is
missing. The catalogue does that for `DATABASE_URL`. Run it once with the variable emptied:

```
ana@vm:~/lab/twelve$ docker compose run --rm -e DATABASE_URL= catalogue; echo "exit code $?"
 Container twelve-db-1 Running 
 Container twelve-db-1 Waiting 
 Container twelve-db-1 Healthy 
 Container twelve-catalogue-run-e35a295b088c Creating 
 Container twelve-catalogue-run-e35a295b088c Created 
DATABASE_URL is not set: give the catalogue the address of its database

exit code 1
```

**The alternative is worse in a way that is easy to miss.** A program that started anyway, with a
default address, would come up healthy and fail on its first real request, perhaps an hour later, with
a connection error that names a host nobody configured. A program that refuses to start fails in the
deploy, while somebody is watching it.

`PORT` is the other kind: it has a sensible default, 8000, and the program takes it when nothing else
is said. **Give a default only when there is a value that is right almost everywhere**; a database
address never is.

## Environment variables are not a secret store

Environment variables can be read by anything that can inspect the process: `docker inspect` prints
them, and so does a crash report that dumps the environment. They are where config is *handed* to the
program. Where the secret *lives* is a secret manager, Vault, AWS Secrets Manager, Google Secret
Manager, Kubernetes secrets, which injects it at start-up, as a variable or as a file, and keeps an
audit of who read it. The program does not have to change for that, which is the point of reading
config from the environment.
