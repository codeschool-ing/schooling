---
title: Your machine: a browser, an editor and a folder
version: 1
---

This course is practised by writing pages and opening them, and **the platform gives you no machine to do it on.** You set one up yourself, once, here. It is small: three programs and one folder.

- **A browser built on Chromium**: Chrome, Edge or Chromium itself. Every number in this course was printed by Chromium, so it is the browser in which your numbers will match the lessons. Firefox and Safari draw the same pages and differ from it by a pixel here and there.
- **A text editor** that saves plain text in UTF-8. VS Code is free on Windows, macOS and Linux, and it is the editor the lessons have in mind when they name a menu. Any editor that saves plain text works. A word processor does not.
- **Node.js**, for two command-line tools: the validator in section 13 and Tailwind in lesson 13. Lessons 2 to 12 need only the browser and the editor.

## Choose where it runs

| path | what you need | what it costs your computer |
|---|---|---|
| **on your own computer (recommended)** | Windows, macOS or Linux as it is | about 200 MB for Node.js, 13 MB for the validator, and your editor |
| in a virtual machine | VirtualBox on Windows and Linux, UTM on a Mac, and Ubuntu Desktop 24.04 LTS | 4 GB of memory while it runs and 25 GB of disk, Ubuntu's own minimum |
| online | an editor in a web page that draws the result beside the code, such as CodePen or StackBlitz | nothing locally; an account, and a free plan that is the company's to change |

**Your own computer is the recommendation**, because nothing in this course needs isolating. A page is a file your browser opens; nothing here listens on a port, changes the system or needs a password. And the browser you already use is the one your readers use.

The virtual machine is for anybody who wants the machine these lessons were recorded on, Ubuntu 24.04, exactly. It is the **Desktop** edition, not Server, because this course needs a window with a browser in it. Ubuntu Desktop comes with Firefox; Chromium is one command away, `sudo snap install chromium`. Node.js goes in the same way as on any Linux, below.

The online editors work from a borrowed computer, and they are fine for lessons 2 to 12, where everything is HTML and CSS. The course does not depend on any of them, because what they offer for free is decided by the company that runs them. And the two terminal sessions, in section 13 and in lesson 13, need a Node.js they may not give you.

## Build it

**Install Node.js** from nodejs.org, the version marked LTS. On Windows and macOS that is an installer. On Linux, nodejs.org lists the packages for each distribution, and a version manager such as `nvm` is the other usual way. When it finishes, **open a new terminal**, because a terminal that was already open does not know Node exists. Then check:

```
ana@laptop:~$ node --version
v22.22.0
ana@laptop:~$ npm --version
10.9.4
```

The validator this course uses needs Node 22.22 or later in the 22 line, or 24.8 or later. A newer LTS than the one above is fine.

**Make the folder** that every page in the course goes in. The lessons call it `~/site`, a folder called `site` in your home directory, and the same two commands make it in a terminal on Windows, macOS and Linux:

```
ana@laptop:~$ mkdir site
ana@laptop:~$ cd site
```

**Install the validator into it.** `npm` is Node's package manager, and this downloads one package into a `node_modules` folder inside `site`:

```sh
npm install html-validate@11.16.2
```

`@11.16.2` pins the version this course was recorded with; without it you get the latest, and the messages in section 13 may read differently. This lesson does not quote what `npm install` prints, because that depends on the network on the day.

**Tell the validator what to check.** Save this as `.htmlvalidate.json` in `site`, with the dot at the start of the name:

```json
{"extends": ["html-validate:standard", "html-validate:document"]}
```

It chooses two of the validator's sets of rules: `standard`, the rules of the HTML language, and `document`, the ones about a whole page, such as having a doctype and a title. Then check that `npx`, which runs a program installed in the current folder, finds it:

```
ana@laptop:~/site$ npx html-validate --version
html-validate-11.16.2
ana@laptop:~/site$ ls -A
.htmlvalidate.json
node_modules
package-lock.json
package.json
```

`package.json` and `package-lock.json` are npm's record of what it installed. `ls -A` is there to show the configuration file, which `ls` alone hides: on macOS and Linux a name that starts with a dot is hidden. That is the whole setup.

## How a page reaches your screen

Every page a lesson measures is shown whole in the section that measures it, or is described as a change to a page shown before it: "the same file with its first line deleted". **Type or paste it into a new file in your editor, save it in `site` under the name the section gives, and double-click it.** It opens in your browser. When you change the file, save it and reload the tab, because the browser shows the file as it was when it last read it. A few names, such as `order.html` and `fixed.html`, come back in a later lesson as a different page; save the new one over the old.

To see what the browser did with the page, right-click on any element and choose **Inspect**. The panel that opens is DevTools, from `web-fundamentals` lesson 11, and it is where you check every number the lessons quote.
