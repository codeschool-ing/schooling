---
title: Programs and processes
version: 1
---

**A program is a file on the disk. A process is that program running.** Open the calculator twice
and there is one program and two processes, each with its own memory and its own state. When
somebody says a computer is slow, the question is almost never *which program is installed*. It is
*which processes are running*, and what each one is doing.

On the Linux server, Ana starts two copies of `sleep`, a program that does nothing for a number of
seconds, and asks for the list:

```
ana@server:~/office$ sleep 600 &
[1] 755
ana@server:~/office$ sleep 600 &
[2] 757
ana@server:~/office$ ps -o pid,ppid,stat,comm
    PID    PPID STAT COMMAND
    753     749 Ss   bash
    755     753 S    sleep
    757     753 S    sleep
    759     753 R+   ps
```

Each line is a process:

- *PID*, the *process id*: a number the kernel gives each process when it starts, and never gives
  to another process while that one is alive. `[1]` and the number after it are the shell telling
  you the first background job, and the PID it got.
- *PPID*, the parent's PID. Both `sleep`s and `ps` itself were started by the shell, `bash`, so
  their PPID is the PID of `bash` on the first line. Every process except the very first one was started by another; lesson 14
  comes back to that first one.
- *STAT*, its state: `S` is *sleeping*, waiting for something (here, for time to pass); `R` is
  *running*, which is `ps` itself, busy printing this list.
- *COMMAND*, the name of the program it is running.

## Looking at one process

The kernel keeps a record of every process, and on Linux that record can be read like a file under
`/proc`:

```
ana@server:~/office$ sleep 600 &
[1] 769
ana@server:~/office$ grep -E '^(Name|State|PPid|Threads|VmRSS)' /proc/$!/status
Name:   sleep
State:  S (sleeping)
PPid:   767
VmRSS:      2124 kB
Threads:        1
ana@server:~/office$ kill %1
ana@server:~/office$ ps -o pid,comm
    PID COMMAND
    767 bash
    774 ps
[1]+  Terminated              sleep 600
```

`VmRSS` is the memory it is really using right now, about 2 MB for a program that does nothing.
`kill %1` asks the kernel to stop job 1, and the shell reports it as `Terminated` a moment later.

## The same thing in the other two

The list exists on every system; only the window changes:

| | Windows | macOS | Linux |
|---|---|---|---|
| the window | Task Manager, `Ctrl+Shift+Esc` | Activity Monitor | System Monitor, or `top` |
| the command | `tasklist`, or `Get-Process` | `ps` and `top` | `ps` and `top` |
| stopping one | *End task* | *Force Quit* | `kill` |

**These two were not run for this lesson.** The machine these transcripts were captured on is
Linux, and the Windows and macOS columns are the names you will look for, not output you have
seen. Lesson 8 puts all three command lines side by side.
