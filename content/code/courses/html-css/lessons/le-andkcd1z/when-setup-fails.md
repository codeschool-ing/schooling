---
title: When the setup does not work
version: 1
---

Setup is where most people stop, usually at a message they have not seen before. These three were reproduced on purpose, and each one says what is wrong if you know how to read it.

## The terminal has never heard of Node

```
ana@laptop:~/site$ node --version
bash: node: command not found
```

Either Node.js is not installed, or it was installed after this terminal was opened. A terminal reads the list of places it looks for programs once, when it starts. **Close it and open a new one** before reinstalling anything. On Windows the wording is different, *is not recognized as the name of a cmdlet*, and it means the same.

## The validator is not a command on its own

```
ana@laptop:~/site$ html-validate -f text skeleton.html
bash: html-validate: command not found
```

That is correct, and nothing is broken. `npm install` put the validator inside `site/node_modules`, not among the system's programs, so the terminal does not find it by name. **`npx` is what finds it**: `npx html-validate -f text skeleton.html`.

## npx offers to download it

```
ana@laptop:~$ npx html-validate --version
Need to install the following packages:
html-validate@11.16.2
Ok to proceed? (y) n
npm error canceled
npm error A complete log of this run can be found in: /home/ana/.npm/_logs/2026-10-07T10_46_24_037Z-debug-0.log
```

Look at the prompt: `~`, not `~/site`. `npx` looks for the program in the folder you are in, did not find it, and offered to fetch the latest version from the internet. **Answer `n`, then `cd site`.** Answering `y` works, and leaves you with a validator that is not the one the lessons were recorded with, and without the `.htmlvalidate.json` that lives in `site`. The version it offers is whatever is newest on the day you ask.

## Four that were not reproduced here

**On Windows, a page saved as `skeleton.html.txt`.** File Explorer hides extensions by default, and Notepad adds `.txt` unless you choose *All files* when saving. The page opens in Notepad instead of the browser. Turn on file name extensions in File Explorer's **View** menu, and the real name is visible.

**A double-click that opens the editor.** Your computer has decided `.html` files belong to the editor. Drag the file onto a browser window, or right-click it and choose **Open with**, then your browser.

**A change that does not appear.** The browser does not watch the file. Save in the editor, then reload the tab.

**npm warns about `EBADENGINE`.** Your Node is older than the validator accepts. Install the current LTS from nodejs.org and run `npm install html-validate@11.16.2` again in `site`.
