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

@@CAPTURE notfound@@

The shell searched every directory on its path and found no program by that name. Either the
`apt install` of the last section did not run, it ran on another machine than the one you are
typing in, or it failed halfway: scroll up to its last lines, and run it again. `javac: command
not found` on a machine where `java` works is the same failure with a narrower cause: a Java
**runtime** package was installed instead of `openjdk-25-jdk`, and a runtime has no compiler.

## A JDK older than 25

A machine that has been used for Java before may have another JDK on it, and Maven may find that
one instead. Two places decide it, and `mvn -v` reports the result: the `JAVA_HOME` variable, if
it is set, and otherwise the `java` your path leads to. A `JAVA_HOME` left over in `~/.bashrc` by
an older tutorial is the commonest case, and with the `~/.mavenrc` line from the chain section in
place it fails before Maven even starts:

@@CAPTURE oldjdk@@

@@OLDJDK-PROSE@@

## Four `WARNING:` lines before every build

They are the `sun.misc.Unsafe` warnings from the chain section, and they mean the line in
`~/.mavenrc` is missing, misspelt, or in a file of another name. `cat ~/.mavenrc` should print the
line exactly as it was typed there. They never stop a build, and nothing else here depends on them.

## Below all of these: the virtual machine itself

If the hypervisor refuses to start the machine with a message about `VT-x`, `AMD-V` or
virtualisation being disabled, **the processor can do it and the computer's firmware has the
feature switched off.** It is a setting in the BIOS or UEFI menu, reached by a key pressed while
the computer starts, and the manufacturer's site says which key. If you cannot change it, the
installed path or the online one in the first section needs no virtualisation at all.
