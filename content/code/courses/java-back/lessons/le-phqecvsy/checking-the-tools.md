---
title: Checking what is installed
version: 1
---

Three commands say whether the machine is ready, and each prints more than a version number.
Read all of it once, because the lines that look like noise are the ones that explain a failure
later.

@@CAPTURE versions@@

`java -version` names the **runtime**: OpenJDK, the release @@JV@@, and the build Ubuntu packaged
(`24.04` in the build string is the Ubuntu release it was built for). `javac -version` names the
**compiler**, and it matters separately: a machine with only a Java runtime installed answers the
first command and not the second, and Maven needs both.

@@CAPTURE mvn-v@@

`mvn -v` is the one to read line by line, because it says **which Java Maven will actually use**,
and that is not always the one `java -version` reported:

- `Maven home` is where Maven itself is installed, `/usr/share/maven` for Ubuntu's package.
- `Java version` and `runtime` are the JDK that will compile your code. Maven finds it through the
  `JAVA_HOME` variable if it is set, and through the `java` on your path if it is not.
- `platform encoding: UTF-8` is the default the JDK would read source files with. The project in
  this lesson names its encoding in the pom, so a machine set to another one builds the same way.
- `OS name` and `arch` are the machine. Yours will say a different kernel version.

When all three answer with 25 and the runtime path ends in `java-25-openjdk-amd64` (or `arm64`),
the machine is ready.
