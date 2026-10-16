---
title: Your machine
version: 1
---

Nothing in this course runs on a machine we host. **You build the machine yourself, and every
command in every lesson is typed there.** It is one Ubuntu 24.04 machine called `nft`, and over
the course it collects an application to test and the tools that test it: four load generators
and two smaller ones, Lighthouse, a browser that Playwright drives, a secret scanner, a
dependency auditor and Prometheus. Each tool is installed in the lesson that first uses it. This
lesson builds the machine, installs the base and types in the application.

You can throw the machine away and build it again in about half an hour. That is the property
that matters most: a lesson that leaves something broken is a lesson you can start again from
nothing, and a load test is a good way to leave something broken.

There are three ways to get it. Pick the virtual machine unless you have a reason not to.

| | what it is | what it costs |
|---|---|---|
| installed | the packages straight onto Ubuntu 24.04, either a computer of its own or WSL on Windows | nothing extra, and every tool of the course stays on that system |
| **a virtual machine with Multipass** (recommended) | Canonical's tool that creates an Ubuntu VM with one command, on Windows, macOS and Linux | 4 processors, 4 GB of memory and 20 GB of disk while it runs |
| online | a small Linux machine you rent by the hour from a cloud provider | money, and a machine on the internet from its first minute |

**The virtual machine** is recommended because it is the same everywhere, and because a load test
needs a box with known limits. The transcripts in these lessons were recorded on Ubuntu 24.04 with
exactly the packages each lesson installs. A VM is the one way to have that on any computer
without touching the system you work on. Any other hypervisor works in place of Multipass:
VirtualBox, UTM on an Apple-silicon Mac, Hyper-V or GNOME Boxes, at the price of half an hour of
installer screens.

The four processors are not decoration. The load generator and the application share the
machine, and with fewer processors the generator steals the time the application needs, so the
numbers you measure describe the generator. With two processors and 2 GB of memory every lesson
still works; your timings will differ more from the transcripts, and lessons 4 and 6, which run
Java, will be slow to start.

**Installed** is a fine choice if you already run Ubuntu 24.04, or WSL with the Ubuntu 24.04
distribution on Windows. On macOS, or on another Linux, the same tools exist, but the versions and
the install commands differ from the ones printed here. **Online** is named so that you know it
exists, not recommended: you would be paying by the hour for something your own computer does
for free, and the application listens only on `127.0.0.1`, so there is nothing to gain from a
public address.

## With Multipass

Install Multipass from its website, then, in your computer's own terminal:

```sh
multipass launch 24.04 --name nft --cpus 4 --memory 4G --disk 20G
multipass shell nft
```

**Those two commands were not run for this course**, because the computer it was recorded on
cannot run a hypervisor. The machine in the transcripts was built from the same Ubuntu release
and the same packages without one. The first command creates the virtual machine and the second
opens a shell inside it. Everything after this point happens in that shell.

Three small differences from the transcripts are expected and harmless:

- The prompt here reads `ana@nft`, and yours will read `ubuntu@nft`, because Multipass names its
  user `ubuntu`.
- `multipass shell nft` is also how you open a second terminal on the same machine. Several
  lessons need one: the application runs in the first and the load test in the second.
- On a Mac with Apple silicon, the VM's processor is ARM. Where a lesson downloads a program
  built for one processor, it names the file for `x86_64`, the one the transcripts used, and says
  which name to use for ARM.

## Two things that happen on your own computer

A screen reader needs a desktop, and the VM has none, so lesson 15 runs one on your own computer:
NVDA on Windows, VoiceOver on macOS, Orca on Linux. Lessons 10 and 13 also show the audits built
into Chrome's developer tools, which run in the browser you already have. For those, the page
has to reach your browser from inside the VM, and the section after next says how.
