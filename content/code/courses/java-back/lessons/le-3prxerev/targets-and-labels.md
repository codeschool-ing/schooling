---
title: BUILD files, targets and labels
version: 1
---

Maven has one build per project, run phase by phase. Bazel has a **graph of targets**, and a BUILD
file is where targets are declared. A directory holding a `BUILD.bazel` is a **package**, and a
target is named by a **label**: `//`, the package's path from the top of the module, a colon and
the target's name. The library below is `//src/main/java/com/example/isbn:isbn`. Build, run, test
and query commands take labels, and `//...` means every target in the module.

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
ana@vm:~/isbn-bazel$ bazel build //src/main/java/com/example/isbn:isbn-check
INFO: Analyzed target //src/main/java/com/example/isbn:isbn-check (0 packages loaded, 0 targets configured).
INFO: Found 1 target...
Target //src/main/java/com/example/isbn:isbn-check up-to-date:
  bazel-bin/src/main/java/com/example/isbn/isbn-check
  bazel-bin/src/main/java/com/example/isbn/isbn-check.jar
INFO: Elapsed time: 11.452s, Critical Path: 5.68s
INFO: 11 processes: 6 internal, 3 linux-sandbox, 2 worker.
INFO: Build completed successfully, 11 total actions
```

**`linux-sandbox`** is the hermetic rule at work: three actions ran in a sandbox holding only their
declared inputs. The two `worker` processes are the compiler, kept alive between builds like the
server. The outputs are not in a `target/` directory but under `bazel-bin`, one of four symbolic
links Bazel puts in the project into its cache:

```
ana@vm:~/isbn-bazel$ ls -A
.bazelrc
.bazelversion
MODULE.bazel
MODULE.bazel.lock
bazel-bin
bazel-isbn-bazel
bazel-out
bazel-testlogs
src
```

`MODULE.bazel.lock` is the **lockfile**: what the module's dependencies resolved to, down to each
file's hash. It belongs in version control beside `MODULE.bazel`, and the `bazel-*` links do not.

```
ana@vm:~/isbn-bazel$ bazel run //src/main/java/com/example/isbn:isbn-check -- 978-0-306-40615-7 0-306-40615-2 978-0-306-40615-8
INFO: Analyzed target //src/main/java/com/example/isbn:isbn-check (0 packages loaded, 0 targets configured).
INFO: Found 1 target...
Target //src/main/java/com/example/isbn:isbn-check up-to-date:
  bazel-bin/src/main/java/com/example/isbn/isbn-check
  bazel-bin/src/main/java/com/example/isbn/isbn-check.jar
INFO: Elapsed time: 0.549s, Critical Path: 0.02s
INFO: 1 process: 1 internal.
INFO: Build completed successfully, 1 total action
INFO: Running command line: bazel-bin/src/main/java/com/example/isbn/isbn-check <args omitted>
978-0-306-40615-7: valid, ISBN-13 9780306406157
0-306-40615-2: valid, ISBN-13 9780306406157
978-0-306-40615-8: invalid
```

`bazel run` builds what is out of date first, so it works on a clean checkout too, and everything
after `--` goes to the program. Then the tests, with `--test_output=all` to see what the launcher
printed rather than only the verdict:

```
ana@vm:~/isbn-bazel$ bazel test //... --test_output=all
INFO: Analyzed 3 targets (3 packages loaded, 25 targets configured).
INFO: From Testing //src/test/java/com/example/isbn:IsbnCheckTest:
==================== Test output for //src/test/java/com/example/isbn:IsbnCheckTest:

Test run finished after 117 ms
[         4 containers found      ]
[         0 containers skipped    ]
[         4 containers started    ]
[         0 containers aborted    ]
[         4 containers successful ]
[         0 containers failed     ]
[         3 tests found           ]
[         0 tests skipped         ]
[         3 tests started         ]
[         0 tests aborted         ]
[         3 tests successful      ]
[         0 tests failed          ]

================================================================================
INFO: Found 2 targets and 1 test target...
INFO: Elapsed time: 2.121s, Critical Path: 1.53s
INFO: 10 processes: 6 internal, 4 linux-sandbox, 1 worker.
INFO: Build completed successfully, 10 total actions
//src/test/java/com/example/isbn:IsbnCheckTest                           PASSED in 1.0s

Executed 1 out of 1 test: 1 test passes.
ana@vm:~/isbn-bazel$ bazel test //...
INFO: Analyzed 3 targets (0 packages loaded, 0 targets configured).
INFO: Found 2 targets and 1 test target...
INFO: Elapsed time: 0.536s, Critical Path: 0.01s
INFO: 1 process: 1 action cache hit, 1 internal.
INFO: Build completed successfully, 1 total action
//src/test/java/com/example/isbn:IsbnCheckTest                  (cached) PASSED in 1.0s

Executed 0 out of 1 test: 1 test passes.
```

In the launcher's table the three tests are `IsbnCheckTest`'s three methods, and the four
containers are the class and the three test engines the console jar carries.

The second `bazel test` ran nothing. **`(cached) PASSED`** is a test result taken from the cache,
because none of the test's inputs changed since it last passed: not its source, not the library,
not a jar, not a flag. A remote cache makes that hold across machines, so a CI job reruns only the
tests a commit could have broken. Maven runs every test on every `mvn test`.

## The graph, asked directly

Bazel will show you the graph it builds from. `cquery` lists what a target depends on, here
leaving out the toolchain's own implicit dependencies:

```
ana@vm:~/isbn-bazel$ bazel cquery --noimplicit_deps 'deps(//src/test/java/com/example/isbn:IsbnCheckTest)'
INFO: Analyzed target //src/test/java/com/example/isbn:IsbnCheckTest (0 packages loaded, 0 targets configured).
INFO: Found 1 target...
//src/test/java/com/example/isbn:IsbnCheckTest (be37ecb)
@junit_console//jar:jar (6258d0d)
//src/test/java/com/example/isbn:IsbnCheckTest.java (null)
//src/main/java/com/example/isbn:isbn (6258d0d)
@bazel_tools//tools/jdk:launcher_flag_alias (6258d0d)
@commons_logging//jar:jar (6258d0d)
@commons_collections//jar:jar (6258d0d)
@junit_console//jar:downloaded.jar (null)
@commons_beanutils//jar:jar (6258d0d)
//src/main/java/com/example/isbn:IsbnCheck.java (null)
@commons_digester//jar:jar (6258d0d)
@commons_validator//jar:jar (6258d0d)
@commons_logging//jar:downloaded.jar (null)
@commons_collections//jar:downloaded.jar (null)
@commons_digester//jar:downloaded.jar (null)
@commons_validator//jar:downloaded.jar (null)
@commons_beanutils//jar:downloaded.jar (null)
INFO: Elapsed time: 0.320s, Critical Path: 0.00s
INFO: 0 processes.
INFO: Build completed successfully, 0 total actions
```

Every file is a target too: the test's source, the library's, and `downloaded.jar` in each
external repository. The short hash in brackets names the **configuration**, the set of options a
target was analysed with; a source file has none, hence `null`. The same kind of query in the
other direction, `rdeps`, lists everything that depends on a target: what a change to it can
reach.

## A missing load

Delete the two `load` lines from the library's BUILD file and build again:

```
ana@vm:~/isbn-bazel$ bazel build //...
ERROR: /home/ana/isbn-bazel/src/main/java/com/example/isbn/BUILD.bazel:2:13: //src/main/java/com/example/isbn:isbn: no such attribute 'srcs' in 'java_library' rule
ERROR: /home/ana/isbn-bazel/src/main/java/com/example/isbn/BUILD.bazel:2:13: //src/main/java/com/example/isbn:isbn: no such attribute 'deps' in 'java_library' rule
ERROR: /home/ana/isbn-bazel/src/main/java/com/example/isbn/BUILD.bazel:2:13: //src/main/java/com/example/isbn:isbn: no such attribute 'runtime_deps' in 'java_library' rule
ERROR: /home/ana/isbn-bazel/src/main/java/com/example/isbn/BUILD.bazel:15:12: //src/main/java/com/example/isbn:isbn-check: no such attribute 'main_class' in 'java_binary' rule
ERROR: /home/ana/isbn-bazel/src/main/java/com/example/isbn/BUILD.bazel:15:12: //src/main/java/com/example/isbn:isbn-check: no such attribute 'runtime_deps' in 'java_binary' rule
ERROR: package contains errors: src/main/java/com/example/isbn
ERROR: package contains errors: src/main/java/com/example/isbn: //src/main/java/com/example/isbn:isbn: no such attribute 'srcs' in 'java_library' rule
WARNING: Target pattern parsing failed.
ERROR: Skipping '//...': Error evaluating '//...': error loading package 'src/main/java/com/example/isbn': Package 'src/main/java/com/example/isbn' contains errors
ERROR: Error evaluating '//...': error loading package 'src/main/java/com/example/isbn': Package 'src/main/java/com/example/isbn' contains errors
INFO: Elapsed time: 0.213s
INFO: 0 processes.
ERROR: Build did NOT complete successfully
```

The message does not say *load*. Without the `load`, `java_library` does not mean the rule from
`rules_java`, and what the name does mean in Bazel 9 takes none of these attributes, so the first
error names `srcs`. When a BUILD file that worked in an older Bazel fails this way after an
upgrade, a missing `load` from `rules_java` is the first thing to look for. Put the two lines back
and the module builds again:

```
ana@vm:~/isbn-bazel$ bazel build //... && echo restored
INFO: Analyzed 3 targets (1 packages loaded, 4 targets configured).
INFO: Found 3 targets...
INFO: Elapsed time: 0.582s, Critical Path: 0.00s
INFO: 1 process: 14 action cache hit, 1 internal.
INFO: Build completed successfully, 1 total action
restored
```
