---
title: Your computer, and the three ways to set it up
version: 1
---

**This course gives you no machine.** Every command in it runs on a computer you control, and this
section is how to get one ready before lesson 1's last section asks you to type anything. The
lessons after this one assume what you build here and say so when they add to it.

What you need is small at first and grows in two steps:

| from | what | about how much disk |
|---|---|---|
| lesson 1 | Node.js 22.22.0, npm, git, a terminal and an editor | a project's `node_modules` is about 400 MB |
| lesson 3 | a browser, and optionally Expo Go on a phone | nothing more on the computer |
| lessons 3, 17, 18 and 20 | a Java Development Kit 17 and the Android SDK, for Android builds | 2.5 GB for the SDK, and over 500 MB of Gradle's cache after one build |

**Node.js is installed exactly as lesson 1 of `javascript` installs it**: the 22.22.0 tarball from
nodejs.org, unpacked into `~/.local/node`, with `node`, `npm` and `npx` linked into `~/.local/bin`.
If you took that course, it is already there; the next section checks. If you did not, that lesson's
section "Your computer, set up for this course" has the five commands, and on a Mac the same tarball exists for
`darwin-arm64` and `darwin-x64`.

## The three paths

**1. Installed on your own computer. This is the one to choose.** Linux, a Mac, or Windows with WSL 2
running Ubuntu. Everything runs at full speed, the browser that shows lesson 3's app is the one you
already use, and a phone on the same Wi-Fi can reach the development server directly. It costs the
disk in the table and nothing else. On Windows, keep the project inside WSL's own file system
(`~/planner`, not `/mnt/c/...`): npm and the bundler read thousands of small files, and doing that
across the boundary into Windows is many times slower.

**2. An Ubuntu 24.04 virtual machine.** VirtualBox on Windows or Linux, UTM on a Mac. Give it 4 GB of
memory, two processors and 40 GB of disk, which is what the course needs plus room for the operating
system. Your computer pays for the machine while it runs, roughly that memory taken away from
everything else. Two things get harder: a phone reaches a development server inside a virtual machine
only if the machine's network is *bridged* rather than *NAT*, and the Android emulator needs hardware
virtualisation, which most virtual machines do not pass through to their guests.

**3. Online, in a cloud development environment.** Any Linux machine you reach through a browser or
SSH works: GitHub Codespaces, Gitpod, a server you rent. Your computer pays nothing, and you need
a connection for every minute of study. The web build is reached through the service's port
forwarding, and a phone cannot reach the development server without a tunnel. **Their free
allowances change without notice**, and nothing in this course depends on any one company's: if the
one you use stops being free, the commands are the same anywhere else.

## The phone, if you have one

**A phone is optional and worth having.** Expo Go, a free app from both stores, runs your project
on a real device without building anything: lesson 3 shows how. It shows the real native views this
lesson described, where the browser shows HTML standing in for them. No step in this course
*requires* one, because every lesson also runs in a browser or in tests on the computer.

## What needs more than a computer

Two things do, and lesson 1's section on the boundary says which lessons they touch. **An Android
emulator** needs hardware virtualisation on the computer that runs it: KVM on Linux, the Windows
Hypervisor Platform on Windows, the Hypervisor framework on a Mac. **The iOS simulator and Xcode need
a Mac**, by Apple's licence, and no virtual machine or cloud environment in this list provides one.
