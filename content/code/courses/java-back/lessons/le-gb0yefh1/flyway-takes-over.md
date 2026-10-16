---
title: Flyway takes over the schema
version: 1
---

Flyway's model fits in one sentence. **It reads SQL files named `V<version>__<description>.sql` from
`db/migration` on the classpath, applies in version order the ones this database has not received, and
records each one in a table of its own, `flyway_schema_history`.** Everything else in this lesson is a
consequence of that sentence.

The name carries the order. `V1__catalogue.sql` is version 1 with the description `catalogue`;
`V2__first_titles.sql` is version 2, `first titles`, the underscores turned into spaces. The separator
is **two** underscores, and versions compare as numbers, so `V10` comes after `V9` rather than after
`V1`; a version may also be dotted, `V1.1`. A second kind of file, `R__<description>.sql`, is
**repeatable**: it has no version and runs again whenever its contents change, which suits a view or a
function that is always replaced whole. The bookshop needs none.

## The pom

Replace `pom.xml` with this. Two dependencies are new:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>4.1.1</version>
    <relativePath/>
  </parent>

  <groupId>com.example</groupId>
  <artifactId>bookshop</artifactId>
  <version>0.1.0</version>

  <properties>
    <java.version>25</java.version>
  </properties>

  <dependencies>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-webmvc</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-validation</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-jpa</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-flyway</artifactId>
    </dependency>
    <dependency>
      <groupId>org.flywaydb</groupId>
      <artifactId>flyway-database-postgresql</artifactId>
    </dependency>
    <dependency>
      <groupId>org.postgresql</groupId>
      <artifactId>postgresql</artifactId>
      <scope>runtime</scope>
    </dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-maven-plugin</artifactId>
      </plugin>
    </plugins>
  </build>
</project>
```

`spring-boot-starter-flyway` brings Flyway and the autoconfiguration that runs it at start-up, before
the `EntityManagerFactory` of lesson 10 is built, so Hibernate never sees a schema halfway through a
migration. `flyway-database-postgresql` is Flyway's support for PostgreSQL in particular: Flyway ships
each database family as a module of its own, and the end of this section shows what happens without it.
Neither has a version, because the parent manages them, as lesson 4 explained; this one resolves to
Flyway 12.4.0.

## The migrations

`schema.sql` and `data.sql` go, and two migrations take their place. Delete the two files, then create
the directory `src/main/resources/db/migration` and write the first migration,
`src/main/resources/db/migration/V1__catalogue.sql`:

```sql
CREATE TABLE author (
    id   bigserial PRIMARY KEY,
    name text      NOT NULL UNIQUE
);

CREATE TABLE book (
    id          bigserial PRIMARY KEY,
    isbn        char(13)  NOT NULL UNIQUE,
    title       text      NOT NULL,
    author_id   bigint    NOT NULL REFERENCES author (id),
    price_cents integer   NOT NULL CHECK (price_cents >= 0)
);
```

and the second, `src/main/resources/db/migration/V2__first_titles.sql`:

```sql
INSERT INTO author (name) VALUES
    ('Machado de Assis'),
    ('H. G. Wells'),
    ('Mary Shelley'),
    ('Jane Austen');

INSERT INTO book (isbn, title, author_id, price_cents)
SELECT b.isbn, b.title, a.id, b.price_cents
FROM (VALUES
    ('9786500000016', 'Dom Casmurro', 'Machado de Assis', 3990),
    ('9786500000023', 'The Time Machine', 'H. G. Wells', 2950),
    ('9786500000030', 'Frankenstein', 'Mary Shelley', 3500),
    ('9786500000047', 'Persuasion', 'Jane Austen', 3100),
    ('9786500000054', 'Quincas Borba', 'Machado de Assis', 3690),
    ('9786500000061', 'The War of the Worlds', 'H. G. Wells', 3200)
) AS b (isbn, title, author, price_cents)
JOIN author a ON a.name = b.author
ORDER BY b.isbn;
```

They are the two old files with their guards removed. `IF NOT EXISTS` and `ON CONFLICT` were there
because the files ran on every start; a migration runs once, so a guard in one would only hide a
mistake. Schema and data go in separate files because they are separate changes: a database somewhere
may one day need the tables without these six rows.

Last, `src/main/resources/application.properties` loses the line that ran the old files:

```properties
spring.application.name=bookshop

spring.datasource.url=jdbc:postgresql://localhost:5432/bookshop
spring.datasource.username=bookshop
spring.datasource.password=bookshop

spring.jpa.hibernate.ddl-auto=none
spring.jpa.open-in-view=false
```

Build, and look for the migrations inside the jar, which is where Flyway reads them from:

```
@@files@@
```

## A database that already has tables

Start it in the second terminal. The log is long, so this time it goes through `grep`, which keeps the
one line that matters:

```
@@nonempty@@
```

Flyway found tables and **no history table**, and it refuses to guess. These tables could be what V1
and V2 make, or something else entirely; applying V1 to them would fail on the first `CREATE TABLE`,
and assuming they match could hide a difference forever. The message names the two ways out, and which
one is right depends on whether the data matters.

**A baseline is for a database whose data matters.** It tells Flyway: this database already contains
everything up to version N. Flyway creates its history table with one row saying so, and from then on
applies only versions above N. This is how a team adopts Flyway on a production database that has years
of rows in it. The bookshop's database was made by `schema.sql` and `data.sql`, which make exactly what
V1 and V2 make, so its baseline is 2. Try it once, with the two settings on the command line:

```
@@baseline@@
```

Flyway created its history with a **baseline** row at version 2 and applied nothing. The version is a
claim you make and Flyway cannot check: a baseline of 2 on a database that really stopped at 1 would
skip V2 for ever, silently. That is also why `baseline-on-migrate` belongs on a command line used once
and never in `application.properties`, where it would quietly baseline any non-empty database the
application is ever pointed at, including the wrong one.

**Dropping is for a database whose data does not matter**, and this one holds three lessons of test
rows. Stop the application with Ctrl+C and make the database again, empty, as lesson 10 did:

```sh
sudo -u postgres dropdb bookshop
sudo -u postgres createdb -O bookshop bookshop
```

Start it again. On an empty database there is nothing to refuse, and Flyway's lines tell the whole
story:

```
@@migrate@@
```

It created its history table, found the schema empty, applied version 1 and then version 2, and only
then let the rest of the application start. The next start applies nothing, and the section after next
reads the table that makes that possible.

The second dependency in the pom is easy to leave out, because the project compiles without it. This
is the start without it, against the same database:

```
@@nopg@@
```

Flyway knows PostgreSQL's name and nothing else about it. Put the dependency back.
