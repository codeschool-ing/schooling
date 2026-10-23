---
title: When the setup does not work
version: 1
---

Every way this setup goes wrong prints a sentence that says which. Read the first line of the
error before anything else, and match it against the headings here.

## `command not found`

This is what a fresh Ubuntu 24.04 says when neither package is installed. The transcript ran it in
a throwaway container, a clean machine made in one line, which lesson 19 explains; you do not need
to type it:

```
ana@vm:~$ docker run --rm ubuntu:24.04 bash -c 'java -version; mvn -v'
bash: line 1: java: command not found
bash: line 1: mvn: command not found
```

The shell searched every directory on its path and found no program by that name. Either the
`apt install` of the last section did not run, it ran on another machine than the one you are
typing in, or it failed halfway: scroll up to its last lines, and run it again.
`javac: command not found` on a machine where `java` works is the same failure with a narrower
cause: a Java
**runtime** package was installed instead of `openjdk-25-jdk`, and a runtime has no compiler.

## A JDK older than 25

A machine that has been used for Java before may have another JDK on it, and Maven may find that
one instead. Two places decide it, and `mvn -v` reports the result: the `JAVA_HOME` variable, if
it is set, and otherwise the `java` your path leads to. A `JAVA_HOME` left over in `~/.bashrc` by
an older tutorial is the commonest case. With the `~/.mavenrc` line from the section on the JDK and
Maven in place, it fails before Maven even starts:

```
ana@vm:~$ echo $JAVA_HOME
/usr/lib/jvm/java-21-openjdk-amd64
ana@vm:~$ mvn -v
Unrecognized option: --sun-misc-unsafe-memory-access=allow
Error: Could not create the Java Virtual Machine.
Error: A fatal exception has occurred. Program will exit.
```

`JAVA_HOME` names JDK 21, so `mvn` started Java 21 with the flag from `~/.mavenrc`, and JDK 21
does not know that flag: **the JVM refused to start**, before Maven could print anything of its own.
The same JDK without the `~/.mavenrc` line gets further, into a project, and fails at the compiler,
which cannot produce the Java 25 classes the pom asks for:

```
ana@vm:~/isbn-check$ mvn -q clean compile
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin:3.15.0:compile (default-compile) on project isbn-check: Fatal error compiling: error: release version 25 not supported -> [Help 1]
[ERROR] 
[ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[ERROR] Re-run Maven using the -X switch to enable full debug logging.
[ERROR] 
[ERROR] For more information about the errors and possible solutions, please read the following articles:
[ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoExecutionException
```

Two different sentences, one cause. The fix is to stop pointing at the old JDK. If the variable is
set in `~/.bashrc`, delete that line and open a new terminal; for the terminal you are in, `unset`
removes it, and Maven falls back to the `java` on your path. `-q` prints nothing when the build
works, so `echo` says so:

```
ana@vm:~/isbn-check$ unset JAVA_HOME; mvn -q compile && echo compiled
compiled
```

If something you use really needs `JAVA_HOME`, set it to `/usr/lib/jvm/java-25-openjdk-amd64`
instead of removing it.

The other place is the `java` on your path. When `JAVA_HOME` is not set and `java -version` still
says 21, Ubuntu's alternatives point the `java` command at the older JDK. This lists the JDKs it
knows, with the one ending in `25` as the second line here:

```
ana@vm:~$ update-java-alternatives -l
java-1.21.0-openjdk-amd64      2111       /usr/lib/jvm/java-1.21.0-openjdk-amd64
java-1.25.0-openjdk-amd64      2511       /usr/lib/jvm/java-1.25.0-openjdk-amd64
```

and this makes JDK 25 the one every `java`, `javac` and `mvn` on the machine uses. It asks for your
password and changes the default for every user of the machine, which is why the transcripts of
this course show it without running it:

```sh
sudo update-java-alternatives -s java-1.25.0-openjdk-amd64
```

Then `mvn -v` should name the 25 runtime, as in the last section.

## Four `WARNING:` lines before every build

They are the `sun.misc.Unsafe` warning from the section on the JDK and Maven, and they mean the
line in `~/.mavenrc` is missing, misspelt, or in a file of another name. `cat ~/.mavenrc` should
print the line exactly as it was typed there. The warning never stops a build, and nothing else
here depends on it.

## Below all of these: the virtual machine itself

If the hypervisor refuses to start the machine with a message about `VT-x`, `AMD-V` or
virtualisation being disabled, **the processor can do it and the computer's firmware has the
feature switched off.** It is a setting in the BIOS or UEFI menu, reached by a key pressed while
the computer starts, and the manufacturer's site says which key. If you cannot change it, the
installed path or the online one in the first section needs no virtualisation at all.
