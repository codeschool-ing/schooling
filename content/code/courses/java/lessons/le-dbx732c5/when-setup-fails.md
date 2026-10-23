---
title: When the setup fails
version: 1
---

A setup that fails seldom says "your setup failed". It says something about a package, a command
or a class file version, and the temptation is to remove everything and start again. **Each
failure below has one cause, and the message names it** if you read it to the end. All four were
produced on purpose, on a fresh copy of the same Ubuntu 24.04.

## `Unable to locate package openjdk-25-jdk`

`apt` installs from a list of packages it keeps on disk, and that list is only as recent as the
last `apt update`. A machine that has never run one, which describes many a fresh virtual machine,
knows of no packages at all:

```
ana@vm:~$ sudo apt install -y openjdk-25-jdk 2>&1 | tail -3; echo $?
Reading package lists...
Building dependency tree...
E: Unable to locate package openjdk-25-jdk
0
ana@vm:~$ sudo apt update 2>&1 | tail -1
151 packages can be upgraded. Run 'apt list --upgradable' to see them.
ana@vm:~$ apt-cache policy openjdk-25-jdk | head -3
openjdk-25-jdk:
  Installed: (none)
  Candidate: 25.0.4.1+1-1~24.04.4
```

**Run `sudo apt update` and try again.** After it, `apt-cache policy` names a candidate version, and
the install works. If the candidate is still `(none)`, the package is not in any archive the machine
reads. Ubuntu 24.04 carries `openjdk-25-jdk` in `noble-updates`, in the `universe` component, and a
system that was set up without one of those two will not see it.

The `0` is worth a second look. `echo $?` printed the exit status of the **last** command in the
pipe, which is `tail`, and `tail` succeeded. `apt` failed and the pipe hid it. The words on the
screen were right, and only the number lied: a script that checked the status after that line would
have carried on.

## `javac: command not found`, with `java` working

The JDK is the runtime plus the tools for building. Install only the runtime and you can run Java
programs but not compile one:

```
ana@vm:~$ sudo apt install -y openjdk-25-jre-headless >/dev/null 2>&1; java -version
openjdk version "25.0.4.1" 2026-08-18
OpenJDK Runtime Environment (build 25.0.4.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 25.0.4.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
ana@vm:~$ javac -version; echo $?
bash: line 1: javac: command not found
127
```

**Exit status 127 is the shell's own number for "no such command"**, so the message comes from
`bash` and not from Java. The package names carry the difference: a `-jre` package is a runtime
and a `-jdk` package is the development kit. `-headless` means without the libraries for windows
and graphics, which a server does not need. The fix is the line from section 02, which installs
`openjdk-25-jdk` and pulls every other piece in with it.

## `UnsupportedClassVersionError`

This one needs the machine from section 03, with its two Javas, and the `Hello.class` that section
05 compiles. Run it with the Java 21 that came with Maven, instead of the 25 that compiled it:

```
ana@vm:~/jvm$ /usr/lib/jvm/java-21-openjdk-amd64/bin/java Hello; echo $?
Error: LinkageError occurred while loading main class Hello
	java.lang.UnsupportedClassVersionError: Hello has been compiled by a more recent version of the Java Runtime (class file version 69.0), this version of the Java Runtime only recognizes class file versions up to 65.0
1
```

**Every class file records the version of Java it was compiled for**, as a number section 05
reads out of the file: 69 is Java 25 and 65 is Java 21. A JVM runs every version up to its own and
refuses anything newer, because a newer class file may use instructions it has never heard of. In
practice the message means one of two things. Either the wrong `java` ran, or the code was compiled
for a newer release than the machine it has to run on. Section 06 shows the second fix, `--release`.

## Maven on the wrong Java

Maven runs on whatever Java it finds, and it looks at the `JAVA_HOME` variable before anything
else. Many setup guides on the web tell you to set it, and the obvious value on Ubuntu is
`/usr/lib/jvm/default-java`, the link section 03 found. Set it to that and see which Java Maven picks:

```
ana@vm:~/jvm$ JAVA_HOME=/usr/lib/jvm/default-java mvn -v | grep "Java version"
Java version: 21.0.12.1, vendor: Ubuntu, runtime: /usr/lib/jvm/java-21-openjdk-amd64
ana@vm:~/jvm$ mvn -v | grep "Java version"
Java version: 25.0.4.1, vendor: Ubuntu, runtime: /usr/lib/jvm/java-25-openjdk-amd64
```

**With `default-java`, Maven runs on 21, and nothing says so unless you ask.** It works until the
first project asks for Java 25, and then the compiler refuses with a message lesson 18 reproduces.
The course leaves `JAVA_HOME` unset, and the second command shows what that buys you: Maven follows
`/usr/bin/java` to 25. If a guide or an old `~/.profile` sets it, `echo $JAVA_HOME` shows the value
and `unset JAVA_HOME` removes it from the current shell.

**Whatever went wrong, the first three commands are the same**: `java -version`, `javac -version`
and `mvn -v`. When all three say 25, the lab is right.
