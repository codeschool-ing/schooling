---
title: Submodules: another project, pinned to one commit
version: 1
---

Sometimes a project needs another project inside it. The bakery's site and the bakery's ordering app
should use the same brand colours, kept in a repository of their own, `shared-styles`. Copying the
files into each project would give two copies that drift apart. **A submodule puts one repository
inside another, pinned to an exact commit.**

```
ana@vm:~/site$ git submodule add ~/remotes/shared-styles.git styles
Cloning into '/home/ana/site/styles'...
done.
ana@vm:~/site$ cat .gitmodules
[submodule "styles"]
	path = styles
	url = /home/ana/remotes/shared-styles.git
ana@vm:~/site$ git status --short
A  .gitmodules
A  styles
ana@vm:~/site$ git commit -qm "Use the shared brand styles"
ana@vm:~/site$ git submodule status
 d874c59046ca2f86c55a3ff9aaa882624f8973a5 styles (heads/main)
```

(`shared-styles` lives in a local folder here, like every remote in this course, and Git refuses a
local address for a submodule unless `protocol.file.allow` is set, which the capture script does. With
a real server's address none of that is needed.)

Three things happened:

- `styles/` is a clone of `shared-styles`, a complete repository of its own inside the site.
- `.gitmodules` records where it comes from and where it lives. It is committed, so every clone knows.
- **The site's commit records one thing about `styles/`: the exact commit it is at**, `d874c59`. Not
  the files, not the branch. `git submodule status` prints that id.

That pinning is the point. The site keeps using exactly `d874c59` until somebody deliberately moves
it: goes into `styles/`, fetches and checks out a newer commit, and commits that change in the site.
New colours in `shared-styles` never reach the site by surprise.

## Cloning a project with submodules

```
ana@vm:~$ git clone -q ~/remotes/site.git copy && cd copy
ana@vm:~/copy$ ls styles
ana@vm:~/copy$ git submodule update --init
Submodule 'styles' (/home/ana/remotes/shared-styles.git) registered for path 'styles'
Cloning into '/home/ana/copy/styles'...
done.
Submodule path 'styles': checked out 'd874c59046ca2f86c55a3ff9aaa882624f8973a5'
ana@vm:~/copy$ ls styles
brand.css
```

**A plain clone brings the submodule's folder and nothing in it.** `git submodule update --init` then
clones it and checks out the pinned commit. `git clone --recurse-submodules` does both in one step,
and forgetting it is the most common thing that goes wrong with submodules: the project arrives
without part of itself, and the error appears somewhere else entirely.

## Should you use them?

Submodules solve a real problem and are known for being awkward: every person has to remember the
extra commands, and moving the pinned commit is a small ceremony. For code, most languages have a
**package manager** that does the same job better — lessons in the language courses cover them. Use a
submodule when there is no package manager for what you are sharing, as with a folder of stylesheets
or design assets, and when pinning to an exact commit is what you want.
