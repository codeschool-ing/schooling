---
title: When the setup fails
version: 1
---

A setup that fails seldom says "your setup failed". It says something about a command, a library or
a signature, and the temptation is to remove everything and start again. **Each failure below has
one cause, and the message names it** if you read it to the end. All three were produced on purpose,
on the same Ubuntu 24.04.

## `swift: command not found`, right after unpacking it

The toolchain is on disk, and the shell cannot find it. The shell looks for a command only in the
directories listed in `PATH`, and a terminal reads `~/.bashrc`, where section 02 added the new one,
**when it starts**. A terminal that was already open before the `echo` still has the old list:

```
ana@vm:~$ swift --version; echo $?
bash: line 1: swift: command not found
127
ana@vm:~$ ~/.local/share/swift-6.4.2-RELEASE-ubuntu24.04/usr/bin/swift --version
Swift version 6.4.2 (swift-6.4.2-RELEASE)
Target: x86_64-unknown-linux-gnu
ana@vm:~$ echo $PATH
/usr/local/bin:/usr/bin:/bin
```

**Exit status 127 is the shell's own number for "no such command"**, so the message comes from
`bash` and not from Swift. The full path works, which proves the file is there. `echo $PATH` shows
the list the shell is searching, and the toolchain's `usr/bin` is not in it. Open a new terminal, or
type `source ~/.bashrc` in this one, and `swift` answers.

If a new terminal still cannot find it, look at the end of `~/.bashrc` with `tail -1 ~/.bashrc`. The
line should read exactly as section 02 typed it. Double quotes outside instead of single quotes is
the usual mistake: the shell then replaced `$HOME` and `$PATH` with their values at the moment you
typed the `echo`, which still works but freezes the old `PATH` into the file.

## `swift` is found, and a library is not

The toolchain's programs were built on Ubuntu 24.04 and expect some of that system's libraries to be
there. Unpack it and skip the `apt` line, and the program is found and then fails before it can
print anything of its own:

```
ana@vm:~$ swift --version; echo $?
swift: error while loading shared libraries: libncurses.so.6: cannot open shared object file: No such file or directory
127
ana@vm:~$ ldd $(which swift) | grep "not found"
	libncurses.so.6 => not found
```

The message is the **dynamic loader's**, the part of Linux that starts a program and connects it to
its shared libraries. It names the first library it could not find, `libncurses.so.6`, and gives up
there. **Read a message for the program that wrote it**: `swift` was found and never ran a line.
`ldd` lists every library a program asks for and where each was found, and `grep "not found"` keeps
the missing ones. The fix is the `apt` line of section 02, all of it, because a toolchain that
starts can still fail to link your first program when `binutils` or `libc6-dev` is missing.

The same message, with a different library, is what you see after unpacking a toolchain built for
another release, such as the Ubuntu 22.04 archive on a 24.04 machine. **The archive's name says
which system it is for**, and it has to match yours.

## A download that stopped halfway

A connection that drops can leave an archive that is shorter than it should be, with the right name.
Nothing about the file name tells you, and `tar` finds out late:

```
ana@vm:~/dl$ gpg --verify swift-6.4.2-RELEASE-ubuntu24.04.tar.gz.sig swift-6.4.2-RELEASE-ubuntu24.04.tar.gz; echo $?
gpg: Signature made Wed Oct 28 11:36:39 2026 -03
gpg:                using RSA key EF80A866B47A981F
gpg: BAD signature from "Swift 6.x Release Signing Key <swift-infrastructure@forums.swift.org>" [unknown]
1
ana@vm:~/dl$ tar -xzf swift-6.4.2-RELEASE-ubuntu24.04.tar.gz -C /tmp; echo $?

gzip: stdin: unexpected end of file
tar: Unexpected EOF in archive
tar: Unexpected EOF in archive
tar: Error is not recoverable: exiting now
2
ana@vm:~/dl$ ls -l swift-6.4.2-RELEASE-ubuntu24.04.tar.gz
-rw-r--r-- 1 ana ana 419430400 Oct 30 14:52 swift-6.4.2-RELEASE-ubuntu24.04.tar.gz
```

`gpg --verify` said `BAD signature` before anything was unpacked, which is why section 02 checks the
file first. Exit status 1 means the check failed. `tar` then confirms it in its own words: a
compressed archive is read from the start and the end of the data is expected to be there, and in a
file cut short it is not. **Delete the file and download it again**; there is nothing in a damaged
archive worth keeping. `ls -l` shows the difference as a size, 419,430,400 bytes against the
1,124,819,616 of the archive that verified, and that is the quickest thing to compare when you did not
keep the signature.

## When none of these is it

Three things to collect before asking anybody for help, because they answer most of the questions
you will be asked:

- `swift --version`, `which swift` and `cat /etc/os-release`, which together say what you are
  running and on what;
- `echo $PATH`, and `ls ~/.local/share`;
- the **last** lines of the failing command's output, not the first. A compiler that fails names the
  problem in its own words near the end, after whatever it was doing when it noticed.
