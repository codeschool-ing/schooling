---
title: Your lab, and three ways to have one
version: 1
---

**Every lesson of this course drives a browser with a program**, and the browser has to be on a
computer you control, pointed at an application you can start, break and reset. The platform
gives you none of that. This section says what the lab is and three ways to have it; the next two
build the application, and the one after them says what to do when the setup goes wrong.

The lab is one computer with four things on it:

- **Node.js**, version 22 or 24. The application under test is a Node program, and so are the
  tests. Node comes with **npm**, which installs the testing tools into the project's own folder;
- **a code editor**. Any will do; Visual Studio Code is free and is what most people doing this
  work use;
- **a browser you use by hand**, with its developer tools: Chrome, Edge or Firefox. This lesson is
  about those tools, and every later lesson opens them when a test does something surprising;
- **the project, `quitanda`**: a small online shop and, beside it, the tests that drive it. The
  next two sections build it file by file, and **Playwright**, the first testing tool you meet,
  installs into it with one command.

That is all the course needs until lesson 8, which adds Selenium to the same folder, and lesson 9,
which adds Cypress. Nothing runs on a server somewhere else and nothing needs an account.

## Three ways to have one

| path | what you get | what it costs | the transcripts |
|---|---|---|---|
| **installed** (recommended) | Node and the project on the computer you already use | about 13 MB of packages in the project, and about 920 MB of browsers in a cache folder | match on Ubuntu 24.04; close elsewhere |
| **a virtual machine** | Ubuntu Desktop 24.04, apart from your own system | about 25 GB of disk, and 4 GB of memory while it runs | match as printed |
| **online** | a Linux machine in your browser | nothing on your computer; hours from a monthly allowance | close, not exact |

**Installing on your own computer is the recommended path**, which is the opposite of what most
courses in this catalogue say, and the reason is particular to this subject. A browser test is
something you watch: in lesson 10 you run tests with the browser on screen, step through them in
Playwright's inspector and open a recorded trace in a window. All of that wants a screen, and the
computer you already use has one. Everything the course installs stays in two places, the
`quitanda` folder and Playwright's cache of browsers, so removing the lab means deleting two
folders. It works the same on Windows, macOS and Linux.

**A virtual machine** suits you if you would rather keep your own system untouched, or your
computer runs something the tools do not support. Use a desktop image, not a server one: a server
image has no screen for the browser to open on. VirtualBox runs on Windows and Linux, UTM on an
Apple-silicon Mac, and `virtualization` lesson 4 builds a machine in VirtualBox step by step. Give
it 4 GB of memory and 25 GB of disk; the browsers alone use a gigabyte.

**Online**, GitHub Codespaces gives you a Linux machine with a terminal and an editor in the
browser. It costs your computer nothing. GitHub gives personal accounts a monthly allowance of
hours and charges past it, on terms it sets and can change. A codespace has no screen of its own,
so every browser in it runs headless, the mode lesson 17 is about, and you open the shop through
the port it forwards. That path was not run for this course.

## Installing Node

Download the installer marked **LTS** from nodejs.org and run it; on Windows and macOS that is
the whole job, and it puts both `node` and `npm` on your path. On Linux, nodejs.org lists the
ways to install it for each distribution. Ubuntu's own `nodejs` package is version 18, which is
too old for the tools in this course, so do not take that one.

The machine these transcripts were recorded on already had Node, so the installation itself is
not shown. Open a new terminal and ask both programs their version:

```
ana@laptop:~$ node --version
v22.22.0
ana@laptop:~$ npm --version
10.9.4
```

**Anything from Node 22 on behaves the same here.** If yours prints a number below 22, the
installer you ran was not the LTS one, or an older Node earlier on your path is answering first;
the section on failures says how to tell.

## What the transcripts print

Every transcript in the course was recorded on Ubuntu 24.04 with Node 22.22.0, and shows the
prompt `ana@laptop:~/quitanda$`: Ana is the tester whose terminal they come from, and
`~/quitanda` is the project folder in her home directory. Yours shows your own user and folder,
and on Windows, PowerShell's `PS C:\Users\you\quitanda>` instead. The **timings** a test runner
prints are different on every machine and on every run; test names, counts, status codes and
error messages should match what you see.
