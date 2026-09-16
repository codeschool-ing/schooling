---
title: PID 1, and why there was an argument
version: 1
---

The kernel boots, mounts the root filesystem, and starts **exactly one program**. Everything else
on the machine is a descendant of it.

That program is process 1, and its job is to start everything else, in the right order, and to keep
watching. It is called the *init system*.

```
root@vm:~# ps -p 1 -o pid,comm
  PID COMMAND
    1 process_api
root@vm:~# ls -l /sbin/init
lrwxrwxrwx 1 root root 22 Jul 28 15:04 /sbin/init -> ../lib/systemd/systemd
```

**On this machine PID 1 is not an init system at all.** It is a container runtime's supervisor,
because this is a container and containers frequently run one program with no init underneath it.
That is a real and common arrangement, and it is the honest reason several transcripts later in
this lesson are drawings — the note in section 10 says so where it matters.

The second line is the interesting one. **`/sbin/init` points at systemd**, exactly as it does on
any Ubuntu: the software is installed and would be process one if this machine had booted normally.
Nothing is missing. Something else was started first.

## Three generations, and what each fixed

**SysV init**, from 1983 and in use until about 2014. A directory of **shell scripts**, numbered,
run one after another:

```
/etc/init.d/nginx start
/etc/rc3.d/S20nginx -> ../init.d/nginx
```

The `S20` is the whole design: `S` for start, `20` for the order, and the scripts run in
alphabetical sequence. It is readable, debuggable, and **slow** — one at a time, each waiting for
the last, and a machine with forty services spends a long time booting nothing in particular.

Worse, it had no idea what it had started. A script ran, the script exited, and whether the daemon
was still alive was nobody's business. Watching a service meant a second tool.

**Upstart**, Ubuntu's, 2006–2014. Event-driven rather than ordered: start this when the network
appears, start that when a disk is mounted. It solved the parallelism and lost the argument.

**systemd**, from 2010, and the default on Debian, Ubuntu, Red Hat, Fedora, SUSE and Arch. Three
ideas, and they are worth stating as ideas rather than as a verdict:

| | |
|---|---|
| **declare, do not script** | a unit file says *what* — `ExecStart=`, `After=` — instead of scripting *how* |
| **dependencies, not numbers** | `After=network.target` is a fact; `S20` is a guess about a fact |
| **track what you started** | each service gets a cgroup, so systemd knows its processes and can stop all of them |

That third one is the quiet one, and it is the biggest practical difference. Under SysV, stopping a
service meant reading a PID file and hoping. Under systemd, the service's processes are in a group
the kernel maintains, so `systemctl stop` stops the ones that forked away too.

## The argument, stated fairly

It was loud, it lasted years, and both sides had a point.

**Against**: systemd is large, and it grew well past starting services — logins, logging, network
configuration, DNS resolution, time synchronisation, containers. The Unix tradition is small tools
that compose, and systemd is not that. Its log is binary rather than text, which puts a tool
between you and your data for the first time in this course. And it is one implementation, on
nearly every distribution, in a place where a bug is a very bad bug.

**For**: the things it replaced were a pile of shell scripts that every distribution had rewritten
differently and nobody had tested. Services now describe themselves in a file that means the same
thing everywhere. Parallel startup made boots measurably faster. And the cgroup tracking closed a
class of bug that had no clean answer before.

**What settled it was neither argument.** The distributions adopted it, one after another, and the
alternatives are now the specialist choice. Devuan exists for people who want Debian without it;
Alpine uses OpenRC and is why lesson 2 mentioned it; Void uses runit. They are real and you will
probably not meet one.

**Learn systemd.** It is what is on the machine in front of you. The seven commands in section 09
are the whole of what you need for a long time.

## What PID 1 actually does, beyond starting things

Two jobs that only PID 1 can do, and both turn up later in this course:

**It adopts orphans.** When a process's parent exits, the child is re-parented to PID 1. That is
how a daemon ends up belonging to the system — section 07's second property — and lesson 6 section
06 draws it.

**It reaps them.** A finished process stays in the table until its parent collects its exit status.
An orphan's parent is PID 1, and PID 1 collects continuously. **An init that does not do this leaks
zombies**, which is the single most common bug in a hand-written container entrypoint, and lesson 6
section 04 is where you meet one.

That is also why `docker run` has `--init`: it inserts a tiny process one whose only job is those
two things, because the program you actually wanted to run was never written to do them.
