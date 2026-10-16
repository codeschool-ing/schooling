---
title: Bazel, pinned, and a module of your own
version: 1
---

This section and the next build lesson 1's ISBN checker a third time, now with Bazel. The two
Java files do not change; what changes is everything around them. Nothing from here on is used
again in the course, so if you only want the ideas you can read along without typing.

## Bazelisk, the launcher

Nobody installs Bazel itself. You install **Bazelisk**, a small launcher that reads the Bazel
version a project asks for in a file called `.bazelversion`, downloads that version once into
`~/.cache/bazelisk`, and runs it. It is the same idea as lesson 2's Gradle wrapper: the version is
part of the repository, so everybody who clones it builds with the same Bazel. Bazelisk is one
executable from its GitHub releases, and the convention is to call it `bazel`:

```
TRANSCRIPT_INSTALL
```

Ubuntu's `~/.profile` puts `~/bin` on your `PATH` when the directory exists, so log out and in
again, or run `source ~/.profile`, and `bazel` is a command.

## The project

Copy the sources from lesson 1 into a directory of their own, as lesson 2 did for Gradle, and
name the Bazel version the project builds with:

```
TRANSCRIPT_PROJECT
```

Three files go at the top of `~/isbn-bazel`, and two more beside the sources in the next section.
The first is the one-line `.bazelversion` the last command wrote, which pins Bazel the way a
wrapper pins Gradle. The second is **`MODULE.bazel`**, and its presence is what makes the
directory a Bazel project. Its system is called **Bzlmod**: the module names the rule sets it
depends on, and Bazel fetches them from the **Bazel Central Registry**, which plays the
part Maven Central plays for jars. Older projects declare the same things in a file called
`WORKSPACE`, which you will still meet in repositories that have not moved.

```schooling-example
{"language": "python", "file": "MODULE.bazel", "parts": [{"code": "module(name = \"isbn_check\", version = \"1.0.0\")\n\nbazel_dep(name = \"rules_java\", version = \"9.9.0\")", "note": "The module's own name and version, which matter when another module depends on this one, and the one rule set it uses. `rules_java` defines `java_library`, `java_binary` and `java_test`; Bazel itself defines no Java rules at all. The version is exact: there are no ranges, and if two modules ask for different versions of one dependency, Bzlmod takes the highest of them."}, {"code": "\nhttp_jar = use_repo_rule(\"@bazel_tools//tools/build_defs/repo:http.bzl\", \"http_jar\")", "note": "`http_jar` is a **repository rule**: it downloads one file and turns it into an external repository the BUILD files can name, `@commons_validator` for the first one below."}, {"code": "\nhttp_jar(\n    name = \"commons_validator\",\n    sha256 = \"b7e1dcdc60d581de82934f4600e25af9ad9366730af1704ddcbf459e4dcc85e5\",\n    urls = [\"https://repo1.maven.org/maven2/commons-validator/commons-validator/1.11.0/commons-validator-1.11.0.jar\"],\n)", "note": "The one library the code imports. The `sha256` is the hermetic rule applied to a download: Bazel refuses a file whose hash differs, so a jar replaced on the server, or a mirror that serves something else, fails the build instead of entering it."}, {"code": "\nhttp_jar(\n    name = \"commons_beanutils\",\n    sha256 = \"9e44ba68ec9a3f21286fa2a8bbb003b735c0f69101bb43144b79f4f8aaa74709\",\n    urls = [\"https://repo1.maven.org/maven2/commons-beanutils/commons-beanutils/1.11.0/commons-beanutils-1.11.0.jar\"],\n)\n\nhttp_jar(\n    name = \"commons_digester\",\n    sha256 = \"e0b2b980a84fc6533c5ce291f1917b32c507f62bcad64198fff44368c2196a3d\",\n    urls = [\"https://repo1.maven.org/maven2/commons-digester/commons-digester/2.1/commons-digester-2.1.jar\"],\n)\n\nhttp_jar(\n    name = \"commons_logging\",\n    sha256 = \"d175dbd751dd782a63bde28c7a039520e971f25e84b79c19b8435edc3603e0dc\",\n    urls = [\"https://repo1.maven.org/maven2/commons-logging/commons-logging/1.4.0/commons-logging-1.4.0.jar\"],\n)\n\nhttp_jar(\n    name = \"commons_collections\",\n    sha256 = \"eeeae917917144a68a741d4c0dff66aa5c5c5fd85593ff217bced3fc8ca783b8\",\n    urls = [\"https://repo1.maven.org/maven2/commons-collections/commons-collections/3.2.2/commons-collections-3.2.2.jar\"],\n)", "note": "The four jars commons-validator itself depends on, at the versions lesson 1's `mvn dependency:tree` resolved. Maven found them on its own from one `<dependency>`; `http_jar` fetches only what it is told, so they are written out here."}, {"code": "\nhttp_jar(\n    name = \"junit_console\",\n    sha256 = \"3ba0d6150af79214a1411f9ea2fbef864eef68b68c89a17f672c0b89bff9d3a2\",\n    urls = [\"https://repo1.maven.org/maven2/org/junit/platform/junit-platform-console-standalone/6.0.3/junit-platform-console-standalone-6.0.3.jar\"],\n)", "note": "JUnit for the test: one jar holding the Jupiter API, its engine and a **console launcher** that runs tests from a `main` method. The next section says why the test needs a launcher."}]}
```

The third, `.bazelrc`, holds flags Bazel reads on every command, so nobody has to type them:

```conf
# Compile for Java 25, as lesson 1's pom does with maven.compiler.release.
common --java_language_version=25
# Print results, not a progress line that redraws itself: what you see is what this lesson shows.
common --noshow_progress
```

With the three files in place, ask Bazel what it is:

```
TRANSCRIPT_VERSION
```

The first command in a new directory starts a **Bazel server**, a process that stays in the
background and keeps the build graph in memory between commands, much as Gradle's daemon does.
The first command after a new `.bazelversion` also downloads that Bazel, and the first build
downloads `rules_java`, the six jars and **two JDKs of Bazel's own**: one that runs its tools and
one that compiles your code. That is the hermetic rule from the first section, applied to the
compiler itself. Your program still runs on the JDK 25 the `java` course installed.
