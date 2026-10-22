---
title: Testing through the port
version: 1
---

Lesson 19 left the bookshop with three kinds of test. `OrderServiceTest` runs the service with
Mockito standing in for the repositories, `BookRepositoryIT` runs the repository against PostgreSQL
in a container, and `BookshopApplicationIT` starts the whole application context against the same
kind of container. **None of them sends an HTTP request.** So nothing has yet checked that
`GET /books/1` answers 200 with JSON, that a book nobody has comes back as the problem detail of
lesson 7, or that `POST /books` without a token is refused with the 401 of lesson 15. All of that
lives between the socket and the service, in code that no test has run.

A common first idea is to test the controller by calling it: build a `BookController`, call
`get(1)`, look at what it returns. That checks a method. It skips the mapping from the path to the
method, the conversion of `"1"` into a `long`, the security filters, Jackson, and the error handler,
which together are what a client actually meets. **An API test is a client.** It sends a request
to a running server and judges the answer by what crossed the wire: the status, the headers and the
body.

## Two ways to start the application in a test

`@SpringBootTest` starts the application context, and its `webEnvironment` attribute says whether a
server comes with it:

| `webEnvironment` | what starts | how a request reaches the controller |
|---|---|---|
| `MOCK`, the default | the context, with a mock servlet environment and no server | in the same thread, through Spring's `MockMvc`, with no socket |
| `RANDOM_PORT` | the context and the embedded Tomcat, on a free port | over a real HTTP connection |
| `DEFINED_PORT` | the same, on `server.port`, 8080 here | over a real HTTP connection, if nothing else holds 8080 |
| `NONE` | the context, without any web layer | it does not |

`BookshopApplicationIT` uses the default, which is why it could ask `BookService` for a count and
never open a connection. The test this lesson writes asks for **`RANDOM_PORT`**. A free port chosen
at start-up means the test never collides with a bookshop you left running in another terminal, or
with a second build on the same machine, which is exactly what `DEFINED_PORT` would do.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"One JVM, started by failsafe, holds both the test and the application. REST Assured sends real HTTP over loopback to Tomcat on a random port; the request goes through the security filter chain, the controller and its error handler, and JPA, which talks JDBC to PostgreSQL in a container outside the JVM.\"><defs><marker id=\"l20p-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"20\" width=\"490\" height=\"265\" rx=\"5\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one JVM, started by failsafe</text><rect x=\"35\" y=\"120\" width=\"135\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"102\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">REST Assured</text><text x=\"102\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the client</text><rect x=\"220\" y=\"50\" width=\"270\" height=\"222\" rx=\"5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the Spring context</text><rect x=\"240\" y=\"80\" width=\"230\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Tomcat, on a random port</text><rect x=\"240\" y=\"128\" width=\"230\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the security filter chain</text><polyline points=\"355,116 355,127\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l20p-ah)\"></polyline><rect x=\"240\" y=\"176\" width=\"230\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">controllers and ApiErrorHandler</text><polyline points=\"355,164 355,175\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l20p-ah)\"></polyline><rect x=\"240\" y=\"224\" width=\"230\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"355\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">JPA and Hibernate</text><polyline points=\"355,212 355,223\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l20p-ah)\"></polyline><polyline points=\"170,148 200,148 200,98 238,98\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l20p-ah)\"></polyline><text x=\"196\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">real HTTP</text><text x=\"196\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">over loopback</text><rect x=\"540\" y=\"214\" width=\"145\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"612\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">postgres:16-alpine</text><text x=\"612\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a container, outside the JVM</text><polyline points=\"470,242 538,242\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l20p-ah)\"></polyline><text x=\"522\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">JDBC</text></svg>", "caption": "RANDOM_PORT starts the whole application inside the test JVM, and REST Assured reaches it the way any client would: through a socket."}
```

`MockMvc` skips the socket and Tomcat, and it is a fair choice for testing a controller's mapping.
This lesson uses a real port because its question is what a client sees, and the client of an API
arrives through a socket.

## REST Assured

**REST Assured** is a Java library for testing HTTP APIs: an HTTP client and a set of assertions,
written as one sentence per request. Spring Boot's parent does not manage its version, so the pom
names it in a property of its own, the way it already names springdoc's. Replace `pom.xml` with this
one. Two things are new: the `rest-assured.version` property, and the dependency near the end of
`<dependencies>`, in the `test` scope.

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
    <springdoc.version>3.1.1</springdoc.version>
    <rest-assured.version>6.1.0</rest-assured.version>
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
      <groupId>io.rest-assured</groupId>
      <artifactId>rest-assured</artifactId>
      <version>${rest-assured.version}</version>
      <scope>test</scope>
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
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-dependency-plugin</artifactId>
        <executions>
          <execution>
            <goals>
              <goal>properties</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-surefire-plugin</artifactId>
        <configuration>
          <argLine>-javaagent:${org.mockito:mockito-core:jar} --enable-native-access=ALL-UNNAMED</argLine>
        </configuration>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-failsafe-plugin</artifactId>
        <configuration>
          <argLine>-javaagent:${org.mockito:mockito-core:jar} --enable-native-access=ALL-UNNAMED</argLine>
        </configuration>
        <executions>
          <execution>
            <goals>
              <goal>integration-test</goal>
              <goal>verify</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
      <plugin>
        <groupId>org.apache.maven.plugins</groupId>
        <artifactId>maven-javadoc-plugin</artifactId>
        <configuration>
          <show>public</show>
          <doclint>all,-missing</doclint>
        </configuration>
      </plugin>
    </plugins>
  </build>
</project>
```

Its dependencies are worth one look, because two of them surprise people:

```
ana@vm:~/bookshop$ mvn dependency:tree -Dincludes=io.rest-assured,org.apache.groovy,org.apache.httpcomponents,org.hamcrest | grep -E 'rest-assured|groovy|httpc|hamcrest'
[INFO] |  \- org.hamcrest:hamcrest:jar:3.0:test
[INFO] \- io.rest-assured:rest-assured:jar:6.1.0:test
[INFO]    +- org.apache.groovy:groovy:jar:5.0.8:test
[INFO]    +- org.apache.groovy:groovy-xml:jar:5.0.8:test
[INFO]    +- org.apache.httpcomponents:httpclient:jar:4.5.13:test
[INFO]    |  \- org.apache.httpcomponents:httpcore:jar:4.4.16:test
[INFO]    +- org.apache.httpcomponents:httpmime:jar:4.5.13:test
[INFO]    +- io.rest-assured:json-path:jar:6.1.0:test
[INFO]    |  +- org.apache.groovy:groovy-json:jar:5.0.8:test
[INFO]    |  \- io.rest-assured:rest-assured-common:jar:6.1.0:test
[INFO]    \- io.rest-assured:xml-path:jar:6.1.0:test
```

REST Assured sends its requests with Apache **HttpClient** 4.5, not with the JDK's own client, and
it reads JSON and XML bodies with **Groovy**: the path you write to reach a field, such as `title`
or `lines.size()`, is Groovy's GPath. Neither ever appears in your test code. Look at the Groovy
version, too, against the one REST Assured's own parent pom asks for:

```
ana@vm:~/bookshop$ grep groovy.version ~/.m2/repository/io/rest-assured/rest-assured-parent/6.1.0/rest-assured-parent-6.1.0.pom
        <groovy.version>5.0.3</groovy.version>
                            <version>${groovy.version}</version>
                <version>${groovy.version}</version>
```

REST Assured asks for 5.0.3 and the build uses 5.0.8. Spring Boot's parent manages Groovy, and
the list of versions lesson 4 described applies to every library on it, including one that arrives
through somebody else's pom.

The test class goes where failsafe looks for integration tests, with a name ending in `IT`, as
lesson 19 arranged: `src/test/java/com/example/bookshop/BooksApiIT.java`. The next section writes
it.
