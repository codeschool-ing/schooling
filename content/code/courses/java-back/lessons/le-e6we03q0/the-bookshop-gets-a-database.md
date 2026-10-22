---
title: The bookshop gets a database
version: 1
---

Now the same work inside the bookshop. It starts as lesson 7 left it, and the change is smaller
than it looks, because lesson 5 put the catalogue behind an interface: `BookService` asks a
`BookRepository` and does not know what is behind it. This section and the next swap what is behind
it, and nothing above it changes.

## The dependencies

Replace `pom.xml` with this. Two dependencies are new, at the end of the list:

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
      <artifactId>spring-boot-starter-jdbc</artifactId>
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

**`spring-boot-starter-jdbc`** brings Spring's JDBC support and a connection pool. The
**`postgresql`** driver has `runtime` scope: the code compiles against `java.sql` and Spring's
classes and never names a PostgreSQL one, so the driver is needed when the application runs and
not when it compiles. Neither line has a version, because the parent manages both. Ask Maven what
arrived; `grep` keeps the lines that matter out of the whole tree:

```
ana@vm:~/bookshop$ mvn dependency:tree | grep -E 'jdbc|postgresql|Hikari'
[INFO] +- org.springframework.boot:spring-boot-starter-jdbc:jar:4.1.1:compile
[INFO] |  +- org.springframework.boot:spring-boot-jdbc:jar:4.1.1:compile
[INFO] |  |  \- org.springframework:spring-jdbc:jar:7.0.9:compile
[INFO] |  \- com.zaxxer:HikariCP:jar:7.0.2:compile
[INFO] \- org.postgresql:postgresql:jar:42.7.13:runtime
```

The driver is the same 42.7.13 that `Jdbc.java` used. Under the starter are `spring-jdbc`, Spring
Framework's JDBC support, and **HikariCP**, the pool.

## Where the database is

Replace `src/main/resources/application.properties` with this:

```properties
spring.application.name=bookshop

spring.datasource.url=jdbc:postgresql://localhost:5432/bookshop
spring.datasource.username=bookshop
spring.datasource.password=bookshop

spring.sql.init.mode=always
```

The three `spring.datasource` lines are the URL, user and password that `Jdbc.java` passed to
`DriverManager`, moved into configuration. Lesson 4 showed that a command-line argument overrides a
line in this file, and the last section of this lesson uses that to break each of the three on
purpose.

## The schema and the first rows

Spring Boot looks for two scripts on the class path and runs them against the database at start-up,
`schema.sql` and then `data.sql`. Create `src/main/resources/schema.sql`:

```sql
CREATE TABLE IF NOT EXISTS book (
    id          bigserial PRIMARY KEY,
    isbn        char(13)  NOT NULL UNIQUE,
    title       text      NOT NULL,
    author      text      NOT NULL,
    price_cents integer   NOT NULL CHECK (price_cents >= 0)
);
```

and `src/main/resources/data.sql`:

```sql
INSERT INTO book (isbn, title, author, price_cents) VALUES
    ('9786500000016', 'Dom Casmurro', 'Machado de Assis', 3990),
    ('9786500000023', 'The Time Machine', 'H. G. Wells', 2950),
    ('9786500000030', 'Frankenstein', 'Mary Shelley', 3500)
ON CONFLICT (isbn) DO NOTHING;
```

By default Boot runs them only for an **embedded** database, one that lives inside the JVM and
starts empty every time. PostgreSQL is a real server, so `spring.sql.init.mode=always` asks for them
on every start. Both are written to survive that: `CREATE TABLE IF NOT EXISTS` leaves an existing
table alone, and `ON CONFLICT (isbn) DO NOTHING` skips any row whose ISBN the `UNIQUE` rule already
holds. Running scripts on every start is a stopgap; lesson 13 shows where it breaks down and
replaces both files with migrations.

The table you made by hand in `psql` has the same columns, but it holds Wise Blood and The War of
the Worlds, which `data.sql` does not. Drop it, so that what you see next is what the application
builds from nothing:

```
ana@vm:~/bookshop$ psql postgresql://bookshop:bookshop@localhost:5432/bookshop -c 'DROP TABLE book'
DROP TABLE
```

## A pool instead of DriverManager

`Jdbc.java` opened a connection, used it once and closed it, and the end of that section counted
what each one costs. A web application cannot pay that on every request, so Boot does not use
`DriverManager`. It builds a **`DataSource`**, JDBC's other way to get a connection, an interface
in `javax.sql` whose one job is `getConnection()`. The one Boot builds from the three
`spring.datasource` properties is HikariCP's, a **connection pool**: it opens connections ahead of
time and lends them out, and when code calls `close()` on one, the connection goes back to the pool
instead of being closed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 372\" role=\"img\" aria-label=\"Two programs side by side. On the left, Jdbc.java calls DriverManager, which opens a new connection on every call. On the right, the bookshop's JdbcBookRepository calls Spring's JdbcClient, which borrows connections from a HikariCP pool. Both then go through the same java.sql interfaces and the same PostgreSQL driver jar, over TCP to localhost port 5432, to one PostgreSQL 16 server.\"><defs><marker id=\"jl9-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">this lesson's first program</text><text x=\"525\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the bookshop</text><rect x=\"30\" y=\"26\" width=\"290\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Jdbc.java</text><text x=\"175\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">your code</text><rect x=\"30\" y=\"82\" width=\"290\" height=\"96\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">DriverManager.getConnection(…)</text><text x=\"175\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a new connection on every call</text><rect x=\"380\" y=\"26\" width=\"290\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"525\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">JdbcBookRepository</text><text x=\"525\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">your code</text><rect x=\"380\" y=\"82\" width=\"290\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"525\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">JdbcClient</text><text x=\"525\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Spring: SQL in, records out</text><rect x=\"380\" y=\"134\" width=\"290\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"525\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">HikariDataSource</text><text x=\"525\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Boot's pool of open connections</text><line x1=\"175\" y1=\"70\" x2=\"175\" y2=\"80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><line x1=\"525\" y1=\"70\" x2=\"525\" y2=\"80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><line x1=\"525\" y1=\"126\" x2=\"525\" y2=\"132\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><line x1=\"175\" y1=\"178\" x2=\"175\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><line x1=\"525\" y1=\"178\" x2=\"525\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><rect x=\"30\" y=\"198\" width=\"640\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">java.sql: Connection, PreparedStatement, ResultSet</text><text x=\"350\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">JDBC, the interfaces both programs are written against</text><line x1=\"350\" y1=\"242\" x2=\"350\" y2=\"252\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><rect x=\"30\" y=\"254\" width=\"640\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">postgresql-42.7.13.jar</text><text x=\"350\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the driver: JDBC calls turned into PostgreSQL's protocol</text><line x1=\"350\" y1=\"298\" x2=\"350\" y2=\"324\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#jl9-ah)\"></line><text x=\"360\" y=\"311\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">TCP, localhost:5432</text><rect x=\"30\" y=\"326\" width=\"640\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"346\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">PostgreSQL 16 server</text></svg>", "caption": "Both programs reach PostgreSQL through the same JDBC interfaces and the same driver. JdbcClient and the pool are what Spring adds on top, and they do not replace what is underneath."}
```

Everything under `JdbcClient` in the figure is the JDBC that `Jdbc.java` called by hand. What Spring
adds is the pool and the class that writes the repetitive part for you, which the next section
reads.
