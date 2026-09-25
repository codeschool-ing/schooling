---
title: Why a program refuses to run
version: 1
---

A program is built for *a processor architecture*, *a system*, and often *particular versions* of
the libraries it uses. Any of the three can refuse it.

```
ana@server:~$ dpkg --print-architecture
amd64
ana@server:~$ ldd /usr/bin/ls
        linux-vdso.so.1 (0x00007fd6a8823000)
        libselinux.so.1 => /lib/x86_64-linux-gnu/libselinux.so.1 (0x00007fd6a87c6000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fd6a8400000)
        libpcre2-8.so.0 => /lib/x86_64-linux-gnu/libpcre2-8.so.0 (0x00007fd6a872c000)
        /lib64/ld-linux-x86-64.so.2 (0x00007fd6a8825000)
ana@server:~$ ldd --version | head -1
ldd (Ubuntu GLIBC 2.39-0ubuntu8.9) 2.39
PS /home/ana> $PSVersionTable.PSEdition
Core
PS /home/ana> $PSVersionTable.PSVersion.ToString()
7.6.6
```

- `amd64` is this server's architecture, the 64-bit Intel and AMD one. A program built for `arm64`,
  lesson 4's Apple silicon and lesson 5's Windows on Arm, does not run here without an emulator.
- `ldd` lists the **shared libraries** a program needs. `ls` needs a few, among them `libc.so.6`,
  the C library, here **glibc 2.39**. A program built on a newer system against glibc 2.40 refuses to
  start on this one, which is why a binary copied from a newer distribution fails with *version
  GLIBC_2.40 not found*, and why packages come from the distribution rather than from another one.
- PowerShell says which one it is: **`Core`** is PowerShell 7; `Desktop` is Windows PowerShell 5.1.
  A script written for one can fail on the other, lesson 5's point about which you will meet.

## The same three on each system

| | the architecture | the system | the version |
|---|---|---|---|
| Windows | 32-bit programs run on 64-bit Windows; x64 runs on Arm through Prism | Windows programs only | *Compatibility mode*, in a program's properties, pretends to be an older Windows |
| macOS | Intel apps run on Apple silicon through **Rosetta 2** | Mac apps only | an app states the oldest macOS it accepts |
| Linux | `dpkg --add-architecture` for 32-bit packages | Linux programs only | libraries from the same distribution and release |

**Compatibility mode** is worth a sentence: many old Windows programs that refuse to start only asked
*which Windows is this?* and did not like the answer, lesson 5's `ProductName` from the other side.
Telling them an older version is often enough.
