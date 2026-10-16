---
title: Tasks and the graph
version: 1
---

Lesson 1 drew Maven's lifecycle as a line: ask for a phase and every phase before it runs, in
order. **Gradle has no line. It has tasks, each declaring the tasks it needs, and a request
selects the part of that graph it reaches.** Ask for `build` and nearly everything runs; ask for
`run` and Gradle compiles the main code and starts it, without looking at a test.

## Tasks

A **task** is one unit of work with a name: compile the main sources, make the jar, run the tests.
Plugins bring them. `tasks` lists the ones meant to be asked for by name, about thirty in this
project, and `--group` narrows the list to one group:

```
ana@vm:~/isbn-gradle$ ./gradlew tasks --group build

> Task :tasks

------------------------------------------------------------
Tasks runnable from root project 'isbn-check'
------------------------------------------------------------

Build tasks
-----------
assemble - Assembles the outputs of this project.
build - Assembles and tests this project.
buildDependents - Assembles and tests this project and all projects that depend on it.
buildNeeded - Assembles and tests this project and all projects it depends on.
classes - Assembles main classes.
clean - Deletes the build directory.
jar - Assembles a jar archive containing the classes of the 'main' feature.
testClasses - Assembles test classes.

To see all tasks and more detail, run gradlew tasks --all

To see more detail about a task, run gradlew help --task <task>

BUILD SUCCESSFUL in 1s
1 actionable task: 1 executed
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.1/userguide/configuration_cache_enabling.html
```

The project is called `isbn-check` here, from `settings.gradle.kts`, though its directory is
`isbn-gradle`. `./gradlew tasks` without `--group` adds the application, distribution,
documentation, help and verification groups, `run` and `test` among them.

## A build

`build` is the task that does everything a release needs:

```
ana@vm:~/isbn-gradle$ ./gradlew build
> Task :compileJava
> Task :processResources NO-SOURCE
> Task :classes
> Task :jar
> Task :startScripts
> Task :distTar
> Task :distZip
> Task :assemble
> Task :compileTestJava
> Task :processTestResources NO-SOURCE
> Task :testClasses
> Task :test
> Task :check
> Task :build

BUILD SUCCESSFUL in 21s
7 actionable tasks: 7 executed
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.1/userguide/configuration_cache_enabling.html
```

Every task printed a line, the plain console at work, and each line without a word after it ran.
`NO-SOURCE` means the task had nothing to read: there is no `src/main/resources` in this project,
so `processResources` skipped itself. The summary counts seven **actionable** tasks, the ones with
work of their own; `classes`, `testClasses`, `assemble`, `check` and `build` only gather other
tasks, and `processResources` and `processTestResources` had nothing to do.

The first build of a project is the slow one, because Gradle compiles the two build scripts and
resolves the dependencies before any task runs. Its products are in `build/`, Gradle's
counterpart of Maven's `target/`:

```
ana@vm:~/isbn-gradle$ ls build/libs build/distributions
build/distributions:
isbn-check-1.0.0.tar
isbn-check-1.0.0.zip

build/libs:
isbn-check-1.0.0.jar
ana@vm:~/isbn-gradle$ grep -o 'tests="[0-9]*" skipped="[0-9]*" failures="[0-9]*"' build/test-results/test/*.xml
tests="3" skipped="0" failures="0"
```

The jar holds the project's own classes, as Maven's does. The two archives are the
`application` plugin's **distribution**: unpacked, each gives a `bin/` with a launcher script and a
`lib/` with the jar and every jar it depends on, so the program can be run on another machine
with a Java and nothing else. And the test results are XML in the same shape as Maven's, three
tests and no failures; Gradle writes an HTML report beside them, in
`build/reports/tests/test/index.html`, and prints nothing about tests that pass.

## The graph behind it

`--dry-run` shows what a request would execute, in order, without executing any of it:

```
ana@vm:~/isbn-gradle$ ./gradlew build --dry-run
:compileJava SKIPPED
:processResources SKIPPED
:classes SKIPPED
:jar SKIPPED
:startScripts SKIPPED
:distTar SKIPPED
:distZip SKIPPED
:assemble SKIPPED
:compileTestJava SKIPPED
:processTestResources SKIPPED
:testClasses SKIPPED
:test SKIPPED
:check SKIPPED
:build SKIPPED

BUILD SUCCESSFUL in 2s
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.1/userguide/configuration_cache_enabling.html
```

That is the order, and the order is only one way to walk the graph Gradle built. The graph itself
is the thing to hold in your head:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 790 250\" role=\"img\" aria-label=\"The tasks of the java and application plugins as a graph. compileJava leads to classes, then jar, startScripts, distTar and distZip, then assemble. From classes a second branch runs compileTestJava, testClasses, test and check. assemble and check both lead to build. run hangs off classes alone.\"><defs><marker id=\"gtg-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"112\" y1=\"55.0\" x2=\"117\" y2=\"55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"225\" y1=\"55.0\" x2=\"230\" y2=\"55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"338\" y1=\"55.0\" x2=\"343\" y2=\"55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"451\" y1=\"55.0\" x2=\"456\" y2=\"33.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"451\" y1=\"55.0\" x2=\"456\" y2=\"77.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"564\" y1=\"33.0\" x2=\"569\" y2=\"55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"564\" y1=\"77.0\" x2=\"569\" y2=\"55.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"172.0\" y1=\"70\" x2=\"172.0\" y2=\"168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"172.0\" y1=\"70\" x2=\"230\" y2=\"185.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"338\" y1=\"185.0\" x2=\"343\" y2=\"185.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"451\" y1=\"185.0\" x2=\"456\" y2=\"185.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"564\" y1=\"185.0\" x2=\"569\" y2=\"185.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"677\" y1=\"55.0\" x2=\"682\" y2=\"120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><line x1=\"677\" y1=\"185.0\" x2=\"682\" y2=\"120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gtg-ah)\"></line><rect x=\"6\" y=\"40\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"59.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">compileJava</text><rect x=\"119\" y=\"40\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"172.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">classes</text><rect x=\"232\" y=\"40\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"285.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">jar</text><rect x=\"345\" y=\"40\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"398.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">startScripts</text><rect x=\"458\" y=\"18\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"511.0\" y=\"33.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">distTar</text><rect x=\"458\" y=\"62\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"511.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">distZip</text><rect x=\"571\" y=\"40\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"624.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">assemble</text><rect x=\"119\" y=\"170\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"172.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">run</text><rect x=\"232\" y=\"170\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"285.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">compileTestJava</text><rect x=\"345\" y=\"170\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"398.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">testClasses</text><rect x=\"458\" y=\"170\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"511.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">test</text><rect x=\"571\" y=\"170\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"624.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">check</text><rect x=\"684\" y=\"105.0\" width=\"106\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"737.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">build</text><text x=\"59.0\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">main code</text><text x=\"398.0\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tests</text><text x=\"172.0\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">only for ./gradlew run</text></svg>", "caption": "The tasks the `java` and `application` plugins add, each arrow pointing from a task to one that needs it. `build` pulls in both branches; `run` needs only `classes`, so it never compiles or runs a test."}
```

`build` needs `assemble` and `check`, and each of those pulls in its branch. `test` needs the test
classes, which are compiled against the main classes, so the main code always compiles first.
Nothing makes a jar wait for the tests: in Maven, `package` comes after `test` in the line, while
here `./gradlew jar` compiles and packages and never touches a test. To get a jar only from tested
code, you ask for `build`.

`run` is the other end of the drawing. It needs the compiled classes and their classpath, so it
runs three tasks and starts the program. `-q` keeps Gradle quiet, leaving only what the program
printed:

```
ana@vm:~/isbn-gradle$ ./gradlew -q run --args="978-0-306-40615-7 0-306-40615-2 978-0-306-40615-8"
978-0-306-40615-7: valid, ISBN-13 9780306406157
0-306-40615-2: valid, ISBN-13 9780306406157
978-0-306-40615-8: invalid
```

The same three verdicts lesson 1's tests assert. Lesson 1 had to assemble a classpath by hand to
run the jar, because the jar does not carry Commons Validator; `run` builds that classpath from
the dependencies declared in the script.

## The dependency report

The dependencies form a graph of their own, and `dependencies` prints it for one configuration:

```
ana@vm:~/isbn-gradle$ ./gradlew -q dependencies --configuration runtimeClasspath

------------------------------------------------------------
Root project 'isbn-check'
------------------------------------------------------------

runtimeClasspath - Runtime classpath of source set 'main'.
\--- commons-validator:commons-validator:1.11.0
     +--- commons-beanutils:commons-beanutils:1.11.0
     |    +--- commons-logging:commons-logging:1.3.5 -> 1.4.0
     |    \--- commons-collections:commons-collections:3.2.2
     +--- commons-digester:commons-digester:2.1
     +--- commons-logging:commons-logging:1.4.0
     \--- commons-collections:commons-collections:3.2.2

(*) - Indicates repeated occurrences of a transitive dependency subtree. Gradle expands transitive dependency subtrees only once per project; repeat occurrences only display the root of the subtree, followed by this annotation.

A web-based, searchable dependency report is available by adding the --scan option.
```

It is the tree lesson 1 printed with `mvn dependency:tree`, in another notation. One line is worth
stopping at: `commons-logging:commons-logging:1.3.5 -> 1.4.0`. Commons BeanUtils asked for 1.3.5,
Commons Validator asked for 1.4.0, and **Gradle resolved the conflict by taking the higher
version**. The arrow is how the report says so. The last section compares that rule with Maven's.

## A failure, on purpose

The script carries a line that looked optional, the JUnit launcher. Remove it and run the tests:

```
ana@vm:~/isbn-gradle$ sed -i '/junit-platform-launcher/d' build.gradle.kts
ana@vm:~/isbn-gradle$ ./gradlew test
> Task :compileJava UP-TO-DATE
> Task :processResources NO-SOURCE
> Task :classes UP-TO-DATE
> Task :compileTestJava UP-TO-DATE
> Task :processTestResources NO-SOURCE
> Task :testClasses UP-TO-DATE

> Task :test FAILED

Gradle Test Executor 2 FAILED
    org.gradle.api.internal.tasks.testing.TestSuiteExecutionException at SuiteTestDefinitionProcessor.java:45
        Caused by: org.gradle.api.internal.tasks.testing.RequiresTestFrameworkTestDefinitionProcessor$TestFrameworkNotAvailableException at JUnitPlatformTestDefinitionProcessor.java:101

FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':test' (registered by plugin 'org.gradle.jvm-test-suite').
> Test process encountered an unexpected problem.
   > Could not start Gradle Test Executor 2.
      > Failed to load JUnit Platform.  Please ensure that all JUnit Platform dependencies are available on the test's runtime classpath, including the JUnit Platform launcher.

* Try:
> Check common problems https://docs.gradle.org/9.8.1/userguide/java_testing.html#sec:java_testing_troubleshooting.
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights from a Build Scan (powered by Develocity).
> Get more help at https://help.gradle.org.

BUILD FAILED in 8s
3 actionable tasks: 1 executed, 2 up-to-date
```

Two things to read. The compile tasks are `UP-TO-DATE`: the launcher was never on the classpath
the tests compile against, so removing it changed nothing there, and only starting the tests
needed it. And the message
names exactly what is missing, `the JUnit Platform launcher`. Gradle 8 put the launcher on the test
classpath by itself; Gradle 9 stopped, and a build upgraded from 8 to 9 that never named it meets
this message on its first test run.

Put the line back where it was in `build.gradle.kts`,
`testRuntimeOnly("org.junit.platform:junit-platform-launcher:6.0.3")` after the
`testImplementation` line, and build again. The tests run and pass, and the rest of the build,
untouched by the change, is not redone. The next section is about how Gradle knows that.
