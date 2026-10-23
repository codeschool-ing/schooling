---
title: Your computer, checked for this course
version: 1
---

**Everything in this course runs on your own computer.** There is no machine to log in to and no
playground in the browser: you install the tools, you create the project, and every transcript in
the lessons is what that computer printed. This section checks you have what the course starts from
and says what it adds.

## What you already have

`javascript` is required before this course, and its lesson 1 set up three things this course uses
as they are:

- **Node.js 22.22.0**, unpacked from nodejs.org into `~/.local/node`, with `node`, `npm` and `npx`
  linked into `~/.local/bin`;
- **npm 10.9.4**, which came in the same folder;
- **`~/js-tools`**, a folder holding Playwright 1.56.0, the Chromium it drives, and `page.mjs`.

Open a terminal and ask:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ ls ~/js-tools
node_modules
package-lock.json
package.json
page.mjs
serve.mjs
ana@dev:~$ du -sh ~/.local/node ~/js-tools
205M	/home/ana/.local/node
13M	/home/ana/js-tools
```

If any of those three answers differently, or `~/js-tools` is not there, go back to `javascript`
lesson 1, section "Your computer, set up for this course", and do it as written. **Do not install a
second Node**: the whole `frontend` track runs on this one, and two copies of Node on one machine
is the most common way for `npm` and the program you meant to run to disagree about which one is
answering.

`du` measured what the two folders cost. The browser Playwright downloaded sits in
`~/.cache/ms-playwright`, which `javascript` lesson 1 put at about 320 MB.

## What this course adds

| | where | about |
|---|---|---|
| TypeScript, for this lesson's two sections | `~/ts` | 23 MB |
| the Angular project you build across 25 lessons | `~/planner` | 320 MB, nearly all of it `node_modules` |
| one more program beside `page.mjs`, called `look` | `~/js-tools` | a few kilobytes |

Lesson 2 creates the project and measures it, and shows `look` whole. Nothing is installed
globally: the Angular CLI lives inside the project, at the exact version the project names, so a
second project next year can use a different one without the two meeting.

## Three ways to have the computer

The three paths are the ones `javascript` lesson 1 describes, and the advice is the same.

| path | what it costs your computer | the transcripts |
|---|---|---|
| **installed** (recommended) | the disk in the tables above; the dev server of lesson 2 holds about 370 MB of memory while it runs | match as printed on Linux; close elsewhere |
| a virtual machine | a few gigabytes of disk for Ubuntu Server 24.04, and memory for the guest; 4 GB leaves room for the dev server and a browser | match as printed |
| online | nothing on your computer; hours from a monthly allowance | close, not exact |

**Installed on the computer you use** is the recommendation, for the same reason as before: the
browser you test with is on the same machine as the server it talks to, and `localhost` means one
thing. On Windows that means WSL, as `javascript` lesson 1 set it up, and every command in this
course is typed in its Ubuntu terminal.

**A virtual machine** works, with one thing to know: the dev server listens on `localhost` inside
the guest, so a browser on your own desktop cannot reach it until the server is started with
`--host 0.0.0.0` and the virtual machine forwards the port. Lesson 2 shows the flag. `look`, which
runs inside the guest, needs neither.

**Online**, GitHub Codespaces gives you a Linux machine in a browser tab and forwards the dev
server's port for you. It was not run for this course, and its free allowance is GitHub's to
change, so treat it as the fallback when neither of the others is possible.

## An editor that knows Angular

Any editor works, and the transcripts never show one. If you use Visual Studio Code, the project
lesson 2 creates recommends one extension, **Angular Language Service**, and VS Code offers to
install it when you open the folder. It reads your templates the way the compiler does, so a typo
in `{{ minutes }}` is underlined before you build. It was not part of the recording, which used
only the terminal.
