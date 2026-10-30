---
title: The toolchain and the bytecode it targets
version: 1
---

`kotlin { jvmToolchain(21) }` has been in every build script since lesson 14. **It says which JDK
compiles and runs the project, and which Java version the bytecode is for.** Gradle looks for a JDK 21
on the machine and uses it, whatever JDK started Gradle; without one, the build stops with the message
lesson 14 provoked on purpose.

The version is written into every `.class` file the compiler produces, as a number the JVM checks before
it loads one. `javap`, the JDK's class file reader, shows it:

```
ana@vm:~/kt/planner$ javap -v build/classes/kotlin/main/HelloKt.class | grep major
  major version: 65
```

**Class file version 65 is Java 21.** Each Java release adds one: 61 is Java 17, 55 is Java 11. A JVM
refuses a class file newer than itself, with `UnsupportedClassVersionError`, so the toolchain number is
also the oldest Java a user can run the program on.

| the build says | the machine needs | the program runs on |
|---|---|---|
| `jvmToolchain(21)` | a JDK 21 to build | Java 21 or newer |
| `jvmToolchain(17)` | a JDK 17 to build | Java 17 or newer |

**Pick the version the program will meet, not the newest one available.** `android-apps` will set this
number from what Android supports rather than from what the laptop has, and that is the question to ask
of any target: where does this bytecode run?
