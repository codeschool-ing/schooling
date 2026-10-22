---
title: Testcontainers, a real PostgreSQL for every run
version: 1
---

**Testcontainers** is a Java library that drives the engine from inside a test: it asks for a
container, waits until the program in it is ready, hands the test its address, and removes it when
the run ends. With PostgreSQL in a container, an integration test checks the bookshop against the
same database it runs on in production, with a schema Flyway built from nothing a few seconds before.

The other common answer is an in-memory database such as H2 in place of PostgreSQL. It is faster to
start, and it is a different database, with its own SQL dialect, its own types and its own locking.
A migration with a type only PostgreSQL has, or a query whose behaviour depends on PostgreSQL's,
passes or fails there for H2's reasons. The bookshop's `isbn` column is `char(13)`, and lesson 13 met a failure that
depended on exactly that type.

## The dependencies

Replace the whole `<dependencies>` element of `pom.xml` with this one. The last four entries before
the PostgreSQL driver are new, all with `test` scope and no version, because Boot's parent manages
Testcontainers like everything else:

```xml
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
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-security-oauth2-resource-server</artifactId>
    </dependency>
    <dependency>
      <groupId>org.springdoc</groupId>
      <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
      <version>${springdoc.version}</version>
    </dependency>

    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-test</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-jpa-test</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-testcontainers</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.testcontainers</groupId>
      <artifactId>testcontainers-junit-jupiter</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.testcontainers</groupId>
      <artifactId>testcontainers-postgresql</artifactId>
      <scope>test</scope>
    </dependency>
    <dependency>
      <groupId>org.postgresql</groupId>
      <artifactId>postgresql</artifactId>
      <scope>runtime</scope>
    </dependency>
  </dependencies>
```

| artifact | what it brings |
| --- | --- |
| `spring-boot-starter-data-jpa-test` | `@DataJpaTest`, a test that starts only the persistence half of the application |
| `spring-boot-testcontainers` | `@ServiceConnection`, which points Spring at a container |
| `testcontainers-junit-jupiter` | `@Testcontainers` and `@Container`, a container whose life is tied to a test class |
| `testcontainers-postgresql` | `PostgreSQLContainer`, which knows how to start PostgreSQL and how to tell it is ready |

Testcontainers 2 named its modules with a `testcontainers-` prefix and moved `PostgreSQLContainer`
into the package `org.testcontainers.postgresql`. Examples written for version 1, which are most of
what a search finds, import it from `org.testcontainers.containers` and write
`PostgreSQLContainer<?>`; neither compiles against version 2.

## The whole application against a container

Create `src/test/java/com/example/bookshop/TestcontainersConfiguration.java`:

```java
package com.example.bookshop;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.postgresql.PostgreSQLContainer;

@TestConfiguration(proxyBeanMethods = false)
public class TestcontainersConfiguration {

    @Bean
    @ServiceConnection
    PostgreSQLContainer postgres() {
        return new PostgreSQLContainer("postgres:16-alpine");
    }
}
```

The container is a **bean**. Spring starts it when the context needs it, before the beans that use
the database, and stops it when the context closes. **`@ServiceConnection`** is the link: Spring Boot
reads the running container's address, database name, user and password and uses them in place of
the `spring.datasource.*` properties of `application.properties`. Nothing in the test names a port,
which matters, because Docker publishes the container's 5432 on whichever port of the machine is
free.

The application also needs the JWT secret that lesson 15 reads from an environment variable. A test
should not depend on a variable somebody has to remember to set, so a profile called `test` gives it
a value. Create `src/test/resources/application-test.properties`:

```properties
bookshop.jwt.secret=a-secret-for-tests-only-at-least-32-bytes
```

That value is not a secret and must never be one: it sits in the repository, and it only signs tokens
inside a test. Then the first integration test, in
`src/test/java/com/example/bookshop/BookshopApplicationIT.java`:

```java
package com.example.bookshop;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;

import com.example.bookshop.catalogue.BookService;

@SpringBootTest
@ActiveProfiles("test")
@Import(TestcontainersConfiguration.class)
class BookshopApplicationIT {

    @Autowired
    BookService books;

    @Test
    void startsAgainstARealDatabaseWithTheMigrationsApplied() {
        assertThat(books.count()).isEqualTo(6);
    }
}
```

`@SpringBootTest` starts the whole application, as `java -jar` would, without a web server listening;
`@ActiveProfiles("test")` reads the file above; `@Import` adds the container. The test then asks the
real `BookService` how many books there are. Six is what lesson 13's `V2__first_titles.sql` inserts,
so the number holds only if Flyway ran every migration on the empty database.

## Only the persistence half

`BookRepositoryIT` tests two of lesson 11's queries. It does not need the controllers, the security
filters or the services, and **`@DataJpaTest`** starts none of them, only the data source, Flyway,
Hibernate and the repositories. Each test method runs inside a transaction that is rolled back when
it ends. Create `src/test/java/com/example/bookshop/catalogue/BookRepositoryIT.java`:

```java
package com.example.bookshop.catalogue;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

@DataJpaTest
@Testcontainers
class BookRepositoryIT {

    @Container
    @ServiceConnection
    static PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:16-alpine");

    @Autowired
    BookRepository books;

    @Test
    void findsTitlesByAuthorInTitleOrder() {
        assertThat(books.findTitlesByAuthor("H. G. Wells"))
                .extracting(TitleAndPrice::getTitle)
                .containsExactly("The Time Machine", "The War of the Worlds");
    }

    @Test
    void searchIgnoresCase() {
        assertThat(books.findByTitleContainingIgnoreCaseOrderByTitle("BORBA"))
                .extracting(Book::getIsbn)
                .containsExactly("9786500000054");
    }
}
```

This class declares its container the other way Testcontainers offers. **`@Testcontainers`** is a
JUnit extension, and it starts every `@Container` field before the class's first test and stops it
after the last; a `static` field is one container for the whole class. `@ServiceConnection` works on
a field exactly as it does on a bean.

The two styles are shown side by side on purpose, and they are not equivalent: the bean belongs to
a Spring context, the field to a test class. The next section counts what that difference costs.

## The warning the second option prevents

Before the real run, a detour that shows what `--enable-native-access=ALL-UNNAMED` is for. Take it
out of both `argLine`s and run the integration tests for the first time:

```
ana@vm:~/bookshop$ sed -i 's/ --enable-native-access=ALL-UNNAMED//' pom.xml && grep -c 'enable-native-access' pom.xml
0
ana@vm:~/bookshop$ mvn -B verify 2>&1 | grep -E '^WARNING|Skipped: 0$|BUILD'
[INFO] Tests run: 17, Failures: 0, Errors: 0, Skipped: 0
WARNING: A restricted method in java.lang.System has been called
WARNING: java.lang.System::load has been called by com.sun.jna.Native in an unnamed module (file:/home/ana/.m2/repository/net/java/dev/jna/jna/5.18.1/jna-5.18.1.jar)
WARNING: Use --enable-native-access=ALL-UNNAMED to avoid a warning for callers in this module
WARNING: Restricted methods will be blocked in a future release unless native access is enabled
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
```

Every test passed, and the failsafe fork printed four lines first. Since JDK 24 the JVM warns when
code calls a **restricted method**, one that reaches outside Java's guarantees; `System::load`, which
loads native code into the process, is one. The caller is **JNA**, Java Native Access, which arrives
with docker-java, the Docker client inside Testcontainers. The third line names the fix: allow native
access to the code on the class path, which the JVM calls the unnamed module.

The warning does not come back on every run. Testcontainers writes the way of reaching the engine
that worked into `~/.testcontainers.properties`, and a run that finds that file goes straight to the
socket without the search that loads JNA. So it shows on a first run, on a build server that starts
from a clean machine every time, and on every attempt that fails to find the engine, which are the
runs where nobody wants extra noise. Put the option back:

```
ana@vm:~/bookshop$ sed -i 's/mockito-core:jar}</mockito-core:jar} --enable-native-access=ALL-UNNAMED</' pom.xml && grep -c 'enable-native-access' pom.xml
2
```

## Running them

The same command, with the option in place. `tee` keeps the whole output in `/tmp/verify.log` for
the next paragraphs, and `~/.testcontainers.properties` was deleted again first, so this is a first
run too:

```
ana@vm:~/bookshop$ mvn -B verify 2>&1 | tee /tmp/verify.log | grep -E '^WARNING|Running |Tests run:|BUILD|Total time'
[INFO] Running com.example.bookshop.ordering.OrderTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.079 s -- in com.example.bookshop.ordering.OrderTest
[INFO] Running com.example.bookshop.ordering.OrderServiceTest
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.527 s -- in com.example.bookshop.ordering.OrderServiceTest
[INFO] Running com.example.bookshop.catalogue.BookTest
[INFO] Running take
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.009 s -- in take
[INFO] Tests run: 0, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.015 s -- in com.example.bookshop.catalogue.BookTest
[INFO] Running com.example.bookshop.catalogue.IsbnTest
[INFO] Tests run: 10, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.082 s -- in com.example.bookshop.catalogue.IsbnTest
[INFO] Tests run: 17, Failures: 0, Errors: 0, Skipped: 0
[INFO] Running com.example.bookshop.BookshopApplicationIT
[INFO] Tests run: 1, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 6.733 s -- in com.example.bookshop.BookshopApplicationIT
[INFO] Running com.example.bookshop.catalogue.BookRepositoryIT
[INFO] Tests run: 2, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 3.070 s -- in com.example.bookshop.catalogue.BookRepositoryIT
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
[INFO] BUILD SUCCESS
[INFO] Total time:  14.740 s
```

No warning this time. Surefire's seventeen unit tests passed first, as before. Then failsafe ran
three tests in two classes, and the build succeeded. The log in `/tmp/verify.log` says what
happened in between, and the first thing is Testcontainers finding the engine:

```
ana@vm:~/bookshop$ grep -E 'DockerClientProviderStrategy|DockerClientFactory   : (Testcontainers|Docker host|Connected)|tc.testcontainers/ryuk|RyukResourceReaper' /tmp/verify.log
2026-10-22T20:29:33.651-03:00  INFO 30480 --- [bookshop] [           main] [] org.testcontainers.DockerClientFactory   : Testcontainers version: 2.0.5
2026-10-22T20:29:34.031-03:00  INFO 30480 --- [bookshop] [           main] [] o.t.d.DockerClientProviderStrategy       : Found Docker environment with local Unix socket (unix:///var/run/docker.sock)
2026-10-22T20:29:34.035-03:00  INFO 30480 --- [bookshop] [           main] [] org.testcontainers.DockerClientFactory   : Docker host IP address is localhost
2026-10-22T20:29:34.049-03:00  INFO 30480 --- [bookshop] [           main] [] org.testcontainers.DockerClientFactory   : Connected to docker: 
2026-10-22T20:29:34.120-03:00  INFO 30480 --- [bookshop] [           main] [] tc.testcontainers/ryuk:0.14.0            : Creating container for image: testcontainers/ryuk:0.14.0
2026-10-22T20:29:34.273-03:00  INFO 30480 --- [bookshop] [           main] [] tc.testcontainers/ryuk:0.14.0            : Container testcontainers/ryuk:0.14.0 is starting: 10b9cde176b8d7220d95e2f098467e51b85098a2cd0a81a9cc3f3a0a3da03149
2026-10-22T20:29:34.547-03:00  INFO 30480 --- [bookshop] [           main] [] tc.testcontainers/ryuk:0.14.0            : Container testcontainers/ryuk:0.14.0 started in PT0.427031218S
2026-10-22T20:29:34.552-03:00  INFO 30480 --- [bookshop] [           main] [] o.t.utility.RyukResourceReaper           : Ryuk started - will monitor and terminate Testcontainers containers on JVM exit
```

It looked for the socket where Docker's packages put it, connected, and started a first container
that is not a database. **Ryuk** is Testcontainers' reaper. The test JVM keeps a connection open to
it, and that connection closes when the run ends, or when the JVM crashes or is killed. Ryuk then
waits a few seconds and removes every container that run started, and itself. Without it,
a test run stopped with Ctrl+C in the middle would leave its databases running until somebody
noticed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 380\" role=\"img\" aria-label=\"A sequence across four lanes: the test JVM, Docker Engine, the Ryuk container and the PostgreSQL container. 1, the JVM asks the engine to start Ryuk and keeps a connection open to it. 2, it asks for postgres:16-alpine with port 5432 published on a free port of the machine. 3, it waits until PostgreSQL says it is ready. 4, @ServiceConnection hands the address, user and password to Spring; Flyway migrates and the tests run against the container. 5, the JVM exits, the connection to Ryuk closes, and Ryuk removes whatever containers are left and then itself.\"><defs><marker id=\"f19c-ad\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"f19c-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"15\" y=\"12\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">test JVM</text><text x=\"95.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">failsafe</text><line x1=\"95\" y1=\"52\" x2=\"95\" y2=\"362\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 4\"></line><rect x=\"210\" y=\"12\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Docker Engine</text><text x=\"290.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/var/run/docker.sock</text><line x1=\"290\" y1=\"52\" x2=\"290\" y2=\"362\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 4\"></line><rect x=\"400\" y=\"12\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Ryuk</text><text x=\"480.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">testcontainers/ryuk</text><line x1=\"480\" y1=\"52\" x2=\"480\" y2=\"362\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 4\"></line><rect x=\"585\" y=\"12\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"665.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">PostgreSQL</text><text x=\"665.0\" y=\"41.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">postgres:16-alpine</text><line x1=\"665\" y1=\"52\" x2=\"665\" y2=\"362\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 4\"></line><line x1=\"95\" y1=\"92\" x2=\"284\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19c-ad)\"></line><text x=\"192.5\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">start Ryuk</text><circle cx=\"43\" cy=\"92\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"43\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">1</text><line x1=\"290\" y1=\"104\" x2=\"474\" y2=\"104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19c-ad)\"></line><line x1=\"95\" y1=\"122\" x2=\"474\" y2=\"122\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f19c-am)\"></line><text x=\"382.5\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a connection that stays open</text><line x1=\"95\" y1=\"166\" x2=\"284\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19c-ad)\"></line><text x=\"222.5\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">start postgres, 5432 on a free port</text><circle cx=\"43\" cy=\"166\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"43\" y=\"167\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">2</text><line x1=\"290\" y1=\"178\" x2=\"659\" y2=\"178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19c-ad)\"></line><line x1=\"665\" y1=\"214\" x2=\"101\" y2=\"214\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19c-ad)\"></line><text x=\"380.0\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ready to accept connections</text><circle cx=\"43\" cy=\"214\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"43\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">3</text><line x1=\"95\" y1=\"262\" x2=\"659\" y2=\"262\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19c-ad)\"></line><text x=\"380.0\" y=\"251\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">@ServiceConnection: Flyway, then the tests</text><circle cx=\"43\" cy=\"262\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"43\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">4</text><line x1=\"95\" y1=\"316\" x2=\"474\" y2=\"316\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f19c-am)\"></line><text x=\"287.5\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the JVM exits: the connection closes</text><circle cx=\"43\" cy=\"316\" r=\"10\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle><text x=\"43\" y=\"317\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">5</text><line x1=\"480\" y1=\"340\" x2=\"659\" y2=\"340\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19c-ad)\"></line><text x=\"572.5\" y=\"329\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">removes what is left, then itself</text></svg>", "caption": "Ryuk is the reason a test run that crashes still leaves no container behind: it acts on the closed connection, not on a message the JVM may never send."}
```

Then the database:

```
ana@vm:~/bookshop$ grep -E 'FlywayExecutor|DbMigrate|Started BookshopApplicationIT|Catalogue opened' /tmp/verify.log | head -n 8
2026-10-22T20:29:36.176-03:00  INFO 30480 --- [bookshop] [           main] [] org.flywaydb.core.FlywayExecutor         : Database: jdbc:postgresql://localhost:32869/test?loggerLevel=OFF (PostgreSQL 16.15)
2026-10-22T20:29:36.270-03:00  INFO 30480 --- [bookshop] [           main] [] o.f.core.internal.command.DbMigrate      : Current version of schema "public": << Empty Schema >>
2026-10-22T20:29:36.276-03:00  INFO 30480 --- [bookshop] [           main] [] o.f.core.internal.command.DbMigrate      : Migrating schema "public" to version "1 - catalogue"
2026-10-22T20:29:36.299-03:00  INFO 30480 --- [bookshop] [           main] [] o.f.core.internal.command.DbMigrate      : Migrating schema "public" to version "2 - first titles"
2026-10-22T20:29:36.308-03:00  INFO 30480 --- [bookshop] [           main] [] o.f.core.internal.command.DbMigrate      : Migrating schema "public" to version "3 - stock and orders"
2026-10-22T20:29:36.324-03:00  INFO 30480 --- [bookshop] [           main] [] o.f.core.internal.command.DbMigrate      : Successfully applied 3 migrations to schema "public", now at version v3 (execution time 00:00.028s)
2026-10-22T20:29:38.617-03:00  INFO 30480 --- [bookshop] [           main] [] c.e.bookshop.BookshopApplicationIT       : Started BookshopApplicationIT in 6.221 seconds (process running for 7.114)
2026-10-22T20:29:38.674-03:00  INFO 30480 --- [bookshop] [           main] [] c.e.bookshop.catalogue.CatalogueReport   : Catalogue opened on 2026-10-22 with 6 books
```

PostgreSQL 16.15 in a container, the database `test`, Flyway applying lesson 13's and lesson 14's
three migrations to an empty schema, and the application started with the six books the test then
counted. The port in the JDBC URL is the one Docker chose this time.

`BookRepositoryIT` started a second container, its own, and a much smaller context:

```
ana@vm:~/bookshop$ grep -E 'BookRepositoryIT  : (Started|No active)|tc.postgres.*(started in|JDBC URL)|^Hibernate:' /tmp/verify.log | tail -n 6
2026-10-22T20:29:40.196-03:00  INFO 30480 --- [bookshop] [           main] [] tc.postgres:16-alpine                    : Container postgres:16-alpine started in PT1.34241367S
2026-10-22T20:29:40.196-03:00  INFO 30480 --- [bookshop] [           main] [] tc.postgres:16-alpine                    : Container is started (JDBC URL: jdbc:postgresql://localhost:32870/test?loggerLevel=OFF)
2026-10-22T20:29:40.219-03:00  INFO 30480 --- [bookshop] [           main] [] c.e.bookshop.catalogue.BookRepositoryIT  : No active profile set, falling back to 1 default profile: "default"
2026-10-22T20:29:40.575-03:00  INFO 30480 --- [bookshop] [           main] [] c.e.bookshop.catalogue.BookRepositoryIT  : Started BookRepositoryIT in 0.372 seconds (process running for 9.072)
Hibernate: select b1_0.id,b1_0.author_id,a1_0.id,a1_0.name,b1_0.isbn,b1_0.price_cents,b1_0.stock,b1_0.title from book b1_0 join author a1_0 on a1_0.id=b1_0.author_id where upper(b1_0.title) like upper(?) escape '\' order by b1_0.title
Hibernate: select b1_0.title,b1_0.price_cents from book b1_0 join author a1_0 on a1_0.id=b1_0.author_id where a1_0.name=? order by b1_0.title
```

The two `Hibernate:` lines are the SQL of the two queries under test, printed because `@DataJpaTest`
switches on `spring.jpa.show-sql`. And when the build is over, `docker ps -a` lists every container
that carries Testcontainers' label, running or not:

```
ana@vm:~/bookshop$ docker ps -a --filter label=org.testcontainers=true --format '{{.Image}}  {{.Status}}'
testcontainers/ryuk:0.14.0  Up 9 seconds
ana@vm:~/bookshop$ sleep 15; docker ps -a --filter label=org.testcontainers=true --format '{{.Image}}  {{.Status}}'
```

Right after the build only Ryuk is left. The two databases were already gone, stopped by their
owners as the run ended: the context closed and took its bean with it, and the extension stopped the
class's field after the last test. Fifteen seconds later Ryuk had gone too, which is the wait above
followed by its last job.
