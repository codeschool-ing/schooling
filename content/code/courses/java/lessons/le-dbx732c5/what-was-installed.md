---
title: What was installed, and the Java you did not ask for
version: 1
---

`apt` put the JDK in one directory and told the shell where to find it. Both halves are worth
knowing before anything goes wrong, because **most broken Java setups are a machine with two JDKs
and a shell that picked the other one**. Ana's machine has two already, and she installed one.

## Every JDK lives under `/usr/lib/jvm`

```
ana@vm:~$ ls -l /usr/lib/jvm
total 12
lrwxrwxrwx 1 root root   25 Oct  4  2023 default-java -> java-1.21.0-openjdk-amd64
lrwxrwxrwx 1 root root   21 Sep  4 03:14 java-1.21.0-openjdk-amd64 -> java-21-openjdk-amd64
lrwxrwxrwx 1 root root   21 Sep  4 03:24 java-1.25.0-openjdk-amd64 -> java-25-openjdk-amd64
drwxr-xr-x 7 root root 4096 Oct 16 19:30 java-21-openjdk-amd64
drwxr-xr-x 9 root root 4096 Oct 16 19:30 java-25-openjdk-amd64
drwxr-xr-x 2 root root 4096 Oct 16 19:30 openjdk-25
```

Two real directories, `java-25-openjdk-amd64` and `java-21-openjdk-amd64`, and links pointing at
them. The 25 is the one Ana asked for. **The 21 came with Maven.** Ubuntu's `maven` package needs
*some* Java runtime to run on, and it asks for the archive's default one:

```
ana@vm:~$ apt-cache depends default-jre-headless | head -2
default-jre-headless
  Depends: openjdk-21-jre-headless
```

In Ubuntu 24.04 the default is 21, chosen when the release was made in 2024, before 25 existed. So
Maven pulled in a Java 21 **runtime**, without a compiler, and the link `default-java` points at it.
Nothing is wrong yet. It is simply the machine you have, and section 04 shows the one way it bites.

## Which `java` runs

When you type `java`, the shell runs `/usr/bin/java`, and on Ubuntu that file is a link managed by
a small program called `update-alternatives`. Each installed JDK registers itself with a priority,
and in automatic mode the highest one wins:

```
ana@vm:~$ update-alternatives --display java | head -3
java - auto mode
  link best version is /usr/lib/jvm/java-25-openjdk-amd64/bin/java
  link currently points to /usr/lib/jvm/java-25-openjdk-amd64/bin/java
```

**Auto mode, pointing at 25.** Further down the same output, not shown here, the two priorities are
2511 and 2111, and 25 wins because its number is larger. `sudo update-alternatives --config java`
lets you choose by hand, and the course never needs it.

## Thirty programs

The JDK's own directory holds the programs, and `/usr/bin` links to them:

```
ana@vm:~$ ls -C -T 0 /usr/lib/jvm/java-25-openjdk-amd64/bin
jar        javadoc   jdb        jhsdb   jmap         jps         jstat       rmiregistry
jarsigner  javap     jdeprscan  jimage  jmod         jrunscript  jstatd      serialver
java       jcmd      jdeps      jinfo   jnativescan  jshell      jwebserver
javac      jconsole  jfr        jlink   jpackage     jstack      keytool
ana@vm:~$ du -sh /usr/lib/jvm/java-25-openjdk-amd64 /usr/lib/jvm/java-21-openjdk-amd64
331M	/usr/lib/jvm/java-25-openjdk-amd64
194M	/usr/lib/jvm/java-21-openjdk-amd64
```

Thirty programs in 331 MB. **This course uses about a third of them**, and each one arrives in the
lesson that needs it:

| program | what it does | first used |
|---|---|---|
| `javac` | compiles `.java` source into `.class` files | section 05 of this lesson |
| `java` | starts a JVM and runs a program in it | section 05 of this lesson |
| `javap` | prints what is inside a `.class` file | section 05 of this lesson |
| `jshell` | runs Java one line at a time, for trying things | lesson 3 |
| `jps`, `jcmd` | list running JVMs and ask one questions | lesson 2 |
| `javadoc` | turns documentation comments into web pages | lesson 3 |
| `jar` | packs classes into one archive file | lesson 18 |
| `jdeps`, `jlink` | find what a program needs, and build a runtime with only that | lesson 40 |

The Java 21 directory is smaller because it is a runtime only: it has `java` and a handful of
others, and no `javac`. That difference is section 04's second failure.

`jshell` answers its own version too, and the first time it ever runs it says something else first:

```
ana@vm:~$ jshell --version
Oct 16, 2026 7:30:57 PM java.util.prefs.FileSystemPreferences setupUserRoot
INFO: Created user preferences directory.
jshell 25.0.4.1
ana@vm:~$ jshell --version
jshell 25.0.4.1
```

The two `INFO` lines are not an error. Java keeps a small store of user preferences under your home
directory, and the first program that needs it creates it and reports doing so. The second run
finds it there and stays quiet. **A line that says `INFO` or `WARNING` is the JVM telling you
something; only an exit status that is not 0 says the program failed**, and lesson 2 is about that
number.
