---
title: BUILD files, targets and labels
version: 1
---

Maven has one build per project, run phase by phase. Bazel has a **graph of targets**, and a BUILD
file is where targets are declared. A directory holding a `BUILD.bazel` is a **package**, and a
target is named by a **label**: `//`, the package's path from the top of the module, a colon and
the target's name. The library below is `//src/main/java/com/example/isbn:isbn`. Every command
takes labels, and `//...` means every target in the module.

Save this as `src/main/java/com/example/isbn/BUILD.bazel`, beside `IsbnCheck.java`:

```schooling-example
{"language": "python", "file": "BUILD.bazel", "parts": [{"code": "load(\"@rules_java//java:java_binary.bzl\", \"java_binary\")\nload(\"@rules_java//java:java_library.bzl\", \"java_library\")", "note": "A BUILD file starts by loading the rules it uses, each from the file in `rules_java` that defines it. Leave these out and nothing in the file works, as the end of this section shows."}, {"code": "\njava_library(\n    name = \"isbn\",\n    srcs = [\"IsbnCheck.java\"],\n    deps = [\"@commons_validator//jar\"],\n    runtime_deps = [\n        \"@commons_beanutils//jar\",\n        \"@commons_collections//jar\",\n        \"@commons_digester//jar\",\n        \"@commons_logging//jar\",\n    ],\n    visibility = [\"//src/test/java/com/example/isbn:__pkg__\"],\n)", "note": "A **target** called `isbn`: the class, compiled into a jar. `deps` is what the code compiles against and `runtime_deps` only goes on the classpath when something runs, which is Maven's compile and runtime scopes said per target. `visibility` lets the test's package depend on it and nobody else; in a repository of a thousand packages that line is how a team keeps others off its internals."}, {"code": "\njava_binary(\n    name = \"isbn-check\",\n    main_class = \"com.example.isbn.IsbnCheck\",\n    runtime_deps = [\":isbn\"],\n)", "note": "A second target, the program: the library plus the class with `main`, and a launcher script that puts every jar on the classpath. `:isbn` is a label relative to this package."}]}
```

And this as `src/test/java/com/example/isbn/BUILD.bazel`, beside the test:

```py
load("@rules_java//java:java_test.bzl", "java_test")

java_test(
    name = "IsbnCheckTest",
    size = "small",
    srcs = ["IsbnCheckTest.java"],
    deps = [
        "//src/main/java/com/example/isbn:isbn",
        "@junit_console//jar",
    ],
    use_testrunner = False,
    main_class = "org.junit.platform.console.ConsoleLauncher",
    args = [
        "execute",
        "--select-class=com.example.isbn.IsbnCheckTest",
        "--disable-banner",
        "--disable-ansi-colors",
        "--details=summary",
    ],
)
```

A `java_test` is a program whose exit code is the verdict. Bazel's own test runner speaks JUnit 4
only, so a Jupiter test needs something else as its `main`: `use_testrunner = False` turns Bazel's
runner off and `main_class` names JUnit's console launcher, told by `args` which class to run.
Teams that write many Jupiter tests use a rule set that packages this, `contrib_rules_jvm` and its
`java_junit5_test`. `size` declares how heavy the test is, and Bazel gives it a timeout to match.

## Build, run, test

```
TRANSCRIPT_BUILD
```

**`linux-sandbox`** is the hermetic rule at work: three actions ran in a sandbox holding only their
declared inputs. The two `worker` processes are the compiler, kept alive between builds like the
server. The outputs are not in a `target/` directory but under `bazel-bin`, one of four symbolic
links Bazel puts in the project into its cache:

```
TRANSCRIPT_LS
```

`MODULE.bazel.lock` is the **lockfile**: what the module's dependencies resolved to, down to each
file's hash. It belongs in version control beside `MODULE.bazel`, and the `bazel-*` links do not.

```
TRANSCRIPT_RUN
```

`bazel run` builds what is out of date first, so it works on a clean checkout too, and everything
after `--` goes to the program. Then the tests, with `--test_output=all` to see what the launcher
printed rather than only the verdict:

```
TRANSCRIPT_TEST
```

The second `bazel test` ran nothing. **`(cached) PASSED`** is a test result taken from the cache,
because none of the test's inputs changed since it last passed: not its source, not the library,
not a jar, not a flag. With a remote cache that holds across machines, so a CI job reruns only the
tests a commit could have broken. Maven runs every test on every `mvn test`.

## The graph, asked directly

Bazel will show you the graph it builds from. `cquery` lists what a target depends on, here
leaving out the toolchain's own implicit dependencies:

```
TRANSCRIPT_GRAPH
```

Every file is a target too: the test's source, the library's, and `downloaded.jar` in each
external repository. The short hash in brackets names the **configuration**, the set of options a
target was analysed with; a source file has none, hence `null`. The same kind of query in the
other direction, `rdeps`, lists everything that depends on a target: what a change to it can
reach.

## A missing load

Delete the two `load` lines from the library's BUILD file and build again:

```
TRANSCRIPT_NOLOAD
```

The message does not say *load*. Without the `load`, `java_library` does not mean the rule from
`rules_java`, and what the name does mean in Bazel 9 takes none of these attributes, so the first
error names `srcs`. When a BUILD file that worked in an older Bazel fails this way after an
upgrade, a missing `load` from `rules_java` is the first thing to look for. Put the two lines back
and the module builds again:

```
TRANSCRIPT_RESTORED
```
