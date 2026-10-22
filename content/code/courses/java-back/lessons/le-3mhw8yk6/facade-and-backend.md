---
title: The facade and the backend
version: 1
---

The common picture of logging in Java is one library that your code imports and that writes the
lines. **There are two halves, and your code meets only one of them.** The half your code calls is a
**facade**: an interface with methods like `info` and `warn` and no opinion about where a line goes.
The half that formats a line and writes it somewhere is the **backend**. In this course the facade is
**SLF4J**, the Simple Logging Facade for Java, and the backend is **Logback**, because that is what
Spring Boot ships.

The split exists because a Java application is mostly other people's code. Spring, Hibernate,
HikariCP and Tomcat all log, they were written by different teams in different years, and they chose
different logging APIs. If each brought its own backend, one program would write in four formats to
four places with four sets of levels. The facade lets every library log through one interface and
leaves the choice of backend to whoever assembles the application, which is you.

## What the bookshop already carries

Lesson 4 met `spring-boot-starter-logging` in the starter's dependency tree. Asking Maven for the
logging libraries alone shows where each one comes from:

```
ana@vm:~/bookshop$ mvn dependency:tree -Dincludes=org.slf4j,ch.qos.logback,org.apache.logging.log4j,commons-logging,org.jboss.logging
[INFO] Scanning for projects...
[INFO] 
[INFO] ------------------------< com.example:bookshop >------------------------
[INFO] Building bookshop 0.1.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-dependency-plugin:3.10.0:tree (default-cli) @ bookshop ---
[INFO] com.example:bookshop:jar:0.1.0
[INFO] +- org.springframework.boot:spring-boot-starter-webmvc:jar:4.1.1:compile
[INFO] |  +- org.springframework.boot:spring-boot-starter:jar:4.1.1:compile
[INFO] |  |  \- org.springframework.boot:spring-boot-starter-logging:jar:4.1.1:compile
[INFO] |  |     +- ch.qos.logback:logback-classic:jar:1.5.38:compile
[INFO] |  |     |  \- ch.qos.logback:logback-core:jar:1.5.38:compile
[INFO] |  |     +- org.apache.logging.log4j:log4j-to-slf4j:jar:2.25.5:compile
[INFO] |  |     |  \- org.apache.logging.log4j:log4j-api:jar:2.25.5:compile
[INFO] |  |     \- org.slf4j:jul-to-slf4j:jar:2.0.18:compile
[INFO] |  \- org.springframework.boot:spring-boot-http-converter:jar:4.1.1:compile
[INFO] |     \- org.springframework.boot:spring-boot:jar:4.1.1:compile
[INFO] |        \- org.springframework:spring-core:jar:7.0.9:compile
[INFO] |           \- commons-logging:commons-logging:jar:1.3.6:compile
[INFO] +- org.springframework.boot:spring-boot-starter-validation:jar:4.1.1:compile
[INFO] |  \- org.springframework.boot:spring-boot-validation:jar:4.1.1:compile
[INFO] |     \- org.hibernate.validator:hibernate-validator:jar:9.1.3.Final:compile
[INFO] |        \- org.jboss.logging:jboss-logging:jar:3.6.3.Final:compile
[INFO] \- org.springframework.boot:spring-boot-starter-data-jpa:jar:4.1.1:compile
[INFO]    \- org.springframework.boot:spring-boot-starter-jdbc:jar:4.1.1:compile
[INFO]       \- com.zaxxer:HikariCP:jar:7.0.2:compile
[INFO]          \- org.slf4j:slf4j-api:jar:2.0.18:compile
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.254 s
[INFO] Finished at: 2026-10-16T20:28:13-03:00
[INFO] ------------------------------------------------------------------------
```

Read it from the bottom. `slf4j-api` is the facade, and Maven files it under HikariCP only because
that is the first place it met it; Logback depends on it too. `logback-classic` is the backend.
Everything else is a way in: Spring's own classes log through `commons-logging`, Hibernate's
validator through `jboss-logging`, and two **bridges** catch the rest. `log4j-to-slf4j` takes calls
made to the Log4j API and hands them to SLF4J, and `jul-to-slf4j` does the same for
`java.util.logging`, the JDK's built-in logger. Note what is absent: `log4j-core`, the Log4j backend.
The last section of this lesson is about why that absence once mattered to everybody.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Five sources of log calls on the left: your code through the SLF4J API, Spring's classes through commons-logging, Hibernate through jboss-logging, a Log4j API library through log4j-to-slf4j and java.util.logging through jul-to-slf4j. All five arrows meet at slf4j-api, which has one arrow to logback-classic, which writes to the console.\"><defs><marker id=\"ffb-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"14\" width=\"240\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"134\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">your code</text><text x=\"134\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">LoggerFactory.getLogger</text><line x1=\"254\" y1=\"36\" x2=\"368\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"14\" y=\"70\" width=\"240\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"134\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Spring's own classes</text><text x=\"134\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">commons-logging</text><line x1=\"254\" y1=\"92\" x2=\"368\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"14\" y=\"126\" width=\"240\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"134\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Hibernate</text><text x=\"134\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">jboss-logging</text><line x1=\"254\" y1=\"148\" x2=\"368\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"14\" y=\"182\" width=\"240\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"134\" y=\"197\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a library on the Log4j API</text><text x=\"134\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">log4j-to-slf4j</text><line x1=\"254\" y1=\"204\" x2=\"368\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"14\" y=\"238\" width=\"240\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"134\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a library on java.util.logging</text><text x=\"134\" y=\"269\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">jul-to-slf4j</text><line x1=\"254\" y1=\"260\" x2=\"368\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"370\" y=\"118\" width=\"130\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"435\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">slf4j-api</text><text x=\"435\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the facade</text><line x1=\"500\" y1=\"150\" x2=\"538\" y2=\"150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"540\" y=\"118\" width=\"166\" height=\"64\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"623\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">logback-classic</text><text x=\"623\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the one backend</text><line x1=\"623\" y1=\"182\" x2=\"623\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#ffb-ah)\"></line><rect x=\"553\" y=\"238\" width=\"140\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"623\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the console</text></svg>", "caption": "Five ways in, one way out. Each library logs through the API it chose; the bridges in Boot's logging starter send all of it to SLF4J, and SLF4J to the one backend on the classpath."}
```

## The facade on its own

The cleanest way to see the two halves is a program small enough to run with each backend in turn.
Create `~/logging-look/pom.xml`. It has no code to build: it exists so that Maven can work out a
classpath, and each **profile** adds one backend to the single dependency every variant shares:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>logging-look</artifactId>
  <version>1.0.0</version>

  <dependencies>
    <dependency>
      <groupId>org.slf4j</groupId>
      <artifactId>slf4j-api</artifactId>
      <version>2.0.18</version>
    </dependency>
  </dependencies>

  <profiles>
    <profile>
      <id>logback</id>
      <dependencies>
        <dependency>
          <groupId>ch.qos.logback</groupId>
          <artifactId>logback-classic</artifactId>
          <version>1.5.38</version>
        </dependency>
      </dependencies>
    </profile>
    <profile>
      <id>log4j2</id>
      <dependencies>
        <dependency>
          <groupId>org.apache.logging.log4j</groupId>
          <artifactId>log4j-slf4j2-impl</artifactId>
          <version>2.25.5</version>
        </dependency>
        <dependency>
          <groupId>org.apache.logging.log4j</groupId>
          <artifactId>log4j-core</artifactId>
          <version>2.25.5</version>
        </dependency>
      </dependencies>
    </profile>
    <profile>
      <id>tinylog</id>
      <dependencies>
        <dependency>
          <groupId>org.tinylog</groupId>
          <artifactId>slf4j-tinylog</artifactId>
          <version>2.8.1</version>
        </dependency>
        <dependency>
          <groupId>org.tinylog</groupId>
          <artifactId>tinylog-impl</artifactId>
          <version>2.8.1</version>
        </dependency>
      </dependencies>
    </profile>
  </profiles>

  <build>
    <pluginManagement>
      <plugins>
        <plugin>
          <artifactId>maven-dependency-plugin</artifactId>
          <version>3.10.0</version>
        </plugin>
      </plugins>
    </pluginManagement>
  </build>
</project>
```

The versions are the ones Boot 4.1.1 manages for the bookshop, so the first two variants download
nothing new. Beside it, `~/logging-look/Hello.java`, which imports SLF4J and nothing else:

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Hello {

    private static final Logger log = LoggerFactory.getLogger(Hello.class);

    public static void main(String[] args) {
        log.debug("Looking up book {}", 3);
        log.info("Order {} placed by {}: {} line(s)", 7, "ana", 2);
        log.warn("Only {} of '{}' left", 1, "Frankenstein");
        try {
            Integer.parseInt("two");
        } catch (NumberFormatException e) {
            log.error("Quantity '{}' is not a number", "two", e);
        }
    }
}
```

`LoggerFactory.getLogger(Hello.class)` asks for a **logger**, and the class it is given becomes the
logger's **name**: `Hello` here, `com.example.bookshop.ordering.OrderService` in the bookshop. Every
line carries that name, and the next section uses it to choose which lines appear.

`mvn dependency:build-classpath` resolves the jars a project needs and joins their paths with colons,
which is exactly what `java -cp` takes; `-Dmdep.outputFile=cp.txt` writes that string to a file, and `-q` keeps Maven silent unless
something fails.
`java` then runs the source file straight away with that classpath. First with no profile,
so the facade is alone (`cp.txt` has no newline at its end, hence the `echo`):

```
ana@vm:~/logging-look$ mvn -q dependency:build-classpath -Dmdep.outputFile=cp.txt
ana@vm:~/logging-look$ cat cp.txt; echo
/home/ana/.m2/repository/org/slf4j/slf4j-api/2.0.18/slf4j-api-2.0.18.jar
ana@vm:~/logging-look$ java -cp "$(cat cp.txt)" Hello.java
SLF4J(W): No SLF4J providers were found.
SLF4J(W): Defaulting to no-operation (NOP) logger implementation
SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
```

The program compiled, ran and finished, and **none of its four lines was written, the error
included.** SLF4J looked for a **provider**, which is what a backend is called from SLF4J's side,
found none, said so three times, and replaced every logger with one that discards everything. That
is the facade doing its job exactly: it has no idea how to write a line. A server started this way
would run for months with an empty log, so those three warnings are worth recognising.

Now with Logback:

```
ana@vm:~/logging-look$ mvn -q dependency:build-classpath -Dmdep.outputFile=cp.txt -P logback
ana@vm:~/logging-look$ tr ':' '\n' < cp.txt; echo
/home/ana/.m2/repository/org/slf4j/slf4j-api/2.0.18/slf4j-api-2.0.18.jar
/home/ana/.m2/repository/ch/qos/logback/logback-classic/1.5.38/logback-classic-1.5.38.jar
/home/ana/.m2/repository/ch/qos/logback/logback-core/1.5.38/logback-core-1.5.38.jar
ana@vm:~/logging-look$ java -cp "$(cat cp.txt)" Hello.java
20:28:19.674 [main] DEBUG Hello -- Looking up book 3
20:28:19.677 [main] INFO Hello -- Order 7 placed by ana: 2 line(s)
20:28:19.677 [main] WARN Hello -- Only 1 of 'Frankenstein' left
20:28:19.678 [main] ERROR Hello -- Quantity 'two' is not a number
java.lang.NumberFormatException: For input string: "two"
	at java.base/java.lang.NumberFormatException.forInputString(NumberFormatException.java:67)
	at java.base/java.lang.Integer.parseInt(Integer.java:565)
	at java.base/java.lang.Integer.parseInt(Integer.java:662)
	at Hello.main(Hello.java:13)
	at java.base/jdk.internal.reflect.DirectMethodHandleAccessor.invoke(DirectMethodHandleAccessor.java:104)
	at java.base/java.lang.reflect.Method.invoke(Method.java:565)
	at jdk.compiler/com.sun.tools.javac.launcher.SourceLauncher.execute(SourceLauncher.java:258)
	at jdk.compiler/com.sun.tools.javac.launcher.SourceLauncher.run(SourceLauncher.java:138)
	at jdk.compiler/com.sun.tools.javac.launcher.SourceLauncher.main(SourceLauncher.java:76)
```

Same source file, three more jars, and now every line arrives: the time, the thread, the level, the
logger's name and the message, with the exception's stack trace after the last one. Nothing in
`Hello.java` changed between the two runs. **Choosing a backend is a change to the classpath, never
to the code**, and that is the whole promise of a facade. The format above is Logback's own default,
used when nobody configured it; the bookshop's lines look different because Spring Boot configures
Logback before the first one is written, which is where the next section starts.
