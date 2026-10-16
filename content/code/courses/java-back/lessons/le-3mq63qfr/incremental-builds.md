---
title: Incremental builds
version: 1
---

The wrong picture of a build is a recipe, run from the top each time. **Gradle treats each task as
a function: the same inputs give the same outputs, so a task whose inputs have not changed since
its outputs were made has nothing to do.** Before it runs a task, Gradle fingerprints everything
the task declared as input and compares that with what it recorded last time. This section
watches that comparison, starting from the build just made.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Before a task runs, Gradle fingerprints what goes in: source files, classpath, Java version and compiler options. If the fingerprint matches the last run in this directory, the task is UP-TO-DATE and nothing runs. If not, and the build cache holds outputs for that fingerprint, they are copied in and the task is FROM-CACHE. Otherwise the action runs and its outputs and fingerprint are recorded.\"><defs><marker id=\"gdc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"40\" width=\"130\" height=\"150\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"75\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">what goes in</text><text x=\"75\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">source files</text><text x=\"75\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">classpath</text><text x=\"75\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Java version</text><text x=\"75\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">compiler options</text><line x1=\"140\" y1=\"115\" x2=\"168\" y2=\"115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gdc-ah)\"></line><rect x=\"170\" y=\"95\" width=\"110\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"225.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fingerprint</text><line x1=\"280\" y1=\"115\" x2=\"308\" y2=\"115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gdc-ah)\"></line><rect x=\"310\" y=\"92\" width=\"200\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">same as the last run here?</text><line x1=\"510\" y1=\"115\" x2=\"548\" y2=\"115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gdc-ah)\"></line><text x=\"529\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">yes</text><rect x=\"550\" y=\"92\" width=\"160\" height=\"46\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">UP-TO-DATE</text><text x=\"630\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nothing runs</text><line x1=\"410\" y1=\"138\" x2=\"410\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gdc-ah)\"></line><text x=\"420\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no</text><rect x=\"310\" y=\"168\" width=\"200\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">in the build cache?</text><line x1=\"510\" y1=\"188\" x2=\"548\" y2=\"188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gdc-ah)\"></line><text x=\"529\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">yes</text><rect x=\"550\" y=\"168\" width=\"160\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">FROM-CACHE</text><text x=\"630\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">outputs copied in</text><line x1=\"410\" y1=\"208\" x2=\"410\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gdc-ah)\"></line><text x=\"420\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no</text><rect x=\"310\" y=\"238\" width=\"200\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"410.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">run the action</text><line x1=\"510\" y1=\"256\" x2=\"548\" y2=\"256\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gdc-ah)\"></line><rect x=\"550\" y=\"238\" width=\"160\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.6\" fill=\"var(--paper)\">record outputs and fingerprint</text><text x=\"630\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the work is done</text></svg>", "caption": "The question Gradle asks of every task before running it. Two of the three answers do no work, and the comparison is of contents, never of timestamps."}
```

## Nothing changed

Build again, with nothing edited:

```
ana@vm:~/isbn-gradle$ ./gradlew build
> Task :compileJava UP-TO-DATE
> Task :processResources NO-SOURCE
> Task :classes UP-TO-DATE
> Task :jar UP-TO-DATE
> Task :startScripts UP-TO-DATE
> Task :distTar UP-TO-DATE
> Task :distZip UP-TO-DATE
> Task :assemble UP-TO-DATE
> Task :compileTestJava UP-TO-DATE
> Task :processTestResources NO-SOURCE
> Task :testClasses UP-TO-DATE
> Task :test UP-TO-DATE
> Task :check UP-TO-DATE
> Task :build UP-TO-DATE

BUILD SUCCESSFUL in 2s
7 actionable tasks: 7 up-to-date
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.1/userguide/configuration_cache_enabling.html
```

Every task is **`UP-TO-DATE`** and the summary says `7 up-to-date`: Gradle compared, found the
inputs and outputs as it left them, and ran nothing. The two seconds are Gradle reading the
scripts and making the comparison.

Now change a source file's modification time without changing a byte of it:

```
ana@vm:~/isbn-gradle$ touch src/main/java/com/example/isbn/IsbnCheck.java && ./gradlew build
> Task :compileJava UP-TO-DATE
> Task :processResources NO-SOURCE
> Task :classes UP-TO-DATE
> Task :jar UP-TO-DATE
> Task :startScripts UP-TO-DATE
> Task :distTar UP-TO-DATE
> Task :distZip UP-TO-DATE
> Task :assemble UP-TO-DATE
> Task :compileTestJava UP-TO-DATE
> Task :processTestResources NO-SOURCE
> Task :testClasses UP-TO-DATE
> Task :test UP-TO-DATE
> Task :check UP-TO-DATE
> Task :build UP-TO-DATE

BUILD SUCCESSFUL in 1s
7 actionable tasks: 7 up-to-date
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.1/userguide/configuration_cache_enabling.html
```

Still nothing. Gradle fingerprints a file by its contents, not by its date, so a `touch`, a fresh
`git checkout` or a copy that resets the dates does not make a task run. Maven's compiler plugin
decides whether a source is stale by comparing its date with its class file's, and the same `touch`
would have sent lesson 1's build back to `javac`.

## One file changed

Change what the program prints between an ISBN and its verdict, from `: ` to ` -> `:

```
ana@vm:~/isbn-gradle$ sed -i 's/": "/" -> "/' src/main/java/com/example/isbn/IsbnCheck.java
ana@vm:~/isbn-gradle$ ./gradlew build
> Task :compileJava
> Task :processResources NO-SOURCE
> Task :classes
> Task :jar
> Task :startScripts
> Task :distTar
> Task :distZip
> Task :assemble
> Task :compileTestJava UP-TO-DATE
> Task :processTestResources NO-SOURCE
> Task :testClasses UP-TO-DATE
> Task :test
> Task :check
> Task :build

BUILD SUCCESSFUL in 5s
7 actionable tasks: 6 executed, 1 up-to-date
Consider enabling configuration cache to speed up this build: https://docs.gradle.org/9.8.1/userguide/configuration_cache_enabling.html
ana@vm:~/isbn-gradle$ ./gradlew -q run --args="0-306-40615-2"
0-306-40615-2 -> valid, ISBN-13 9780306406157
```

Read which tasks ran. `compileJava` ran, because its input changed. `jar`, `startScripts` and the
distributions ran, because their input is the class file `compileJava` just rewrote: **a change
travels down the graph only as far as the outputs actually change**. `test` ran, because the
classes it executes are different. And `run` prints the new separator, from the class that was
just compiled.

And `compileTestJava` stayed `UP-TO-DATE`, which is the subtle one. The edit was inside the body
of `main`; no class, method or signature that a test could compile against changed. Gradle
compares the main classes' **ABI**, their public signatures, when deciding whether to recompile
code that depends on them, and skips the recompile when the signatures are the same. That is
called compile avoidance, and on a project of fifty modules it is the difference between
recompiling one module and recompiling everything downstream of it.

`--info` makes Gradle say why each task ran. Put the separator back and ask:

```
ana@vm:~/isbn-gradle$ sed -i 's/" -> "/": "/' src/main/java/com/example/isbn/IsbnCheck.java
ana@vm:~/isbn-gradle$ ./gradlew build --info | grep -A1 'is not up-to-date'
Task ':compileJava' is not up-to-date because:
  Input property 'stableSources' file /home/ana/isbn-gradle/src/main/java/com/example/isbn/IsbnCheck.java has changed.
--
Task ':jar' is not up-to-date because:
  Input property 'rootSpec$1' file /home/ana/isbn-gradle/build/classes/java/main/com/example/isbn/IsbnCheck.class has changed.
--
Task ':startScripts' is not up-to-date because:
  Input property 'classpath' file /home/ana/isbn-gradle/build/libs/isbn-check-1.0.0.jar has changed.
--
Task ':distTar' is not up-to-date because:
  Input property 'rootSpec$1$1$1$1$1' file /home/ana/isbn-gradle/build/libs/isbn-check-1.0.0.jar has changed.
--
Task ':distZip' is not up-to-date because:
  Input property 'rootSpec$1$1$1$1$1' file /home/ana/isbn-gradle/build/libs/isbn-check-1.0.0.jar has changed.
--
Task ':test' is not up-to-date because:
  Input property 'stableClasspath' file /home/ana/isbn-gradle/build/classes/java/main/com/example/isbn/IsbnCheck.class has changed.
```

Each reason names the input that changed and which file it was. The chain is visible in the
paths: the `.java` file changed, so its `.class` changed, so the jar changed, so everything holding
the jar ran. The reasons are worth keeping in mind for the day a task runs when you did not expect
it to: `--info` names the input, and the input is usually somewhere you did not think to look.

## The build cache and the configuration cache

`UP-TO-DATE` needs the outputs still sitting in `build/`. After `clean`, or in a fresh clone, there
is nothing to be up to date with. The **build cache** answers that case: a store, in
`~/.gradle/caches`, of task outputs keyed by the fingerprint of their inputs. If a task's
fingerprint is in it, Gradle copies the outputs in instead of running the task.

The **configuration cache** is a different saving. Before any task runs, Gradle runs the build
scripts to work out the graph, and that phase is paid on every build, which is the two seconds a
build that did nothing took. With the configuration cache, Gradle stores the graph it computed for
a given request and reuses it until a script or a property changes. It is the cache Gradle has
been suggesting at the bottom of every build in this lesson.

Both are switched on in `gradle.properties`. Replace the file with this:

```properties
org.gradle.console=plain
org.gradle.caching=true
org.gradle.configuration-cache=true
```

Then clean and build twice:

```
ana@vm:~/isbn-gradle$ ./gradlew clean build
Calculating task graph as no cached configuration is available for tasks: clean build
> Task :clean
> Task :processResources NO-SOURCE
> Task :processTestResources NO-SOURCE
> Task :compileJava
> Task :classes
> Task :jar
> Task :compileTestJava
> Task :startScripts
> Task :testClasses
> Task :distTar
> Task :distZip
> Task :assemble
> Task :test
> Task :check
> Task :build

BUILD SUCCESSFUL in 14s
8 actionable tasks: 8 executed
Configuration cache entry stored.
ana@vm:~/isbn-gradle$ ./gradlew clean build
Reusing configuration cache.
> Task :clean
> Task :processTestResources NO-SOURCE
> Task :processResources NO-SOURCE
> Task :compileJava FROM-CACHE
> Task :classes UP-TO-DATE
> Task :jar
> Task :startScripts
> Task :compileTestJava FROM-CACHE
> Task :testClasses UP-TO-DATE
> Task :distTar
> Task :test FROM-CACHE
> Task :check UP-TO-DATE
> Task :distZip
> Task :assemble
> Task :build

BUILD SUCCESSFUL in 1s
8 actionable tasks: 5 executed, 3 from cache
Configuration cache entry reused.
ana@vm:~/isbn-gradle$ ls ~/.gradle/caches/build-cache-1 | wc -l
5
```

The first run had no stored graph (`Calculating task graph as no cached configuration is
available`) and nothing in the build cache, so it executed all eight tasks, `clean` included, and
stored both. The second deleted `build/` again with `clean`, and then took **`compileJava`,
`compileTestJava` and `test` `FROM-CACHE`**: their outputs, test results included, were copied
from the cache, and no compiler or test ran. The order of the lines also changed, because with the
configuration cache Gradle runs independent tasks at the same time.

`jar` and the distributions ran anyway. Gradle does not cache archive tasks, because zipping a
few files is cheaper than looking them up and copying them back. The time went from 14 seconds to
1, and on a project where compiling and testing take minutes, that is the saving that matters.

The cache in `~/.gradle` serves the projects on this machine. A team or a CI server can point
Gradle at a **remote build cache** on a server, so that a pull request built on one machine leaves
outputs that every other machine can reuse. It is the same mechanism with a longer reach, and it
is why a fresh CI checkout does not have to recompile what somebody else already compiled.
