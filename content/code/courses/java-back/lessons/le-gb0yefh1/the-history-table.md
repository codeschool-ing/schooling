---
title: The history table and its checksums
version: 1
---

Everything Flyway knows about this database is in one table it created and nothing else writes to.
Ask for it:

```
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'select installed_rank, version, description, script, checksum, success from flyway_schema_history'
 installed_rank | version | description  |        script        |  checksum  | success 
----------------+---------+--------------+----------------------+------------+---------
              1 | 1       | catalogue    | V1__catalogue.sql    | 2131081588 | t
              2 | 2       | first titles | V2__first_titles.sql | -765405402 | t
(2 rows)
```

One row per migration it applied, in the order it applied them. `installed_rank` is that order,
`version` and `description` come from the file name, `script` is the name itself, and `success` says it
finished. The column that does the work is **`checksum`**, a number Flyway computes from the file's
contents when it applies it, so that it can later tell whether the file it is looking at is still the
file that ran.

On every start Flyway walks the migrations it finds in the jar and the rows in this table side by side:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 256\" role=\"img\" aria-label=\"Flyway on start: on the left, three migration files in the jar; on the right, two rows of flyway_schema_history. V1 and V2 match their rows by checksum and are skipped. V3 has no row, so it is applied and a third row is recorded.\"><defs><marker id=\"fh-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\" dominant-baseline=\"middle\">in the jar: db/migration</text><text x=\"460\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" text-anchor=\"start\" dominant-baseline=\"middle\">in the database</text><rect x=\"20\" y=\"44\" width=\"220\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"34\" y=\"62\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"start\" dominant-baseline=\"middle\">V1__catalogue.sql</text><rect x=\"20\" y=\"100\" width=\"220\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"34\" y=\"118\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"start\" dominant-baseline=\"middle\">V2__first_titles.sql</text><rect x=\"20\" y=\"156\" width=\"220\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"34\" y=\"174\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"start\" dominant-baseline=\"middle\">V3__next_change.sql</text><rect x=\"460\" y=\"44\" width=\"220\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"474\" y=\"62\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"start\" dominant-baseline=\"middle\">1 · 2131081588</text><rect x=\"460\" y=\"100\" width=\"220\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"474\" y=\"118\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\" text-anchor=\"start\" dominant-baseline=\"middle\">2 · -765405402</text><rect x=\"460\" y=\"156\" width=\"220\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"474\" y=\"174\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" text-anchor=\"start\" dominant-baseline=\"middle\">3 · added after V3 runs</text><line x1=\"242\" y1=\"62\" x2=\"458\" y2=\"62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"2 3\"></line><text x=\"350\" y=\"53\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">same checksum: skip</text><line x1=\"242\" y1=\"118\" x2=\"458\" y2=\"118\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"2 3\"></line><text x=\"350\" y=\"109\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">same checksum: skip</text><line x1=\"242\" y1=\"174\" x2=\"456\" y2=\"174\" stroke=\"var(--amber)\" stroke-width=\"1.6\" marker-end=\"url(#fh-ah)\"></line><text x=\"350\" y=\"165\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" text-anchor=\"middle\" dominant-baseline=\"middle\">no row: apply it, then record it</text><text x=\"350\" y=\"236\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\" text-anchor=\"middle\" dominant-baseline=\"middle\">A row whose checksum differs from its file stops the start before anything is applied.</text></svg>", "caption": "What Flyway compares on every start: each file against its row. Only a file with no row runs."}
```

Stop the application with Ctrl+C and start it again. Both files have a row with the same checksum, so
there is nothing to do, and Flyway says so:

```
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep -E 'o\.f\.'
2026-10-22T19:30:02.279-03:00  INFO 16715 --- [bookshop] [           main] o.f.core.internal.command.DbValidate     : Successfully validated 2 migrations (execution time 00:00.018s)
2026-10-22T19:30:02.319-03:00  INFO 16715 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Current version of schema "public": 2
2026-10-22T19:30:02.321-03:00  INFO 16715 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Schema "public" is up to date. No migration necessary.
```

## Editing a migration that already ran

Now a common mistake. Somebody notices that Frankenstein should cost 36.00 rather than
35.00, opens `V2__first_titles.sql`, and corrects it there, because that is where the price is written.
Stop the application and do the same:

```
ana@vm:~/bookshop$ sed -i 's/3500/3600/' src/main/resources/db/migration/V2__first_titles.sql
ana@vm:~/bookshop$ mvn -B -q package -DskipTests
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep -m1 -A3 'checksum mismatch'
Migration checksum mismatch for migration version 2
-> Applied to database : -765405402
-> Resolved locally    : 1463101623
Either revert the changes to the migration, or run repair to update the schema history.
```

**Flyway refused to start.** The file no longer matches the row that recorded it. This database ran the old V2 and holds 3500; a database created tomorrow
would run the new V2 and hold 3600. Two databases built from what looks like the same set of files
would disagree, and nothing would ever say which one is wrong. The checksum is how Flyway notices that
history was rewritten, and it stops before any harm is done.

The message offers two ways out, and only one of them is a fix:

- **Revert the file.** An applied migration is a record of what happened; the correction is a new
  migration, the next version, with an `UPDATE` in it. Every database then receives the same two steps,
  in the same order.
- **`repair`** rewrites the stored checksum to match the file. It runs nothing, so the database keeps
  its 3500 while the file says 3600. It is the right tool only when the edit changed nothing the
  database would have done, such as a comment, or to clear the row a failed migration left on a
  database that cannot roll DDL back.

**Never edit a migration that has run anywhere but your own machine.** On your machine, before you
have shared it, editing is fine: you drop and recreate your own database, as the previous section did,
and nobody else ever saw the old version. Once a migration is in somebody else's database it is
history, and history is corrected by adding to it.

Put the price back, so that the file is the one that ran:

```
ana@vm:~/bookshop$ sed -i 's/3600/3500/' src/main/resources/db/migration/V2__first_titles.sql
ana@vm:~/bookshop$ mvn -B -q package -DskipTests
ana@vm:~/bookshop$ java -jar target/bookshop-0.1.0.jar | grep -E 'o\.f\.|Started'
2026-10-22T19:30:15.616-03:00  INFO 17238 --- [bookshop] [           main] o.f.core.internal.command.DbValidate     : Successfully validated 2 migrations (execution time 00:00.027s)
2026-10-22T19:30:15.649-03:00  INFO 17238 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Current version of schema "public": 2
2026-10-22T19:30:15.652-03:00  INFO 17238 --- [bookshop] [           main] o.f.core.internal.command.DbMigrate      : Schema "public" is up to date. No migration necessary.
2026-10-22T19:30:17.657-03:00  INFO 17238 --- [bookshop] [           main] c.example.bookshop.BookshopApplication   : Started BookshopApplication in 4.654 seconds (process running for 5.124)
```

The checksums agree again, and the application starts. The correction itself, if the shop wanted it,
would be the next migration, and the next migration is the bookshop's own V3, which lesson 14 writes.
