---
title: When modules pay, and why most code has none
version: 1
---

Modules arrived in Java 9, in 2017, after the better part of a decade of design. **Most Java
applications written since have no `module-info.java`**, and that includes nearly every service built
with the frameworks `java-back` uses. It is worth knowing why, because the reasons are about costs, not
about the module system being wrong.

## What a module costs

- **Every dependency has to be a module too**, or pass for one. A library jar with no
  `module-info.class` can be put on the module path as an *automatic module*, named after its jar, but
  an application is only as modular as the least modular jar it pulls in, and a real service pulls in
  dozens.
- **Frameworks reflect.** They read your classes' private fields and annotations, as lesson 39's
  validator did, so every package they touch has to be `opens`, and the declaration fills up with
  exceptions to the rule it exists to enforce.
- **Two paths to keep straight.** The class path and the module path behave differently, as section 03
  showed with the same two directories, and a build that mixes them is a source of errors a class-path
  build never has.

## What a module buys

- **A library's internals stay internal.** Section 02's `Index` cannot become somebody else's
  dependency by accident. For a library with many users this is the main reason to write the file: the
  JDK itself is the largest example.
- **Missing pieces fail at start-up.** A module that `requires` another which is not there refuses to
  start, rather than failing with a `NoClassDefFoundError` an hour into a run, the first time a rarely
  used class is touched.
- **`jlink`.** A runtime of 60 MB instead of 331, from section 04, when the program and its
  dependencies are modules.

## So, in practice

**Write an application on the class path**, as every other lesson of this course has, and as lesson
18's Maven project does. Reach for `module-info.java` when you publish a library that others depend on
and you want its internals protected, or when a small self-contained runtime is worth the effort of
making every piece modular.

Whichever you write, you live inside the JDK's modules already. The `InaccessibleObjectException` of
section 03 is the module system speaking to a program that never declared a module, and reading that
message correctly is the part of this lesson every Java developer needs, whatever they build.
