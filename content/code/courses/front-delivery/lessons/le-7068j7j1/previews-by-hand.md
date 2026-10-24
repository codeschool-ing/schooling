---
title: Two previews side by side, by hand
version: 1
---

**A host's preview is a build of a branch, published under a path or an address nobody else uses.**
Nothing about it needs the host, and doing it by hand once shows exactly what the host automates: check
out a branch without leaving the one you are on, build it for its own path, and serve both builds at
once.

## A branch to preview

A change worth previewing: the planner's heading in green, on a branch of its own.

```
ana@dev:~/planner$ git switch -q -c green-heading
ana@dev:~/planner$ echo 'h1 { color: #2f6f4e; }' >> src/style.css
ana@dev:~/planner$ git commit -qam "A green heading"
ana@dev:~/planner$ git switch -q main
```

## Each branch in a folder of its own

`git worktree` checks a branch out into another folder while the repository stays where it is, which is
how a build machine holds two branches at once without them treading on each other. Build `main` and the
branch, each with `--base` set to the path its preview will be served from, and put both under one
folder. `--outDir` writes the build somewhere other than `dist/`, and `--emptyOutDir` lets Vite clear
that folder first, which it refuses to do by default for a folder outside the project:

```
ana@dev:~/planner$ rm -rf ~/previews && mkdir ~/previews
ana@dev:~/planner$ git worktree add -q ~/previews-src/green-heading green-heading
ana@dev:~/planner$ npx vite build --base=/main/ --outDir ~/previews/main --emptyOutDir > /dev/null
ana@dev:~/planner$ (cd ~/previews-src/green-heading && npm ci > /dev/null && npx vite build --base=/green-heading/ --outDir ~/previews/green-heading --emptyOutDir > /dev/null)
ana@dev:~/planner$ ls ~/previews
green-heading
main
```

Serve the folder with `host.mjs`, from the first terminal:

```
ana@dev:~/planner$ node host.mjs ~/previews 8080
serving /home/ana/previews on http://127.0.0.1:8080
```

and ask for both, from a second:

```
ana@dev:~/planner$ curl -s http://127.0.0.1:8080/main/ | grep -o 'assets/[^"]*\.css'
assets/index-DXSNtWuR.css
ana@dev:~/planner$ curl -s http://127.0.0.1:8080/green-heading/ | grep -o 'assets/[^"]*\.css'
assets/index-BnjBSOGU.css
ana@dev:~/planner$ css=$(curl -s http://127.0.0.1:8080/green-heading/ | grep -o 'assets/[^"]*\.css')
ana@dev:~/planner$ curl -s http://127.0.0.1:8080/green-heading/$css | grep -o 'h1{[^}]*}'
h1{color:#2f6f4e}
```

**Two builds, two paths, two stylesheets, served at once by one server.** The CSS of the branch carries
the colour and `main`'s does not. Open `http://127.0.0.1:8080/main/` and
`http://127.0.0.1:8080/green-heading/` in two tabs and the headings differ; every link in each stays
inside its own preview, because each was built with its own base path. That is lesson 1's subpath, put
to work.

## What the host adds to this

The host does exactly these steps on every push, and three more things you did not:

- **an address per preview** rather than a path, `<branch>.<project>.pages.dev`, so `--base` stays `/`
  and nothing about the build differs from production's;
- **the link, posted on the pull request**, so nobody has to know the pattern;
- **cleaning up** when the pull request closes, or after a set time.

Remove the worktree and the folder when you are done; the branch stays, and the next lesson works on
`main`:

```
ana@dev:~/planner$ git worktree remove ~/previews-src/green-heading
ana@dev:~/planner$ rm -rf ~/previews ~/previews-src
ana@dev:~/planner$ git branch
  green-heading
* main
```
