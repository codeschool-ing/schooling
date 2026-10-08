---
title: Installing the command-line tool
version: 2
---

Tailwind is a program that reads your HTML, finds the class names in it and writes a stylesheet with a rule for each one. It runs on **Node.js**, the JavaScript runtime that also runs most of the web's build tools.

**Node.js is already on your machine** if you set it up in lesson 1 section 03, for the validator. If not, that section is the short way: install the LTS from nodejs.org, open a new terminal, and `node --version` prints a version number. Section 04 there covers what goes wrong.

**Install Tailwind in the site's folder.** In the folder of your site, the same command on every system:

```bash
npm install tailwindcss@4.3.3 @tailwindcss/cli@4.3.3
```

`npm` is Node's package manager, and it downloads the two packages into a `node_modules` folder beside your files. Pinning the version with `@4.3.3` is what this course was recorded with; without it you get the latest. This lesson does not quote what `npm install` prints, because that depends on the network on the day.

**Make a folder for the first example.** Each example in this lesson is a small site of its own: a folder inside `site` holding an `index.html` and an `input.css`, so that a build reads one page and nothing else. The first folder is `first`, and its page, `first/index.html`, is the card from section 02:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Andorinha Books</title>
    <link rel="stylesheet" href="out.css">
  </head>
  <body class="bg-stone-50 text-stone-900">
    <main id="content" class="mx-auto max-w-3xl p-4">
      <h1 id="title" class="text-2xl font-bold">This week</h1>
      <article id="poetry" class="mt-4 rounded-lg border-l-4 border-emerald-700 bg-white p-4">
        <h2 class="text-lg font-semibold">Poetry reading</h2>
        <p class="mt-1 text-stone-600">Thursday, 7 pm.</p>
      </article>
    </main>
  </body>
</html>
```

**Write an input stylesheet**, `first/input.css`, with one line:

```css
@import "tailwindcss";
```

**Run the build.** `npx` runs a command from an installed package. Here it is run from `~/site` on the first example; `--cwd first` makes the folder `first` the place it reads from and writes to:

```
ana@laptop:~/site$ npx @tailwindcss/cli --cwd first -i input.css -o out.css --silent
```

It printed nothing, because `--silent` asks it to speak only about errors. It wrote `first/out.css`, and the page links to that file with an ordinary `<link rel="stylesheet" href="out.css">`. While you work, add **`--watch`**, and the command keeps running and rebuilds every time you save a file.
