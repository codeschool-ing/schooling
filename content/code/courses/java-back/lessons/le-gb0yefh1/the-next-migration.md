---
title: Writing the next migration
version: 1
---

Migrations only go forward. Every change to the schema is a new file with the next version, and a file
that has run is never touched again. Flyway's free edition has no undo: a mistake that reached a
database is corrected by the migration after it, the way the price was in the previous section.

That makes it worth knowing what happens when a migration fails halfway. Suppose the shop starts
recording each book's publisher. Create `src/main/resources/db/migration/V3__publisher.sql`:

```sql
CREATE TABLE publisher (
    id   bigserial PRIMARY KEY,
    name text      NOT NULL UNIQUE
);

ALTER TABLE book ADD COLUMN publisher_id bigint NOT NULL REFERENCES publisher (id);
```

Build and start it, keeping Flyway's progress lines and the database's message:

```
ana@vm:~/bookshop$ mvn -B -q package -DskipTests
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep -m4 -E 'DbMigrate|^Message'
2026-10-22T19:30:23.171-03:00  INFO 17484 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Current version of schema "public": 2
2026-10-22T19:30:23.181-03:00  INFO 17484 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Migrating schema "public" to version "3 - publisher"
2026-10-22T19:30:23.230-03:00 ERROR 17484 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Migration of schema "public" to version "3 - publisher" failed! Changes successfully rolled back.
Message    : ERROR: column "publisher_id" of relation "book" contains null values
```

The second statement failed, and the first one is gone with it:

```
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost/bookshop -c '\dt'
                 List of relations
 Schema |         Name          | Type  |  Owner   
--------+-----------------------+-------+----------
 public | author                | table | bookshop
 public | book                  | table | bookshop
 public | flyway_schema_history | table | bookshop
(3 rows)

ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'select installed_rank, version, description, success from flyway_schema_history'
 installed_rank | version | description  | success 
----------------+---------+--------------+---------
              1 | 1       | catalogue    | t
              2 | 2       | first titles | t
(2 rows)
```

No `publisher` table, and no row for version 3. **PostgreSQL runs DDL inside transactions**, so Flyway
runs each migration in one, and a failure anywhere in the file takes back everything before it in the
same file. The database is exactly as it was at version 2, and the next start will try V3 again from
the top. Not every database can do this. MySQL commits each `CREATE` and `ALTER` the moment it runs, so
the same failure there leaves the table behind and a failed row in the history, and somebody has to
clean up both by hand before anything moves.

Now read why it failed, because this is the failure migrations are known for. A `NOT NULL` column with
no default cannot be added to a table that has rows, since every existing row would break the rule the
moment the column appeared. On an empty database the same file succeeds: on a new colleague's laptop, in
lesson 19's tests, which start from nothing, and in every check that never meets real data. **A
migration that passes on an empty database has proved very little.** Run new migrations against a copy
of data shaped like production's before production does it for you.

The way through is to split the change, and it has a name, **expand and contract**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 256\" role=\"img\" aria-label=\"Three releases from left to right. Release 1 expands: a migration adds a nullable column and the new code writes it while the old code ignores it. Release 2 fills: a migration gives every old row its value. Release 3 contracts: a migration makes the column required, once nothing is left without a value.\"><defs><marker id=\"fx-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"120.0\" y=\"20\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" text-anchor=\"middle\" dominant-baseline=\"middle\">release 1: expand</text><rect x=\"15\" y=\"36\" width=\"210\" height=\"92\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"52\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">migration</text><text x=\"120.0\" y=\"72\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">add the table and a</text><text x=\"120.0\" y=\"88\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">column that may be empty</text><text x=\"120.0\" y=\"110\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\" text-anchor=\"middle\" dominant-baseline=\"middle\">publisher_id bigint NULL</text><rect x=\"15\" y=\"140\" width=\"210\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"156\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">application</text><text x=\"120.0\" y=\"174\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">new code writes it;</text><text x=\"120.0\" y=\"190\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">old code ignores it</text><text x=\"350.0\" y=\"20\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" text-anchor=\"middle\" dominant-baseline=\"middle\">release 2: fill</text><rect x=\"245\" y=\"36\" width=\"210\" height=\"92\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"52\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">migration</text><text x=\"350.0\" y=\"72\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">give every old row</text><text x=\"350.0\" y=\"88\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">its value</text><text x=\"350.0\" y=\"110\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\" text-anchor=\"middle\" dominant-baseline=\"middle\">UPDATE book SET ...</text><rect x=\"245\" y=\"140\" width=\"210\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"156\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">application</text><text x=\"350.0\" y=\"174\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">all code writes it;</text><text x=\"350.0\" y=\"190\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">old rows catch up</text><text x=\"580.0\" y=\"20\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" text-anchor=\"middle\" dominant-baseline=\"middle\">release 3: contract</text><rect x=\"475\" y=\"36\" width=\"210\" height=\"92\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"52\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">migration</text><text x=\"580.0\" y=\"72\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">make the column</text><text x=\"580.0\" y=\"88\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">required</text><text x=\"580.0\" y=\"110\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\" text-anchor=\"middle\" dominant-baseline=\"middle\">SET NOT NULL</text><rect x=\"475\" y=\"140\" width=\"210\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"580.0\" y=\"156\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">application</text><text x=\"580.0\" y=\"174\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">nothing is left</text><text x=\"580.0\" y=\"190\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">without a value</text><line x1=\"15\" y1=\"226\" x2=\"685\" y2=\"226\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#fx-ah)\"></line><text x=\"350.0\" y=\"244\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">each step is deployed, and checked, before the next</text></svg>", "caption": "Expand and contract: one change the database cannot take in one step, split across three releases so that every version of the code that runs meets a schema it can work with."}
```

Each step is its own migration, shipped with its own release. The reason for the separate releases is
that a deployment is never instantaneous: for a while the old version of the application and the new
one run against the same database, and each step leaves a schema that both can live with. A rename is
the same shape — add the new column, copy into it, move the code across, and drop the old column in a
later release, when nothing reads it any more.

This V3 was a demonstration. Delete it, so that version 3 is free for the bookshop's real one, which
lesson 14 writes:

```
ana@vm:~/bookshop$ rm src/main/resources/db/migration/V3__publisher.sql
ana@vm:~/bookshop$ mvn -B -q package -DskipTests
```
