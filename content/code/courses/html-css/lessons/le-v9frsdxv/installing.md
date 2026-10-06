---
title: Installing the command-line tool
version: 1
---

Lesson 1 said one lesson would need a command-line tool, and this is it. Tailwind is a program that reads your HTML, finds the class names in it and writes a stylesheet with a rule for each one. It runs on **Node.js**, the JavaScript runtime that also runs most of the web's build tools.

**Install Node.js** from nodejs.org, the version marked LTS, long-term support. Then, in a terminal, `node --version` should print a version number. On Linux and macOS a version manager such as `nvm` is the usual way, and Windows has an installer.

**Install Tailwind in the site's folder.** In the folder of your site, the same command on every system:

```bash
npm install tailwindcss@4.3.3 @tailwindcss/cli@4.3.3
```

`npm` is Node's package manager, and it downloads the two packages into a `node_modules` folder beside your files. Pinning the version with `@4.3.3` is what this course was recorded with; without it you get the latest. This lesson does not quote what `npm install` prints, because that depends on the network on the day.

**Write an input stylesheet**, `input.css`, with one line:

```css
@import "tailwindcss";
```

**Run the build.** `npx` runs a command from an installed package. Here it is run from `~/site` on the first example, a page with the card above; `--cwd first` makes the folder `first` the place it reads from and writes to:

```
ana@laptop:~/site$ npx @tailwindcss/cli --cwd first -i input.css -o out.css --silent
```

It printed nothing, because `--silent` asks it to speak only about errors. It wrote `first/out.css`, and the page links to that file with an ordinary `<link rel="stylesheet" href="out.css">`. While you work, add **`--watch`**, and the command keeps running and rebuilds every time you save a file.
