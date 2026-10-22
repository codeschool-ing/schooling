---
title: Plugins, repositories, and running the result
version: 1
---

Every line of the build in the last section named a plugin **and a version**, and the versions
came from the `<build>` block of the pom. That block looks like ceremony. It is the difference
between a build that means the same thing on every machine and one that depends on which Maven
happens to be installed.

## What Maven picks when the pom does not say

Maven 3.8.7 carries its own list of plugin versions for the lifecycle, chosen when that version of
Maven was made, and uses it for any plugin the pom does not pin. To see that list at work, put the
pom aside, delete its `<build>` element, build, and put the pom back:

```
ana@vm:~/isbn-check$ cp pom.xml pom.xml.keep
ana@vm:~/isbn-check$ sed -i '/<build>/,/<\/build>/d' pom.xml
ana@vm:~/isbn-check$ mvn -q clean package
[ERROR] COMPILATION ERROR : 
[ERROR] Source option 5 is no longer supported. Use 8 or later.
[ERROR] Target option 5 is no longer supported. Use 8 or later.
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.1:compile (default-compile) on project isbn-check: Compilation failure: Compilation failure: 
[ERROR] Source option 5 is no longer supported. Use 8 or later.
[ERROR] Target option 5 is no longer supported. Use 8 or later.
[ERROR] -> [Help 1]
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoFailureException
```

With no `<build>`, every plugin is Maven 3.8.7's choice, and the first one to matter is the
compiler, at version 3.1. That version is older than `maven.compiler.release`, so it ignores the
property, falls back on a default of its own, Java 5, and JDK 25 refuses to compile for Java 5.

That failure is loud, at least. Give the old compiler the two settings it does understand, `source`
and `target`, and the build goes through. Then look at what else changed:

```
ana@vm:~/isbn-check$ mvn clean package -Dmaven.compiler.source=25 -Dmaven.compiler.target=25 | grep -E 'plugin:|Tests run|BUILD'
[INFO] --- maven-clean-plugin:2.5:clean (default-clean) @ isbn-check ---
[INFO] --- maven-resources-plugin:2.6:resources (default-resources) @ isbn-check ---
[INFO] --- maven-compiler-plugin:3.1:compile (default-compile) @ isbn-check ---
[INFO] --- maven-resources-plugin:2.6:testResources (default-testResources) @ isbn-check ---
[INFO] --- maven-compiler-plugin:3.1:testCompile (default-testCompile) @ isbn-check ---
[INFO] --- maven-surefire-plugin:2.12.4:test (default-test) @ isbn-check ---
Tests run: 0, Failures: 0, Errors: 0, Skipped: 0
[INFO] --- maven-jar-plugin:2.4:jar (default-jar) @ isbn-check ---
[INFO] BUILD SUCCESS
ana@vm:~/isbn-check$ mv pom.xml.keep pom.xml
```

Every plugin is older than the pinned one: clean 2.5, resources 2.6, compiler 3.1, surefire 2.12.4,
jar 2.4. The `grep` keeps the lines that name a plugin, the test count and the verdict, and the last
command puts the real pom back.

And it says **`Tests run: 0` beside `BUILD SUCCESS`**. Surefire 2.12.4 cannot run tests written for
the JUnit Platform, so it found none it could run, ran none, and reported success, while three
tests sat in `src/test/java`. Nothing on the screen looked wrong. That is the case for pinning
every plugin: a build that fails can be fixed by the person who reads it, and **a build that passes
without testing anything** is found by nobody.

## The one plugin the pom forgot

The `dependency:tree` run in the section on dependencies printed `maven-dependency-plugin:2.8`. The
dependency plugin is not bound to any phase, so the pom above never named it, and Maven used the
version from the same built-in list: 2.8, where the plugin's current version on Central is
3.11.0. It worked this time. The next goal you ask of it may be one 2.8 does not have, or does
differently, and the build would still say nothing about which version answered. Pin it like the
others. **Replace the `<build>` element of `pom.xml` with this one**, which adds one `<plugin>` at
the end:

```xml
  <build>
    <pluginManagement>
      <plugins>
        <plugin>
          <artifactId>maven-clean-plugin</artifactId>
          <version>3.5.0</version>
        </plugin>
        <plugin>
          <artifactId>maven-resources-plugin</artifactId>
          <version>3.5.0</version>
        </plugin>
        <plugin>
          <artifactId>maven-compiler-plugin</artifactId>
          <version>3.15.0</version>
        </plugin>
        <plugin>
          <artifactId>maven-surefire-plugin</artifactId>
          <version>3.5.6</version>
        </plugin>
        <plugin>
          <artifactId>maven-jar-plugin</artifactId>
          <version>3.5.1</version>
        </plugin>
        <plugin>
          <artifactId>maven-install-plugin</artifactId>
          <version>3.1.4</version>
        </plugin>
        <plugin>
          <artifactId>maven-deploy-plugin</artifactId>
          <version>3.1.4</version>
        </plugin>
        <plugin>
          <artifactId>maven-dependency-plugin</artifactId>
          <version>3.11.0</version>
        </plugin>
      </plugins>
    </pluginManagement>
  </build>
```

```
ana@vm:~/isbn-check$ mvn dependency:tree | grep maven-dependency-plugin
[INFO] --- maven-dependency-plugin:3.11.0:tree (default-cli) @ isbn-check ---
```

`pluginManagement` **pins a version without running anything**: it says "if this plugin is used,
use this version", whether the lifecycle calls it or you name one of its goals. The other
element, a `<plugins>` list directly under `<build>`, is for adding a goal to a phase or
configuring one, and lesson 17 uses it.

## Repositories

A **repository** is a directory tree of jars and poms laid out by coordinates, served over HTTP.
**Maven Central** is the public one every Maven knows without being told, at
`repo.maven.apache.org`. Your **local repository** in `~/.m2/repository` has the same layout and is
a cache of it, plus whatever `mvn install` put there:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 264\" role=\"img\" aria-label=\"The coordinates org.junit.jupiter, junit-jupiter, 6.0.3 become the path org/junit/jupiter/junit-jupiter/6.0.3/junit-jupiter-6.0.3.jar, the dots of the group turned into directories. The same path exists in Maven Central and in the local repository under ~/.m2/repository. A jar missing locally is downloaded from Central once and kept; every build on the machine reads it from the local repository.\"><defs><marker id=\"l1r-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"115\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">coordinates in the pom</text><rect x=\"20\" y=\"30\" width=\"190\" height=\"66\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"34\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">org.junit.jupiter</text><text x=\"34\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">junit-jupiter</text><text x=\"34\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6.0.3</text><text x=\"460\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the path they become, in any repository</text><rect x=\"280\" y=\"38\" width=\"400\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"294\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">org/junit/jupiter/junit-jupiter/6.0.3/</text><text x=\"294\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">junit-jupiter-6.0.3.jar</text><line x1=\"212\" y1=\"63\" x2=\"276\" y2=\"63\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l1r-ah)\"></line><rect x=\"20\" y=\"150\" width=\"240\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"140\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">local repository</text><text x=\"140\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">~/.m2/repository</text><rect x=\"440\" y=\"150\" width=\"240\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"560\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Maven Central</text><text x=\"560\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">repo.maven.apache.org/maven2</text><line x1=\"438\" y1=\"190\" x2=\"264\" y2=\"190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l1r-ah)\"></line><text x=\"350\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">only when missing:</text><text x=\"350\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">download once, keep</text><line x1=\"400\" y1=\"90\" x2=\"160\" y2=\"147\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#l1r-ah)\"></line><line x1=\"560\" y1=\"90\" x2=\"560\" y2=\"147\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#l1r-ah)\"></line><line x1=\"140\" y1=\"206\" x2=\"140\" y2=\"236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l1r-ah)\"></line><text x=\"140\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every build on this machine reads from here</text></svg>", "caption": "Coordinates are an address. The group's dots become directories, and the same path leads to the same file in Central and in your local repository."}
```

Maven looks in the local repository first and asks Central only for what is missing, once. That is
why the second build of a project prints no downloads and works without a network.

The transcripts in this course were recorded on a machine that reached Central through a mirror,
because Central answered its downloads with "429 Too Many Requests". A transcript that shows a
download therefore names `google-maven-central` and a Google address; on your machine the
same line says `central` and `repo.maven.apache.org`. The files are Central's in both cases, with
the same checksums. You need no mirror and no configuration for it.

## Running the program

The jar `package` produced is the project's own classes and nothing else:

```
ana@vm:~/isbn-check$ jar tf target/isbn-check-1.0.0.jar
META-INF/
META-INF/MANIFEST.MF
com/
com/example/
com/example/isbn/
com/example/isbn/IsbnCheck.class
META-INF/maven/
META-INF/maven/com.example/
META-INF/maven/com.example/isbn-check/
META-INF/maven/com.example/isbn-check/pom.xml
META-INF/maven/com.example/isbn-check/pom.properties
```

One class of ours, a manifest, and the pom, which Maven copies in for the record. No Commons
Validator, so the obvious command fails as soon as the program touches the library:

```
ana@vm:~/isbn-check$ java -cp target/isbn-check-1.0.0.jar com.example.isbn.IsbnCheck 978-0-306-40615-7
Exception in thread "main" java.lang.NoClassDefFoundError: org/apache/commons/validator/routines/ISBNValidator
	at com.example.isbn.IsbnCheck.<clinit>(IsbnCheck.java:7)
Caused by: java.lang.ClassNotFoundException: org.apache.commons.validator.routines.ISBNValidator
	at java.base/jdk.internal.loader.BuiltinClassLoader.loadClass(BuiltinClassLoader.java:580)
	at java.base/java.lang.ClassLoader.loadClass(ClassLoader.java:490)
	... 1 more
```

`NoClassDefFoundError` is the JVM looking for a class the first time the code needs it and finding
it on no part of the classpath. The classpath has to name every jar of the program's `compile` and
`runtime` scopes, and the dependency plugin writes that list:

```
ana@vm:~/isbn-check$ mvn -q dependency:build-classpath -DincludeScope=runtime -Dmdep.outputFile=classpath.txt
ana@vm:~/isbn-check$ tr ':' '\n' < classpath.txt; echo
/home/ana/.m2/repository/commons-validator/commons-validator/1.11.0/commons-validator-1.11.0.jar
/home/ana/.m2/repository/commons-beanutils/commons-beanutils/1.11.0/commons-beanutils-1.11.0.jar
/home/ana/.m2/repository/commons-digester/commons-digester/2.1/commons-digester-2.1.jar
/home/ana/.m2/repository/commons-logging/commons-logging/1.4.0/commons-logging-1.4.0.jar
/home/ana/.m2/repository/commons-collections/commons-collections/3.2.2/commons-collections-3.2.2.jar
```

`includeScope=runtime` keeps the `compile` and `runtime` scopes and drops `test`: five jars, the
program's library and the four it brought, all in your local repository, which is why this needs
no network. `outputFile` writes the list to a file, joined with colons the way `-cp` wants them;
`tr` puts one on each line for reading, and `echo` ends the last line, which the file leaves open.

```
ana@vm:~/isbn-check$ java -cp target/isbn-check-1.0.0.jar:$(cat classpath.txt) com.example.isbn.IsbnCheck 978-0-306-40615-7 0-306-40615-2 978-0-306-40615-8
978-0-306-40615-7: valid, ISBN-13 9780306406157
0-306-40615-2: valid, ISBN-13 9780306406157
978-0-306-40615-8: invalid
```

Three arguments and three verdicts, and the ISBN-10 came back as the same ISBN-13 as the first.
Typing a classpath is not how a Java program ships, and it is not how this course ships one:
lesson 4 builds a Spring Boot application whose jar carries its dependencies inside it, and
lesson 23 opens that jar to see how.
