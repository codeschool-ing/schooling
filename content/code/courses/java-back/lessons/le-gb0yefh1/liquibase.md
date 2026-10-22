---
title: The same tables in Liquibase
version: 1
---

**Liquibase** solves the same problem as Flyway with a different unit. Flyway's unit is a SQL file
whose name is its version. Liquibase's is a **changeset**: an entry in a **changelog**, written in YAML,
XML, JSON or SQL, identified by an `id`, an `author` and the file it is in rather than by a number. A
changeset can carry SQL, but it is more often written as a description of the change, `createTable`
or `addColumn`, which Liquibase turns into SQL for whichever database it is talking to. Spring Boot runs
it at start-up exactly as it runs Flyway, given `spring-boot-starter-liquibase` and a changelog at
`db/changelog/db.changelog-master.yaml`.

To see it without disturbing the bookshop, this section uses a separate project, `~/liquibase-look`,
that runs Liquibase from Maven against a schema of its own, `look`, inside the bookshop's database.
Create `~/liquibase-look/pom.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>liquibase-look</artifactId>
  <version>0.1.0</version>
  <packaging>pom</packaging>

  <build>
    <plugins>
      <plugin>
        <groupId>org.liquibase</groupId>
        <artifactId>liquibase-maven-plugin</artifactId>
        <version>5.0.3</version>
        <configuration>
          <changeLogFile>changelog.yaml</changeLogFile>
          <url>jdbc:postgresql://localhost:5432/bookshop?currentSchema=look</url>
          <username>bookshop</username>
          <password>bookshop</password>
        </configuration>
        <dependencies>
          <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <version>42.7.13</version>
          </dependency>
        </dependencies>
      </plugin>
    </plugins>
  </build>
</project>
```

It builds nothing; it only configures the Liquibase plugin, with the PostgreSQL driver as the plugin's
own dependency and `currentSchema=look` in the URL so that every table Liquibase makes lands in `look`.
Then the changelog, `~/liquibase-look/changelog.yaml`, with the bookshop's two tables and one row:

```yaml
databaseChangeLog:
  - changeSet:
      id: author
      author: ana
      changes:
        - createTable:
            tableName: author
            columns:
              - column:
                  name: id
                  type: bigint
                  autoIncrement: true
                  constraints:
                    primaryKey: true
              - column:
                  name: name
                  type: text
                  constraints:
                    nullable: false
                    unique: true
  - changeSet:
      id: book
      author: ana
      changes:
        - createTable:
            tableName: book
            columns:
              - column:
                  name: id
                  type: bigint
                  autoIncrement: true
                  constraints:
                    primaryKey: true
              - column:
                  name: isbn
                  type: char(13)
                  constraints:
                    nullable: false
                    unique: true
              - column:
                  name: title
                  type: text
                  constraints:
                    nullable: false
              - column:
                  name: author_id
                  type: bigint
                  constraints:
                    nullable: false
                    foreignKeyName: book_author_fk
                    references: author(id)
  - changeSet:
      id: first-author
      author: ana
      changes:
        - sql:
            sql: INSERT INTO author (name) VALUES ('Machado de Assis')
      rollback:
        - sql:
            sql: DELETE FROM author WHERE name = 'Machado de Assis'
```

The first two changesets describe tables and never mention PostgreSQL. The third is plain SQL, and it
carries a `rollback` of its own; the reason is at the end of this section. Create the schema and run
the changelog twice:

```
ana@vm:~/liquibase-look$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'CREATE SCHEMA look'
CREATE SCHEMA
ana@vm:~/liquibase-look$ mvn -B -q liquibase:update

UPDATE SUMMARY
Run:                          3
Previously run:               0
Filtered out:                 0
-------------------------------
Total change sets:            3

ana@vm:~/liquibase-look$ mvn -B -q liquibase:update

UPDATE SUMMARY
Run:                          0
Previously run:               3
Filtered out:                 0
-------------------------------
Total change sets:            3
```

The first run applied three changesets and the second applied none, which is Flyway's "up to date" in
Liquibase's words. Its history is the table `databasechangelog`:

```
ana@vm:~/liquibase-look$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'select id, author, filename, md5sum, exectype, orderexecuted from look.databasechangelog'
      id      | author |    filename    |               md5sum               | exectype | orderexecuted 
--------------+--------+----------------+------------------------------------+----------+---------------
 author       | ana    | changelog.yaml | 9:9f262f08622c0f18cafcf7c050aa0b36 | EXECUTED |             1
 book         | ana    | changelog.yaml | 9:9341c4015a946c2287430dcf5c96a8f3 | EXECUTED |             2
 first-author | ana    | changelog.yaml | 9:74f9aa91af47f13bc625299b866ecca3 | EXECUTED |             3
(3 rows)
```

A changeset is known by its `id`, `author` and `filename` together, and `md5sum` plays the part of
Flyway's checksum: edit a changeset that has run and the next update stops, for the same reason Flyway
stopped. Liquibase also made a second table, `databasechangeloglock`, which keeps two copies of an
application starting at once from applying the same changeset twice.

## Rollback

The feature people choose Liquibase for is **rollback**: undoing the last changesets, in reverse order.
Undo the last two:

```
ana@vm:~/liquibase-look$ mvn -B -q liquibase:rollback -Dliquibase.rollbackCount=2
ana@vm:~/liquibase-look$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'select id from look.databasechangelog'
   id   
--------
 author
(1 row)

ana@vm:~/liquibase-look$ psql postgresql://bookshop:bookshop@localhost/bookshop -c '\dt look.*'
                 List of relations
 Schema |         Name          | Type  |  Owner   
--------+-----------------------+-------+----------
 look   | author                | table | bookshop
 look   | databasechangelog     | table | bookshop
 look   | databasechangeloglock | table | bookshop
(3 rows)

ana@vm:~/liquibase-look$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'select count(*) from look.author'
 count 
-------
     0
(1 row)
```

The history lost its last two rows, the `book` table is gone and `author` is empty again. Liquibase
undid them in two different ways. For `createTable` it **generated** the inverse, a `DROP TABLE`, because
a described change says enough to be reversed. For the `sql` changeset it ran the `rollback` written in
the file, because Liquibase cannot know what arbitrary SQL did; without that block, the rollback would
refuse rather than guess. Be clear about what a rollback is: a new set of changes run forward, which
drop what was created. A dropped column's data does not come back.

Drop the schema when you have finished looking:

```
ana@vm:~/liquibase-look$ psql postgresql://bookshop:bookshop@localhost/bookshop -c 'DROP SCHEMA look CASCADE'
NOTICE:  drop cascades to 3 other objects
DETAIL:  drop cascades to table look.databasechangelog
drop cascades to table look.databasechangeloglock
drop cascades to table look.author
DROP SCHEMA
```

## Choosing between them

| | Flyway | Liquibase |
|---|---|---|
| the unit | a SQL file, `V<version>__<description>.sql` | a changeset in a changelog |
| its identity | the version in the file name | `id`, `author` and file |
| written in | the database's own SQL | described changes, or SQL |
| history table | `flyway_schema_history` | `databasechangelog` |
| an edited change that already ran | refused: checksum mismatch | refused: checksum mismatch |
| undo | not in the free edition | generated, or written beside the change |

They differ in one more way, and it is not technical. The licence each one ships under is in its pom:

```
ana@vm:~$ grep -A1 '<license>' .m2/repository/org/flywaydb/flyway-parent/12.4.0/flyway-parent-12.4.0.pom .m2/repository/org/liquibase/liquibase-maven-plugin/5.0.3/liquibase-maven-plugin-5.0.3.pom
.m2/repository/org/flywaydb/flyway-parent/12.4.0/flyway-parent-12.4.0.pom:    <license>
.m2/repository/org/flywaydb/flyway-parent/12.4.0/flyway-parent-12.4.0.pom-      <name>Apache License, Version 2.0</name>
--
.m2/repository/org/liquibase/liquibase-maven-plugin/5.0.3/liquibase-maven-plugin-5.0.3.pom:        <license>
.m2/repository/org/liquibase/liquibase-maven-plugin/5.0.3/liquibase-maven-plugin-5.0.3.pom-            <name>FSL-1.1-ALv2</name>
```

Flyway is under the Apache License 2.0. Liquibase 5 moved to the **Functional Source License**, whose
terms forbid using it to build a product that competes with Liquibase's own and turn into Apache 2.0
after two years. That restriction does not touch an application that only runs its own migrations,
but an organisation that reviews licences will want to read it, and it is the kind of fact that changes
between versions.

For a team that writes SQL comfortably and runs one database, Flyway's model is the smaller one: the
files are the SQL that runs, and the history is their names. Liquibase pays its extra vocabulary back
when one changelog has to serve several databases, or when generated rollback is worth having. The
bookshop stays on Flyway, and lesson 14 writes its next migration.
