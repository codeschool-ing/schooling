-- What "verified" means, written as a query.
--
-- IT PRODUCES A REPORT AND NOT A VERDICT, and that is the whole trick: the
-- same file runs against the live instance and against the restored clone, and
-- the drill's answer is whether the two outputs are byte-identical. A check
-- written the other way — a list of expected counts kept here — would be a
-- second copy of the schema that goes stale the first time somebody adds a
-- table, and the drill would keep passing while it stopped looking at half the
-- database.
--
-- NOTHING IS NAMED THAT CAN BE DISCOVERED. Tables come from
-- `information_schema`, so a migration merged tomorrow is inside the drill
-- tomorrow, without anybody remembering this file exists. The two spot checks
-- at the end are the exception, because a school is what makes the deployment
-- answer at all and it is worth seeing by name.
--
-- Every statement carries an explicit ORDER BY. Postgres is free to return
-- rows in any order it likes, and a drill that fails because two identical
-- databases sorted differently is a drill nobody runs twice.

\set ON_ERROR_STOP on

-- The schema the restore brought back, column by column. A dropped column, a
-- changed type, a column that moved — each is a different line.
SELECT 'column|' || table_name || '|' || ordinal_position || '|' || column_name
       || '|' || data_type || '|' || is_nullable
       || '|' || coalesce(column_default, '-')
  FROM information_schema.columns
 WHERE table_schema = 'public'
 ORDER BY table_name, ordinal_position;

-- Indexes and constraints, which a restore can silently lose and which nothing
-- else here would notice: every count would still match while the database got
-- slower and stopped refusing what it used to refuse.
SELECT 'index|' || tablename || '|' || indexname || '|' || indexdef
  FROM pg_indexes
 WHERE schemaname = 'public'
 ORDER BY tablename, indexname;

SELECT 'constraint|' || rel.relname || '|' || con.conname
       || '|' || pg_get_constraintdef(con.oid)
  FROM pg_constraint con
  JOIN pg_class rel ON rel.oid = con.conrelid
  JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
 WHERE nsp.nspname = 'public'
 ORDER BY rel.relname, con.conname;

-- Which migrations have run. `cmd/migrate` writes this table itself, so it is
-- the schema's own account of how far it got — and it is the one line that
-- tells a restored instance apart from an instance that was merely created.
SELECT 'migration|' || version || '|' || name
  FROM schema_migrations
 ORDER BY version;

-- Every row of every table, counted without naming any of them.
--
-- `query_to_xml` is how a single statement runs a query per table: it takes
-- SQL as text, runs it, and hands back the result as XML, which `xpath` then
-- reads the number out of. Ugly, and the alternative is a shell loop that
-- decides which tables exist in a different place from where they are counted.
SELECT 'rows|' || t.table_name || '|' ||
       (xpath('/row/cnt/text()',
              query_to_xml(format('SELECT count(*) AS cnt FROM %I.%I',
                                  t.table_schema, t.table_name),
                           false, true, '')))[1]::text
  FROM information_schema.tables t
 WHERE t.table_schema = 'public'
   AND t.table_type = 'BASE TABLE'
 ORDER BY t.table_name;

-- The two spot checks. A school is a row in `tenants` and a row in
-- `tenant_domains`, and without both the deployment answers `/version` and
-- nothing else — so a restore that brought back every count and lost these
-- would look perfect and serve nobody.
SELECT 'tenant|' || slug || '|' || name || '|' || accent
  FROM tenants
 ORDER BY slug;

SELECT 'domain|' || d.host || '|' || t.slug
  FROM tenant_domains d
  JOIN tenants t ON t.id = d.tenant_id
 ORDER BY d.host;
