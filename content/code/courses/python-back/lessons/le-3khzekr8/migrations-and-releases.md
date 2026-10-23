---
title: Migrations and releases
version: 1
---

A release is a new image, a migration and a restart, in that order:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 172\" role=\"img\" aria-label=\"Four steps of a release: build the image with a new tag; run the migration once with compose run; start the new containers with compose up; check with check --deploy and a request. The migration runs before the new code starts, while the old code may still be serving, so it must leave a schema both versions can use.\"> <defs><marker id=\"rl-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"50\" width=\"155\" height=\"56\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"97\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">build</text> <text x=\"97\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">docker build -t agenda:0.1.1</text> <path d=\"M175 78 L191 78\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#rl-a)\"></path> <rect x=\"195\" y=\"50\" width=\"155\" height=\"56\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.15\" stroke=\"var(--phosphor)\"></rect> <text x=\"272\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">migrate</text> <text x=\"272\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">compose run --rm web migrate</text> <path d=\"M350 78 L366 78\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#rl-a)\"></path> <rect x=\"370\" y=\"50\" width=\"155\" height=\"56\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"447\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">start</text> <text x=\"447\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">compose up -d</text> <path d=\"M525 78 L541 78\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#rl-a)\"></path> <rect x=\"545\" y=\"50\" width=\"155\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"622\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">check</text> <text x=\"622\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">check --deploy, curl</text> <text x=\"360\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">The migration runs once, before the new code starts, while the old code may still be serving:</text> <text x=\"360\" y=\"158\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">so it must leave a schema both versions can use.</text> </svg>", "caption": "A release in order. A migration inside the container's start command would run once per replica, all at the same moment."}
```

## Why the migration is a step of its own

A command such as `migrate && gunicorn` in the image looks tidy. Run three copies of the web service,
or restart one while a deploy is half done, and three migrations start at the same moment against one
database. Django and Alembic both record which migrations ran, but neither promises that two
processes migrating at once is safe. **One container, once, before the new code starts**, as the
previous section did with `docker compose run --rm`.

## Migrations both versions can live with

During a release the old code is still serving while the migration runs, and after it the new code
starts. A migration that **adds** a nullable column, as lesson 12's `organiser` was, is harmless to
the old code, which does not know the column exists. A migration that **removes or renames** a
column breaks the old code at once, in the middle of the release. The usual answer is to split it,
**expand and then contract**: one release adds the new column and writes both, a later one moves the
reads, and only a third drops the old column, when no running code uses it. Lesson 10's rename of
`venue` is exactly the change that needs three releases on a live site.

## What a release is checked with

```
ana@vm:~/deploy$ docker compose exec web python manage.py check --deploy 2>&1 | grep "^?:" | cut -c1-72
?: (security.W005) You have not set the SECURE_HSTS_INCLUDE_SUBDOMAINS s
?: (security.W021) You have not set the SECURE_HSTS_PRELOAD setting to T
```

Lesson 16's two deliberate HSTS warnings, and nothing else; the secret key is long enough because it
was generated at fifty bytes, as lesson 15's was. A key shorter than fifty characters gets its own
warning, which is the check doing its job.

```
ana@vm:~/deploy$ docker image ls --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | head -4
REPOSITORY    TAG         SIZE
agenda-api    0.1.0       347MB
agenda        0.1.0       381MB
python        3.12-slim   179MB
```

**An image is named by its tag**, here `0.1.0`. A release builds a new tag from a new commit, pushes it
to a registry the server can pull from, and changes `image:` in the compose file. Going back is
changing the tag back, provided the database still suits the old code, which is what expand and
contract is for. A tag such as `latest`, which moves, says nothing about which code is running.

```
ana@vm:~/deploy$ docker compose down 2>&1 | tail -1
 Network deploy_default Removed 
```

## Where this leaves agenda

The same two applications now run three ways, each from the one before: on a laptop with `uv run`,
on a server under systemd behind nginx, and as containers from one compose file. Lesson 16's nginx
stays in front in the last case too, proxying to `127.0.0.1:8000` and `127.0.0.1:8001` exactly as
before, because the containers publish the same ports the services used.
