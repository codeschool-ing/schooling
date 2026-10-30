---
title: When the setup fails
version: 1
---

**Setting up is where most people stop, and almost every failure has a message that names its own
cause.** These three were made on purpose on the same machine as section 03, so you can see each one
before it happens to you, and they are in the order you would meet them.

## `command not found` in a terminal that was already open

The `export` line went into `~/.bashrc`, and a terminal reads that file when it opens. One that was
open before the line was added still has the old `PATH`:

```
ana@vm:~$ swift --version
bash: swift: command not found
ana@vm:~$ echo $?
127
ana@vm:~$ source ~/.bashrc
ana@vm:~$ swift --version
Swift version 6.4.2 (swift-6.4.2-RELEASE)
Target: x86_64-unknown-linux-gnu
```

**Exit status 127 is the shell's own way of saying it found no such program**, and it comes from
the shell before Swift is involved at all. `source ~/.bashrc` reads the file into this terminal, and
opening a new one does the same. If a new terminal still says `command not found`, look at the last
line of `~/.bashrc` with `tail -1 ~/.bashrc`: the commonest cause is the quotes, typed double outside
and single inside, which writes the path as it was when you typed it, or writes nothing at all.

## A download that stopped halfway

A connection that drops without `-C -` and `--retry` leaves a file that looks like the archive and is
only part of it. Here it is made on purpose, by cutting a copy to 300 MB:

```
ana@vm:~/downloads$ ls -lh cut.tar.gz
-rw-r--r-- 1 ana ana 300M Oct 30 15:04 cut.tar.gz
ana@vm:~/downloads$ gpg --verify swift-6.4.2-RELEASE-ubuntu24.04.tar.gz.sig cut.tar.gz
gpg: Signature made Wed Oct 28 11:36:39 2026 -03
gpg:                using RSA key EF80A866B47A981F
gpg: BAD signature from "Swift 6.x Release Signing Key <swift-infrastructure@forums.swift.org>" [unknown]
ana@vm:~/downloads$ tar xzf cut.tar.gz -C /tmp; echo $?

gzip: stdin: unexpected end of file
tar: Unexpected EOF in archive
tar: Unexpected EOF in archive
tar: Error is not recoverable: exiting now
2
```

**`BAD signature` is gpg saying that these bytes are not the bytes the Swift project signed.** It
cannot tell you whether they were cut short or changed, and it does not need to: either way the
answer is to download again. `tar` fails too, at the point where the data runs out, and exit status
2 is its word for a fatal error. Check the signature before unpacking and you never meet the `tar`
message at all.

If `gpg` says `No public key` instead, the import in section 03 did not happen in this account:
run the `curl … | gpg --import -` line again.

## A toolchain that will not start

This is a fresh machine again, where the student skipped the `apt` line and went straight to the
download:

```
ana@vm:~/downloads$ tar xzf swift-6.4.2-RELEASE-ubuntu24.04.tar.gz -C ~/.local/share
ana@vm:~/downloads$ echo 'export PATH="$HOME/.local/share/swift-6.4.2-RELEASE-ubuntu24.04/usr/bin:$PATH"' >> ~/.bashrc
ana@vm:~/downloads$ source ~/.bashrc; swift --version
swift: error while loading shared libraries: libncurses.so.6: cannot open shared object file: No such file or directory
```

**`error while loading shared libraries` comes from the system's loader, not from Swift.** The
`swift` program is there and it is on the `PATH`; it needs a library this system does not have, and
the message names it. A desktop Ubuntu usually has `libncurses`, and then the same mistake surfaces
later, as a `swift build` that cannot find a header or a linker. Both have one fix, the `apt install`
line from section 03, and it is safe to run again: `apt` skips what is already installed.

## When nothing here matches

- **Read the first error, not the last.** A build prints the error that caused the others first.
- **Check the version and the system.** Swift 6.4.2 for Ubuntu 24.04 is a different download from
  the one for 22.04, and from the one for an ARM processor (`aarch64` in the name). `uname -m` says
  which processor you have, and `cat /etc/os-release` says which Ubuntu.
- **Start the toolchain again from nothing.** Delete the unpacked directory under `~/.local/share`
  and the downloaded archive, and do section 03 again. Nothing else on the system depends on them.
- **On a Mac with Xcode**, `xcode-select -p` prints which developer directory the `swift` command is
  using. If it names `CommandLineTools` while you expected Xcode, Apple's documentation for
  `xcode-select` explains how to point it at the Xcode you installed. That command was not run for
  this course.
