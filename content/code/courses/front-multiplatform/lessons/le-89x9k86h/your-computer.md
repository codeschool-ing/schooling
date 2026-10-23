---
title: Your computer, set up for this course
version: 1
---

**Everything in this course runs on your own computer, and this section sets up what the first
lessons need.** The tools come in one at a time, each in the lesson before the first one that uses
it: Capacitor in lesson 2, Android Studio in lesson 3, Expo in lesson 7, Electron in lesson 11 and
Rust with Tauri in lesson 12. Today you need three things you very probably have already: **Node.js
22, git and a browser**.

## Three ways to have one

| path | what you get | what it costs your computer | the transcripts |
|---|---|---|---|
| **installed** (recommended) | the tools on the computer you use, with its screen | the most disk of the three, added up lesson by lesson | match as printed on Linux; close on Windows and macOS |
| a virtual machine | Ubuntu Desktop 24.04, apart from your own system | the memory and disk you give it; 4 GB and 40 GB are a reasonable start | match as printed, except the Android emulator |
| online | a Linux machine in a browser tab | nothing on your computer; hours from a monthly allowance | close, and no window and no emulator |

**Install the tools on the computer you use.** This course puts apps in windows and on phones, and
both are easiest where the screen and the USB port already are. The commands are written for Linux,
and work as printed there. On **Windows**, the terminal commands run in WSL, the Linux that Windows
ships with: `wsl --install -d Ubuntu-24.04` in a PowerShell opened as administrator, then a restart.
Android Studio and its emulator install on Windows itself, from Google's installer, and lesson 3 says
how the two meet. On a **Mac**, every command runs in the Terminal app as printed, and a Mac is the
only computer that can do the iOS halves of lessons 3 and 14. The Windows and Mac paths were not run
for this course, so a path or a version in a transcript may differ from yours.

The disk adds up, and it is worth knowing where it goes. What this course measured on its own
machine: Node.js took 205 MB, Electron's copy of Chromium 274 MB inside each project that uses it,
and Rust with its compiler 816 MB. **Android Studio with its SDK and an emulator is the largest of
all**, and Google lists the memory and disk it needs on its download page; an emulator also wants a
processor with virtualisation turned on.

**A virtual machine** keeps all of it away from your own system: VirtualBox on Windows or Linux, UTM
on a Mac with an Apple chip, and **Ubuntu Desktop** 24.04 as the guest, because lessons 11 and 12 open
windows. Its weak point is the Android emulator, which is itself a virtual machine and runs slowly or
not at all inside another one. A real Android phone, with a cable and its developer options turned
on, replaces it; lesson 3 shows how.

**Online**, GitHub Codespaces gives you a Linux machine in a browser tab. It is enough for the
lessons that build and inspect, Capacitor's projects, Expo's web build, the packages of lesson 13. It
has no window to open an app in and no emulator, and GitHub gives personal accounts a monthly
allowance and charges past it, on terms it sets and can change. It was not run for this course.

## The three things

**Node.js 22.** The `javascript` course installs it in its lesson 1, and this course uses exactly
that installation: version 22.22.0, from nodejs.org, in `~/.local/node`. Check it, and git with it:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ git --version
git version 2.43.0
```

If `node --version` prints nothing, or a version below `v22`, go back to lesson 1 of `javascript`,
section "Your computer, set up for this course", and do it there once. **Do not install a second
Node** from your system's packages or from another website: two copies on one computer mean the
version in a transcript depends on which one the terminal finds first.

**Git**, from the `git` course, with your name and address set. Every project here is a repository,
because tools in this course add folders and files to your app, and `git status` is how you see what
they added.

**A browser.** Any current one shows the planner while you work. The transcripts use a copy of
Chromium driven by a program, and the next section but one sets it up.
