---
title: Phases, goals and the build lifecycle
version: 1
---

`mvn compile`, `mvn package` and `mvn dependency:tree` look like three commands of one kind. They
are two kinds. `dependency:tree` names a **goal**: one task of one plugin, run once. `compile` and
`package` name a **phase**: a step in a fixed sequence called a **lifecycle**, and asking for a
phase runs every phase before it as well.

Maven itself does almost nothing. **The work is done by plugins**, each a jar of goals, and the
lifecycle is the order in which their goals run. A project with `jar` packaging gets a goal bound
to six phases of the default lifecycle without writing a line about it, and two more, `install`
and `deploy`, at the end:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 328\" role=\"img\" aria-label=\"Ten phases of the default lifecycle from validate to deploy, each with the plugin goal a jar project binds to it: resources:resources at process-resources, compiler:compile at compile, resources:testResources at process-test-resources, compiler:testCompile at test-compile, surefire:test at test, jar:jar at package, install:install at install and deploy:deploy at deploy; validate and verify have nothing bound. Brackets show that mvn test runs the phases up to test, mvn package up to package and mvn install up to install.\"><text x=\"130\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">phase</text><text x=\"300\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">goal bound to it, for a jar</text><rect x=\"30\" y=\"44\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">validate</text><line x1=\"130\" y1=\"66\" x2=\"130\" y2=\"72\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"300\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nothing bound</text><rect x=\"30\" y=\"72\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">process-resources</text><line x1=\"130\" y1=\"94\" x2=\"130\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"232\" y1=\"83.0\" x2=\"292\" y2=\"83.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"300\" y=\"83.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">resources:resources</text><rect x=\"30\" y=\"100\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">compile</text><line x1=\"130\" y1=\"122\" x2=\"130\" y2=\"128\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"232\" y1=\"111.0\" x2=\"292\" y2=\"111.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"300\" y=\"111.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">compiler:compile</text><rect x=\"30\" y=\"128\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">process-test-resources</text><line x1=\"130\" y1=\"150\" x2=\"130\" y2=\"156\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"232\" y1=\"139.0\" x2=\"292\" y2=\"139.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"300\" y=\"139.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">resources:testResources</text><rect x=\"30\" y=\"156\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">test-compile</text><line x1=\"130\" y1=\"178\" x2=\"130\" y2=\"184\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"232\" y1=\"167.0\" x2=\"292\" y2=\"167.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"300\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">compiler:testCompile</text><rect x=\"30\" y=\"184\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">test</text><line x1=\"130\" y1=\"206\" x2=\"130\" y2=\"212\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"232\" y1=\"195.0\" x2=\"292\" y2=\"195.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"300\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">surefire:test</text><rect x=\"30\" y=\"212\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">package</text><line x1=\"130\" y1=\"234\" x2=\"130\" y2=\"240\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"232\" y1=\"223.0\" x2=\"292\" y2=\"223.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"300\" y=\"223.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">jar:jar</text><rect x=\"30\" y=\"240\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">verify</text><line x1=\"130\" y1=\"262\" x2=\"130\" y2=\"268\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"300\" y=\"251.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nothing bound</text><rect x=\"30\" y=\"268\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"279.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">install</text><line x1=\"130\" y1=\"290\" x2=\"130\" y2=\"296\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"232\" y1=\"279.0\" x2=\"292\" y2=\"279.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"300\" y=\"279.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">install:install</text><rect x=\"30\" y=\"296\" width=\"200\" height=\"22\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130\" y=\"307.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">deploy</text><line x1=\"232\" y1=\"307.0\" x2=\"292\" y2=\"307.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"300\" y=\"307.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">deploy:deploy</text><path d=\"M 492 46 H 500 V 204 H 492\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><text x=\"500\" y=\"217\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">mvn test</text><path d=\"M 557 46 H 565 V 232 H 557\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><text x=\"565\" y=\"245\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">mvn package</text><path d=\"M 622 46 H 630 V 288 H 622\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><text x=\"630\" y=\"301\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">mvn install</text></svg>", "caption": "Ten of the default lifecycle's 23 phases: the ones a jar binds a goal to, and validate and verify. A command names one phase and runs every phase before it as well."}
```

## Reading a build

That figure is what scrolls past when you package the project. Each line between dashes is one
goal running, in the form `plugin:version:goal (execution) @ project`:

```
ana@vm:~/isbn-check$ mvn package
[INFO] Scanning for projects...
[INFO] 
[INFO] -----------------------< com.example:isbn-check >-----------------------
[INFO] Building isbn-check 1.0.0
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:resources (default-resources) @ isbn-check ---
[INFO] skip non existing resourceDirectory /home/ana/isbn-check/src/main/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:compile (default-compile) @ isbn-check ---
[INFO] Nothing to compile - all classes are up to date.
[INFO] 
[INFO] --- maven-resources-plugin:3.5.0:testResources (default-testResources) @ isbn-check ---
[INFO] skip non existing resourceDirectory /home/ana/isbn-check/src/test/resources
[INFO] 
[INFO] --- maven-compiler-plugin:3.15.0:testCompile (default-testCompile) @ isbn-check ---
[INFO] Recompiling the module because of changed source code.
[INFO] Compiling 1 source file with javac [debug release 25] to target/test-classes
[INFO] 
[INFO] --- maven-surefire-plugin:3.5.6:test (default-test) @ isbn-check ---
[INFO] Using auto detected provider org.apache.maven.surefire.junitplatform.JUnitPlatformProvider
[INFO] 
[INFO] -------------------------------------------------------
[INFO]  T E S T S
[INFO] -------------------------------------------------------
[INFO] Running com.example.isbn.IsbnCheckTest
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0, Time elapsed: 0.058 s -- in com.example.isbn.IsbnCheckTest
[INFO] 
[INFO] Results:
[INFO] 
[INFO] Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
[INFO] 
[INFO] 
[INFO] --- maven-jar-plugin:3.5.1:jar (default-jar) @ isbn-check ---
[INFO] Building jar: /home/ana/isbn-check/target/isbn-check-1.0.0.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.020 s
[INFO] Finished at: 2026-10-22T19:33:40-03:00
[INFO] ------------------------------------------------------------------------
```

Six goals ran, in the order of the figure, and the name in brackets, `default-compile` and so on,
is the **execution**: the binding Maven made on its own because the packaging is `jar`. The
compiler had nothing to do for the program, which the first build had compiled and nobody had
changed since, and it compiled the test class, which was new. Surefire found that class under
`src/test/java`, ran its 3 tests and summed them up. Had one failed, the build would have ended
there with `BUILD FAILURE`, and the jar plugin would never have run: **a phase runs only if every
phase before it passed**, so a jar `mvn package` leaves in `target/` is one whose tests passed.
Its name is the artifact id and the version, `isbn-check-1.0.0.jar`.

## The phases you will type

`mvn test` stops after the tests, which is the quick question "does it still work", and
`-q` (quiet) prints only warnings and errors, so a passing run prints nothing at all:

```
ana@vm:~/isbn-check$ mvn -q test
```

`mvn package` is the one above. `mvn verify` runs everything `package` does and then the
phase where integration tests and checks belong; this project has none, and lesson 19 adds them.
`mvn install` copies the project's jar and pom into your local repository, where another project
on the same machine can name it as a dependency like any library from outside. Its output is the
build above plus two lines, so `tail -n 8` keeps only the end:

```
ana@vm:~/isbn-check$ mvn install | tail -n 8
[INFO] Installing /home/ana/isbn-check/pom.xml to /home/ana/.m2/repository/com/example/isbn-check/1.0.0/isbn-check-1.0.0.pom
[INFO] Installing /home/ana/isbn-check/target/isbn-check-1.0.0.jar to /home/ana/.m2/repository/com/example/isbn-check/1.0.0/isbn-check-1.0.0.jar
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  1.376 s
[INFO] Finished at: 2026-10-22T19:33:44-03:00
[INFO] ------------------------------------------------------------------------
ana@vm:~/isbn-check$ ls ~/.m2/repository/com/example/isbn-check/1.0.0
_remote.repositories
isbn-check-1.0.0.jar
isbn-check-1.0.0.pom
```

`mvn deploy` would upload them to a shared repository, which needs a server and credentials
this course does not set up.

## Another lifecycle, and flags worth knowing

`target/` is the build's output and nothing else, and `mvn clean` deletes it. `clean` is a phase
of a second, separate lifecycle, so `mvn clean package` names one phase of each and runs both in
order: first an empty `target/`, then a full build. Use it when a build behaves in a way you cannot
explain, and not out of habit, since it throws away compiled classes the next build would reuse.

Three flags appear in this course. `-q` is above. `-B` (batch mode) turns off colours and the
progress counters of downloads, which is what you want in a script or a log file. And
`-DskipTests` runs every phase but executes no test, for a build whose tests you have just run;
a build that ships should never use it.
