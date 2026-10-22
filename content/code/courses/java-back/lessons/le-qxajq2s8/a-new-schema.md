---
title: Authors get a table of their own
version: 1
---

Until now an author was a string inside each book. Two books by H. G. Wells repeated his name, and
nothing stopped a typo from turning him into two people. This lesson gives authors their own table
and has `book` point at it with a key. That is the change that makes a mapper worth having: a book
now has something to navigate to. (`sql-databases` lesson 1 argues why a fact is recorded once; here
it is simply the new schema.)

Four files change before any Java does.

## The dependency

Replace `spring-boot-starter-jdbc` with `spring-boot-starter-data-jpa`. This is the whole `pom.xml`
as it now stands:

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

The new starter brings Hibernate and the JPA annotations, and it still brings everything the JDBC
starter did, because it depends on it:

```
ana@vm:~/bookshop$ mvn dependency:tree | grep -E 'starter-data-jpa|starter-jdbc|HikariCP|persistence-api|hibernate-core|spring-data-jpa'
[INFO] +- org.springframework.boot:spring-boot-starter-data-jpa:jar:4.1.1:compile
[INFO] |  +- org.springframework.boot:spring-boot-starter-jdbc:jar:4.1.1:compile
[INFO] |  |  \- com.zaxxer:HikariCP:jar:7.0.2:compile
[INFO] |  |  |  |  \- jakarta.persistence:jakarta.persistence-api:jar:3.2.0:compile
[INFO] |  |  |  +- org.hibernate.orm:hibernate-core:jar:7.4.5.Final:compile
[INFO] |  |  +- org.springframework.data:spring-data-jpa:jar:4.1.1:compile
```

`spring-data-jpa` is in there too. It is lesson 11's subject; this lesson uses the mapper underneath
it directly, so that you see what Spring Data later does for you.

## The schema and its data

Replace `src/main/resources/schema.sql`:

```sql
CREATE TABLE IF NOT EXISTS author (
    id   bigserial PRIMARY KEY,
    name text      NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS book (
    id          bigserial PRIMARY KEY,
    isbn        char(13)  NOT NULL UNIQUE,
    title       text      NOT NULL,
    author_id   bigint    NOT NULL REFERENCES author (id),
    price_cents integer   NOT NULL CHECK (price_cents >= 0)
);
```

`author_id` is a **foreign key**: PostgreSQL refuses a book whose `author_id` names no author, and
refuses to delete an author who still has books. And replace `src/main/resources/data.sql`:

```sql
INSERT INTO author (name) VALUES
    ('Machado de Assis'),
    ('H. G. Wells'),
    ('Mary Shelley'),
    ('Jane Austen')
ON CONFLICT (name) DO NOTHING;

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
ORDER BY b.isbn
ON CONFLICT (isbn) DO NOTHING;
```

The authors go in first, and each book finds its author's id by joining on the name, so the file never
writes an id down. Both statements end in `ON CONFLICT … DO NOTHING` because lesson 9's
`spring.sql.init.mode=always` runs this file on every start, and the second start must not fail on
rows the first one inserted.

## The properties

Replace `src/main/resources/application.properties`:

```properties
spring.application.name=bookshop

spring.datasource.url=jdbc:postgresql://localhost:5432/bookshop
spring.datasource.username=bookshop
spring.datasource.password=bookshop

spring.sql.init.mode=always
spring.jpa.hibernate.ddl-auto=none
spring.jpa.open-in-view=false
```

Two lines are new. **`spring.jpa.hibernate.ddl-auto=none`** stops Hibernate from touching the
tables. It can create them from the entities (`create`) or alter them to match (`update`). Both are
tempting on the first day, and then the schema is whatever the Java says this morning, with no
record of how it got there. Here `schema.sql` owns the tables, and lesson 13 hands them to a
migration tool. **`spring.jpa.open-in-view=false`** gets the whole of the last section.

## The database starts again

`schema.sql` says `CREATE TABLE IF NOT EXISTS`, and lesson 9 already created a table called `book`,
the one with an `author` column. So the new definition would be skipped, the old table kept, and
`data.sql` would fail against it. A file that runs on every start cannot change the shape of a table
that exists; that is exactly the problem lesson 13 solves. For now, drop the database and create it
again, empty, owned by the same role:

```
ana@vm:~/bookshop$ sudo -u postgres dropdb bookshop
ana@vm:~/bookshop$ sudo -u postgres createdb -O bookshop bookshop
```

Neither command prints anything when it works. The data was only the sample books, and the
application puts them back on its next start.
