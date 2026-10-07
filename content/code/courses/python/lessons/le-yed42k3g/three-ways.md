---
title: Three places to keep a Python, and the one to pick
version: 1
---

Every program in this course is typed, run and read on a computer, and the platform runs none of
them for you. So the Python you type at is one you put somewhere yourself. There are three places
to put it.

| path | what you get | what it costs your computer |
|---|---|---|
| **installed** (recommended) | Python on the computer you already use | the disk one program takes, and nothing running while you are not using it |
| **in a virtual machine** | Ubuntu Server 24.04, with its own Python 3.12, apart from your system | a few gigabytes of disk, and 2 GB of memory while it runs |
| **online** | a Linux machine with a terminal, in your browser | nothing on your computer; hours from a monthly allowance somebody else sets |

## Installed, which is the one to pick

**An interpreter is a program like any other.** Installing one changes nothing else on the
computer and leaves nothing running in the background. And every lesson after this one assumes the
Python is on the machine in front of you: the editor at the end of this lesson, the virtual
environments of lesson 18. On Ubuntu the standard library, every module that comes with it, is
54 MB. The next section is how to install one on Windows, macOS and Linux.

## In a virtual machine

Pick this if you want Linux anyway, or if the computer is one you may not install software on,
like a work laptop. A virtual machine is a whole second computer inside a window: it costs disk and
memory, and in return nothing you do inside it touches your own system.

1. **A hypervisor**, the program that runs it. VirtualBox on Windows and Linux; UTM on a Mac; on
   Windows, Hyper-V if it is already switched on.
2. **Ubuntu Server 24.04 LTS**, downloaded from ubuntu.com. On a Mac with Apple silicon, take the
   ARM image, not the one for `amd64`.
3. **A new machine** with 2 GB of memory, 2 processors and a 20 GB disk that grows as it is
   written, so it only takes what it uses. Start it with the image in its virtual drive and accept
   the installer's defaults.
4. **Sign in**, and type `python3 --version`. Ubuntu Server already has Python 3.12, and from here
   the Linux instructions in the next section are yours.

On Windows, **WSL** running Ubuntu 24.04 is the lighter version of the same thing: a Linux
terminal beside your Windows programs. `wsl --install -d Ubuntu-24.04`, in a PowerShell opened as
administrator, installs it, and the Linux instructions apply to it too.

Before you start the course, take a **snapshot**, your hypervisor's word for a saved state of the
whole machine. An experiment that goes wrong is then one click from undone. The `virtualization`
course builds and tunes one of these properly, in VirtualBox, in lesson 4.

## Online

**GitHub Codespaces** gives you a Linux machine with an editor and a terminal in the browser, and
the machine it starts comes with a Python. It costs your computer nothing, which makes it the path
for a computer that cannot take an install, like a school or library one. GitHub gives personal
accounts a monthly allowance of hours and charges past it, on terms it sets and can change. It was
not run for this course.

Any machine that gives you a terminal and a `python3` will do, from any company; nothing here
depends on one of them. Check before you start:

```
python3 --version
```

Anything from **3.10** upwards is enough for every lesson.
