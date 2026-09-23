---
title: .gitignore: what Git should not even mention
version: 1
---

A working tree collects files that do not belong in the history. The operating system leaves some,
tools write logs, a package manager downloads other people's code, and you keep a note or two that
are nobody else's business:

```
ana@vm:~/site$ git status --short
?? .DS_Store
?? debug.log
?? node_modules/
?? notes-private.txt
```

Four untracked entries, and in a real project it is forty. They are a nuisance twice over: `git
status` stops being readable, and **`git add .` would commit all of them**. A file called
`.gitignore`, in the root of the repository, tells Git to stop seeing them:

```schooling-example
{"language": "conf", "file": ".gitignore", "parts": [{"code": "# Other people's code, which a package manager fetches again\nnode_modules/\n", "note": "A folder is ignored by its name and a slash: everything inside `node_modules/` goes, at any depth. A line starting with `#` is a comment, for the next person."}, {"code": "# Files the operating system or the tools leave behind\n.DS_Store\n*.log\n", "note": "`*` matches any name, so `*.log` is every file ending in `.log`, in any folder. `.DS_Store` is one exact name, the file macOS leaves in every folder it opens."}, {"code": "# Notes that are nobody else's business\nnotes-private.txt", "note": "A single file, by its path. Ignoring it keeps it out of `git status` and out of `git add .`, and nothing more."}]}
```

With it in place:

```
ana@vm:~/site$ git status --short
?? .gitignore
ana@vm:~/site$ git check-ignore -v debug.log node_modules/lightbox/index.js
.gitignore:6:*.log	debug.log
.gitignore:2:node_modules/	node_modules/lightbox/index.js
```

Only `.gitignore` itself is left, and it should be committed: **the ignore list is part of the
project**, shared with everybody who clones it, so that nobody commits `node_modules/` by accident.

`git check-ignore -v` answers the question you will eventually ask, *why is Git not seeing this
file?* It names the file, the line and the rule that matched: `debug.log` by `*.log` on line 6,
`node_modules/lightbox/index.js` by `node_modules/` on line 2.

## A few more rules

- A pattern with no slash matches at any depth: `*.log` catches `debug.log` and `admin/old/error.log`.
- A leading slash anchors it to the root: `/build` is the `build` folder at the top and no other.
- `!` makes an exception: `*.log` followed by `!keep.log` ignores every log except one.

## Your own leftovers, in every repository

`.DS_Store` is macOS's and not the project's, and every repository on a Mac would need the line.
Git also reads a **global ignore file** for patterns that are about your machine rather than the
project: `git config --global core.excludesFile ~/.gitignore_global`, and the same patterns go in
that file. The project's `.gitignore` then only lists what the project produces.
