---
title: Asking the kernel: system calls
version: 1
---

Section 02 said that programs never touch the hardware; they ask the kernel. On Linux you can watch
the asking. `strace` runs a program and writes down every request it makes to the kernel. Ana uses
it on `cat`, which prints a file:

```
ana@server:~/office$ strace -e trace=openat,read,write -o trace.txt cat notice.txt
Ribeiro Contabilidade
Open 8:00 to 18:00
ana@server:~/office$ grep -A3 notice.txt trace.txt
openat(AT_FDCWD, "notice.txt", O_RDONLY) = 3
read(3, "Ribeiro Contabilidade\nOpen 8:00 "..., 131072) = 41
write(1, "Ribeiro Contabilidade\nOpen 8:00 "..., 41) = 41
read(3, "", 131072)                     = 0
```

Four requests, and they are the whole of what `cat` does:

1. `openat(..., "notice.txt", O_RDONLY) = 3`: *open this file for reading.* The kernel checks that the
   file exists and that Ana is allowed to read it, and answers with a number, `3`, that the program
   will use to refer to it from now on.
2. `read(3, ...) = 41`: *give me up to 131072 bytes from file 3.* The kernel fetches the 41 bytes
   the file has, from the disk or from the cache of the last section.
3. `write(1, ...) = 41`: *write these 41 bytes to 1.* Number 1 is the screen, or more exactly the
   terminal, which every program is handed already open.
4. `read(3, "", ...) = 0`: *more?* Zero bytes means the end of the file, and `cat` stops.

Nowhere does `cat` know where the disk is, what kind it is or how the terminal draws letters. The
kernel does all of it, which is why the same `cat` works on any disk and any screen.

## Two modes

The processor itself enforces the split. Programs run in **user mode**, where the instructions that
touch hardware are forbidden. A system call switches into **kernel mode**, the kernel does the work,
and control comes back. A program that misbehaves in user mode crashes alone. A fault in kernel mode
brings the whole machine down: the Windows *blue screen*, a Linux *kernel panic*, the macOS restart
with *your computer restarted because of a problem*.

That is why a broken driver (next section) is more dangerous than a broken program: drivers run in
kernel mode.

## On the other two

Windows and macOS make the same kinds of requests with different names. The tools that show them,
Process Monitor on Windows and `dtruss` on macOS, are the equivalents of `strace`, and neither was run
for this lesson.
