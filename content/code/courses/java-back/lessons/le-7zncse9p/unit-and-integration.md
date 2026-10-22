---
title: Unit tests and integration tests, surefire and failsafe
version: 1
---

`OrderServiceTest` is a **unit test**: one class, its collaborators replaced, nothing outside the
JVM, a second to run. The next tests in this lesson are **integration tests**: the real service, the
real repositories, Hibernate, Flyway and a real PostgreSQL, checked together, because the questions
they answer — does this query return what its name promises, do the migrations produce the schema
the entities expect — have no answer without the real parts. They take seconds, and they need a
container engine on the machine.

Mocks cannot replace them. A mock of `BookRepository` returns what the test told it to, so a test
that mocks the repository can never find a mistake in the repository's own query. **Each kind of
test is blind exactly where the other one looks**, and a project keeps both, as two separate runs.

## Two plugins, two naming rules

Maven keeps them apart by class name, with one plugin for each:

| plugin | runs classes named | in the phase | a failing test |
| --- | --- | --- | --- |
| **surefire** | `*Test`, `Test*`, `*Tests`, `*TestCase` | `test` | stops the build there |
| **failsafe** | `*IT`, `IT*`, `*ITCase` | `integration-test`, then `verify` | is recorded, and stops the build at `verify` |

So `OrderServiceTest` is surefire's and the two classes of the section after next will be
`BookshopApplicationIT` and `BookRepositoryIT`, failsafe's. The suffix is the whole switch: a test
class named `BookRepositoryTests` would run with the unit tests, start a container in the middle of
them, and slow down every `mvn test` there is.

Failsafe splits its work across two phases on purpose. An integration test often needs something
started before it and stopped after it, a server or a database, and the build must stop it even when
the tests failed. So failsafe runs the tests in `integration-test` and only writes down the result;
`post-integration-test` runs whatever stops the outside world; and `verify` reads the record and
fails the build. The bookshop binds nothing to the two phases around the tests, because Testcontainers
starts and stops its own containers from inside the test JVM.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 360\" role=\"img\" aria-label=\"Maven's default lifecycle from compile to verify, one phase per row. Surefire runs the classes named Test at the test phase and stops the build on a failure. The jar is built at package. Failsafe runs the classes named IT at integration-test and only records failures; post-integration-test still runs; at verify failsafe reads the record and fails the build. mvn test runs the phases up to test; mvn verify runs them all.\"><defs><marker id=\"f19b-ad\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"f19b-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"30\" y=\"20\" width=\"210\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">compile</text><line x1=\"135\" y1=\"50\" x2=\"135\" y2=\"59\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19b-ad)\"></line><rect x=\"30\" y=\"60\" width=\"210\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">test-compile</text><line x1=\"135\" y1=\"90\" x2=\"135\" y2=\"99\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19b-ad)\"></line><rect x=\"30\" y=\"100\" width=\"210\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">test</text><line x1=\"135\" y1=\"130\" x2=\"135\" y2=\"139\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19b-ad)\"></line><line x1=\"244\" y1=\"115\" x2=\"268\" y2=\"115\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"274\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">surefire runs *Test; a failure stops here</text><rect x=\"30\" y=\"140\" width=\"210\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">package</text><line x1=\"135\" y1=\"170\" x2=\"135\" y2=\"179\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19b-ad)\"></line><line x1=\"244\" y1=\"155\" x2=\"268\" y2=\"155\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"274\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the jar, repackaged by Boot</text><rect x=\"30\" y=\"180\" width=\"210\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">pre-integration-test</text><line x1=\"135\" y1=\"210\" x2=\"135\" y2=\"219\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19b-ad)\"></line><line x1=\"244\" y1=\"195\" x2=\"268\" y2=\"195\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"274\" y=\"195\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nothing bound in the bookshop</text><rect x=\"30\" y=\"220\" width=\"210\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">integration-test</text><line x1=\"135\" y1=\"250\" x2=\"135\" y2=\"259\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19b-ad)\"></line><line x1=\"244\" y1=\"235\" x2=\"268\" y2=\"235\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"274\" y=\"235\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">failsafe runs *IT and records failures</text><rect x=\"30\" y=\"260\" width=\"210\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">post-integration-test</text><line x1=\"135\" y1=\"290\" x2=\"135\" y2=\"299\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f19b-ad)\"></line><line x1=\"244\" y1=\"275\" x2=\"268\" y2=\"275\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"274\" y=\"275\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">clean-up would run here, even after a failure</text><rect x=\"30\" y=\"300\" width=\"210\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"135.0\" y=\"315.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">verify</text><line x1=\"244\" y1=\"315\" x2=\"268\" y2=\"315\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></line><text x=\"274\" y=\"315\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">failsafe reads the record: the build fails here</text><path d=\"M 567 22 L 575 22 L 575 128 L 567 128\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><text x=\"583\" y=\"75.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">mvn test</text><path d=\"M 667 22 L 675 22 L 675 328 L 667 328\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><text x=\"683\" y=\"175.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">mvn verify</text></svg>", "caption": "Each command runs the phase it names and every phase before it. The amber phases are the ones this lesson binds a plugin to."}
```

## Turning failsafe on

Spring Boot's parent manages failsafe and already binds its two goals, but a plugin from the parent's
`pluginManagement` only runs if the project's own `<build>` names it. Replace the `<build>` element
once more, with this one. Failsafe is new, between surefire and the javadoc plugin:

```xml
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
```

The `<executions>` block repeats what the parent already says, and changes nothing; written here it
makes the binding visible to whoever reads this file, without a trip into the parent's pom. Failsafe
gets the agent in its `argLine` for surefire's reason: the integration tests run in a fork of their
own, and a test there that creates a mock needs it too.

**Both `argLine`s also end in a new option, `--enable-native-access=ALL-UNNAMED`.** It is for the
integration tests, which will reach Docker, and the section on Testcontainers shows the warning it
prevents. The unit tests never reach Docker and do not need it; surefire's line carries it anyway,
so that the two lines stay identical and nobody has to remember which fork lacks what.

`mvn verify` runs every phase up to `verify`, unit tests included. With no `*IT` class yet, `grep`
keeps the line Maven prints as each plugin starts, the totals (the lines ending in `Skipped: 0`
without a class name after them) and the result:

```
ana@vm:~/bookshop$ mvn -B verify 2>&1 | grep -E '^\[INFO\] --- |Skipped: 0$|No tests|BUILD'
[INFO] --- maven-dependency-plugin:3.10.0:properties (default) @ bookshop ---
[INFO] --- maven-resources-plugin:3.5.0:resources (default-resources) @ bookshop ---
[INFO] --- maven-compiler-plugin:3.15.0:compile (default-compile) @ bookshop ---
[INFO] --- maven-resources-plugin:3.5.0:testResources (default-testResources) @ bookshop ---
[INFO] --- maven-compiler-plugin:3.15.0:testCompile (default-testCompile) @ bookshop ---
[INFO] --- maven-surefire-plugin:3.5.6:test (default-test) @ bookshop ---
[INFO] Tests run: 17, Failures: 0, Errors: 0, Skipped: 0
[INFO] --- maven-jar-plugin:3.5.1:jar (default-jar) @ bookshop ---
[INFO] --- spring-boot-maven-plugin:4.1.1:repackage (repackage) @ bookshop ---
[INFO] --- maven-failsafe-plugin:3.5.6:integration-test (default) @ bookshop ---
[INFO] --- maven-failsafe-plugin:3.5.6:verify (default) @ bookshop ---
[INFO] No tests to run.
[INFO] BUILD SUCCESS
```

Surefire ran the seventeen unit tests, the jar was built and repackaged, and failsafe ran and found
no test to run. **`mvn test` stops before `package`, so it never runs an integration test**, and that
is the command for the minute-by-minute loop. `mvn verify` is the one before a commit, and the one a
build server runs, which `testing-cicd` sets up.
