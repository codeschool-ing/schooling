---
title: Two environments from one project
version: 1
---

An **environment** is a complete place for the pipeline to run: its code, its configuration and the
data it writes. Ana needs two. **Production** is what the reports read, built by the nightly from a
version of the code that was finished and tested. **Development** is where she changes things, built
whenever she likes from whatever she is in the middle of. Nothing done in development may change
what production says.

For the warehouse, the separation is a second dbt target. Lesson 11 showed that a custom schema is
added to the target's schema; that rule now does the work:

```
ana@vm:~/etl$ cat ~/.dbt/profiles.yml
ponto_final:
  target: dev                   # what dbt builds when nobody says otherwise
  outputs:
    dev:                        # Ana's own schemas, beside production's
      type: postgres
      host: /run/etl-pg
      port: 5432
      user: ana
      password: ""
      dbname: wh
      schema: dbt_ana
      threads: 4
    prod:                       # what the reports read; built only by the nightly
      type: postgres
      host: /run/etl-pg
      port: 5432
      user: ana
      password: ""
      dbname: wh
      schema: dbt
      threads: 4
    test:                       # the integration tests' own warehouse
      type: postgres
      host: /run/etl-pg
      port: 5432
      user: ana
      password: ""
      dbname: wh_test
      schema: dbt
      threads: 4
```

`dev` writes to `dbt_ana_staging` and `dbt_ana_marts`, `prod` to `dbt_staging` and `dbt_marts`, in
the same warehouse, reading the same `raw`. And `dev` is the default, so a `dbt build` typed in a
hurry builds Ana's schemas, never the reports'. The `test` target from lesson 17 is the third
environment, with a warehouse of its own.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l18-environments\" aria-label=\"One repository, two environments. In the repository, main has two tagged commits, v1.0.0 and v1.1.0, and a branch where the change was made. Ana works in ~/etl, on main, and builds with the dev target into the dbt_ana schemas. Production is ~/etl-prod, checked out at a tag, built with the prod target into the dbt schemas the reports read. Both read the same raw schema.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"110.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the repository</text><path d=\"M30.0 90.0 L200.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"60.0\" cy=\"90.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><text x=\"60.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1.0.0</text><circle cx=\"170.0\" cy=\"90.0\" r=\"7\" fill=\"var(--phosphor)\"></circle><text x=\"170.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">v1.1.0</text><path d=\"M60 90 C 90 58, 140 58, 170 90\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"115.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">branch</text><rect x=\"250.0\" y=\"30.0\" width=\"220.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">~/etl · main · dev target</text><rect x=\"250.0\" y=\"150.0\" width=\"220.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">~/etl-prod · a tag · prod target</text><path d=\"M200.0 90.0 L248.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M176.0 98.0 L248.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"510.0\" y=\"30.0\" width=\"190.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">dbt_ana_staging · dbt_ana_marts</text><rect x=\"510.0\" y=\"150.0\" width=\"190.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">dbt_staging · dbt_marts</text><path d=\"M470.0 55.0 L508.0 55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M470.0 175.0 L508.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"605.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the reports</text><text x=\"605.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">raw, shared, read only</text></svg>", "caption": "Production is a tag and a target; development is everything else."}
```

For the code, the separation is a second checkout. A **tag** names a commit for good: `v1.0.0` is
*the nightly as it runs today*, whatever happens to `main` later. `git worktree` puts that commit in
a directory of its own, from which production is built:

```
ana@vm:~/etl$ git tag -a v1.0.0 -m "The nightly as it runs today" && git worktree add -q ~/etl-prod v1.0.0 && git worktree list
/home/ana/etl       cdef2c0 [main]
/home/ana/etl-prod  cdef2c0 (detached HEAD)
ana@vm:~/etl-prod$ dbt build --project-dir shop --target prod --quiet && dbt ls --project-dir shop --target prod --resource-type model -q --output name
daily_sales
fact_sales
int_sales
stg_books
stg_events
stg_order_lines
stg_orders
ana@vm:~/etl$ psql -d wh -c "\dn dbt*"
   List of schemas
    Name     | Owner 
-------------+-------
 dbt_marts   | ana
 dbt_staging | ana
(2 rows)
```

Two directories from one repository: `~/etl` on `main`, where Ana works, and `~/etl-prod` fixed at
`v1.0.0`, which is what the nightly runs. Editing a file in `~/etl` changes nothing in `~/etl-prod`.
Production's schemas now exist, built from the tagged code; Ana's do not yet.
