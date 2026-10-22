---
title: The JDK and Maven, as the course before left them
version: 1
---

This course is the third of a chain, and `java` lesson 1 installed its tools. If you came through
it, **you have them already and install nothing twice**: skip the two commands below, and read on
from the warnings. If you came straight here, the setup is two commands on the Ubuntu machine from
the last section.

```sh
sudo apt update
sudo apt install -y openjdk-25-jdk maven
```

`openjdk-25-jdk` is the **JDK**, the Java Development Kit: the `java` launcher that runs programs,
and `javac`, the compiler, which a runtime alone does not have. `maven` is Maven 3.8.7, Ubuntu's
packaging of it, which puts the `mvn` command on your path. `apt` prints a screen of progress for
a minute or two.

## Four lines of warning, and the line that silences them

`java` lesson 18 built a first Maven project and left four `WARNING:` lines at the top of every
build. Any Maven run that does real work prints them, even one that fails at once, and `-q`, which
otherwise hides everything but errors, does not hide them. Here Maven is asked to check a project
in your home directory, where there is none:

@@CAPTURE unsafe-1@@

The error at the end is expected; there is no `pom.xml` in `~`. The four lines above it are one
warning, and **it is not about your code**: it names `guava.jar` in `/usr/share/maven/lib`, a
library Maven itself is built with, calling a part of the JDK that Java 25 says will be removed.
You cannot change Maven 3.8.7's Guava, and the JDK prints the warning on every run, so every build
of yours would open with four lines about somebody else's code.

One JDK flag says that access is allowed, and `~/.mavenrc` is a file the `mvn` command reads its
options from before it starts Java. Append the line to it, and ask again:

@@CAPTURE unsafe-2@@

The error is still there, because there is still no project, and the warning is gone. The line
reaches Maven and nothing else: a program you run with `java` is not started through `mvn`, and it
never reads this file.
