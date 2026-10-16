---
title: The JDK and Maven, as the course before left them
version: 1
---

This course is the third of a chain, and the `java` course installed its tools. If you came
through it, **you have them already and install nothing twice**: skip to the next section, which
checks what is there. If you came straight here, the setup is two commands on the Ubuntu machine
from the last section.

```sh
sudo apt update
sudo apt install -y openjdk-25-jdk maven
```

`openjdk-25-jdk` is the **JDK**, the Java Development Kit: the `java` launcher that runs programs,
and `javac`, the compiler, which a runtime alone does not have. `maven` is Maven 3.8.7, Ubuntu's
packaging of it, which puts the `mvn` command on your path. `apt` prints a screen of progress for
a minute or two.

## Four warnings, and the line that silences them

The first time Maven runs on Java 25 it says this before anything else:

@@CAPTURE unsafe-1@@

The warnings are not about your code, and there is no code yet. They name Guava, a library that
**Maven itself** is built with, calling a part of the JDK that Java 25 is retiring. Maven 3.8.7
cannot be changed, and the JDK prints them on every run, so a build of yours would start with
four lines about somebody else's code.

One flag tells the JDK that access is allowed, and `~/.mavenrc` is the file the `mvn` command
reads its options from before it starts. Append the line to it:

@@CAPTURE unsafe-2@@

It affects Maven and nothing else: a program you run with `java` is not started through `mvn`,
and it does not read this file.
