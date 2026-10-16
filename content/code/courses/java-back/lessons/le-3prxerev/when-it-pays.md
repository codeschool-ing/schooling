---
title: When Bazel pays, and when it does not
version: 1
---

Picture the team this course has in mind: five developers, one Spring Boot service, one
repository. **For them Bazel costs more than it returns.** Their build already takes a minute,
nobody else's code lives in the repository, and every hour spent on the build is an hour not spent
on the service.

The cost is concrete, and the last two sections showed most of it:

- **Every dependency is named, jar by jar, with its hash.** One `<dependency>` in lesson 1's pom
  became five `http_jar` entries here, because Maven resolves the transitive tree and `http_jar`
  fetches exactly what it is told. The bookshop this course builds from lesson 4 resolves 39 jars
  in its first lesson and 125 by lesson 22. The rule set `rules_jvm_external` closes most of that
  gap, generating the targets from a list of Maven coordinates and a lock file, and it brings its
  own dependencies and its own learning curve.
- **The Java world assumes Maven or Gradle.** Spring Boot's own plugin builds the executable jar
  that lesson 23 ships; IntelliJ IDEA opens a `pom.xml` as it is and a Bazel project through a
  plugin; most answers you search for are written in `pom.xml` terms. JUnit 5 and later need a
  launcher of their own, as the test in the previous section did.
- **Somebody has to own the build.** BUILD files are code, written in Starlark, and the rules,
  the toolchains and a remote cache are infrastructure to upgrade and keep running.

The trade turns the other way when the repository grows past what one team holds in its head:

| | Maven (lesson 1) | Gradle (lesson 2) | Bazel |
|---|---|---|---|
| what it builds | a project, through phases | a project, through tasks | a graph of targets, through actions |
| dependencies | resolved from coordinates | resolved from coordinates | declared per target, pinned by hash |
| reuse between builds | classes whose sources did not change; the tests run every time | outputs of up-to-date tasks, and a build cache | every action and every test result, by its key |
| shared between machines | only with the build cache extension | with a remote build cache | remote cache, and remote execution |
| languages | Java, others by plugin | JVM first, others by plugin | any, through rule sets |

Bazel pays when several of these hold at once: **many teams in one repository**; several
languages that depend on each other; CI time spent mostly rebuilding and retesting code that no
commit touched; a requirement that the same commit build the same bytes on every machine. Google,
where it was born, has all four. A company of two hundred developers with one repository may well
have three.

The rest of this course builds with Maven. Lesson 2 says why it is Maven rather than Gradle, and
the reason has to do with reading the build rather than with the tool. Against Bazel the reasons
are the ones above: one service, one language, and an ecosystem that starts from a `pom.xml`. If
you join a company that uses Bazel, what this lesson leaves you with is the
vocabulary — `MODULE.bazel`, BUILD files, targets, labels, rule sets — and the reason behind each
of them.
