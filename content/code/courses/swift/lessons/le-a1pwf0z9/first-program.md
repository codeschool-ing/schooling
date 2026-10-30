---
title: The first program, run two ways
version: 1
---

A Swift program is a text file ending in `.swift`. Make a directory for this lesson, `~/sw/l01`,
open a file called `Hello.swift` in any text editor, and type these four lines:

```swift
// Hello.swift
let course = "Swift"
let minutes = 45
print("Studied \(course) for \(minutes) minutes")
```

The first line is a comment, and the compiler ignores it. Every program in this course starts with
one naming its file, so you always know what to call the file you are typing. The next two lines
give two names to two values, and section 05 is about the word `let`. The last line prints a
sentence, and `\(…)` inside the quotes is **string interpolation**: Swift evaluates what is in the
brackets and puts the result into the text.

There is no `main` function, no class and no import. A file of statements is a whole program, and
the statements run from the top. That is a property of a file run on its own; lesson 19's packages
put the same rule on one file, `main.swift`, and nowhere else.

## Two commands, one compiler

```
ana@vm:~/sw/l01$ swift Hello.swift
Studied Swift for 45 minutes
ana@vm:~/sw/l01$ swiftc Hello.swift -o hello
ana@vm:~/sw/l01$ ./hello
Studied Swift for 45 minutes
ana@vm:~/sw/l01$ ls -l Hello.swift hello
-rw-r--r-- 1 ana ana   103 Oct 30 14:52 Hello.swift
-rwxr-xr-x 1 ana ana 16968 Oct 30 14:52 hello
ana@vm:~/sw/l01$ file hello
hello: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, BuildID[sha1]=11a55221dc1c195d3e9b99c0e54ed521cddaf428, not stripped
```

**`swift Hello.swift` compiles the file in memory and runs it at once**, and prints nothing else. It
is the quickest way to try something, and most programs in this course are run that way.

**`swiftc Hello.swift -o hello` compiles it to a file** and runs nothing. `-o` names the result;
without it the file would be called `Hello`, after the source. `./hello` then runs it, as any other
program on the machine is run. Both commands use the same compiler and produce the same machine
code, and the difference is only whether a file is left behind.

The two `ls` lines are worth a look. Four lines of source became a program of about 17 KB, and
`file` says what kind: an **ELF executable for x86-64**, the native format of Linux on that
processor. Swift does not run on a virtual machine the way Java and Kotlin do. The compiler,
which is built on LLVM, turns the source into instructions for the processor in front of you, and
the same `Hello.swift` compiled on an iPhone's processor becomes an ARM program instead.

The executable is small because it is not alone. It is "dynamically linked", so it borrows the
Swift runtime and standard library from the toolchain's `usr/lib/swift/linux` directory every time
it starts. Copy `hello` to a machine without the toolchain and it will not start, which is the
problem lesson 20 solves with a static build.

## What to type, every time

From here on every program arrives the same way: a block whose first line names the file, then a
terminal block showing the command and what came back. **Type the program yourself rather than
pasting it** for the first few lessons; most of what Swift teaches early is the compiler's
reaction to a typing mistake, and you will see more of those by typing.

The prompt at the start of each command, `ana@vm:~/sw/l01$`, is Ana's: her user name, her
machine's name and the directory she is in. Yours will show your own, and the part after `$` is
what you type.
