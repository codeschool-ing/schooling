---
title: From the push to the page
version: 1
---

**A built front end is a folder of files, and deploying it means putting that folder where a browser
can ask for it.** That is the whole of it for the app in this course, and for most single-page apps.
The folder holds an HTML page, one or more scripts, stylesheets and whatever data and pictures the
app reads. None of it runs on the machine that serves it. It runs in the browser of whoever opens
the page.

The picture many people arrive with is the one from a back end: a deploy starts a process on a
server, and the process answers each request with something it computes. A static front end has no
such process. The server's whole job is to find a file by its path and send it back, and the program
that does that was written once, by somebody else, and is the same for every site it serves.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The path from a push to a page. A commit is pushed to the repository. A build machine checks it out, runs npm ci and npm run build, and writes the folder dist, holding index.html, a script, a stylesheet and courses.json. Only that folder is uploaded to the host, which copies it to servers in many cities. A browser asks the nearest copy for each file and runs the app itself.\"><rect x=\"20\" y=\"40\" width=\"150\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">repository</text><text x=\"95\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">git push</text><rect x=\"190\" y=\"40\" width=\"150\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">build machine</text><text x=\"265\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">npm ci</text><text x=\"265\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">npm run build</text><rect x=\"360\" y=\"40\" width=\"150\" height=\"130\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"435\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">dist/</text><text x=\"435\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">index.html</text><text x=\"435\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">assets/…js</text><text x=\"435\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">assets/…css</text><text x=\"435\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">courses.json</text><rect x=\"530\" y=\"40\" width=\"150\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">host and CDN</text><line x1=\"170\" y1=\"105\" x2=\"190\" y2=\"105\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"190.0,105.0 182.6,108.1 182.6,101.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"340\" y1=\"105\" x2=\"360\" y2=\"105\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"360.0,105.0 352.6,108.1 352.6,101.9\" fill=\"var(--paper-dim)\"></polygon><line x1=\"510\" y1=\"105\" x2=\"530\" y2=\"105\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"530.0,105.0 522.6,108.1 522.6,101.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"560\" y=\"95\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><rect x=\"605\" y=\"120\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><rect x=\"650\" y=\"95\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><rect x=\"575\" y=\"145\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><rect x=\"635\" y=\"148\" width=\"22\" height=\"14\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">copies in many cities</text><line x1=\"605\" y1=\"172\" x2=\"605\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"605.0,200.0 601.9,192.6 608.1,192.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"530\" y=\"202\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the browser runs it</text><text x=\"20\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">you do the first step;</text><text x=\"20\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a connected host does the other three</text></svg>", "caption": "A static front end from push to page: what is deployed is the built folder, and nothing in it runs on the host."}
```

## The four steps, and who does each

1. **You push.** A commit reaches a branch of a repository on GitHub, GitLab or Bitbucket. Everything
   in this course starts there, which is why the course asks for a repository before anything else.
2. **Something builds.** A machine that is not yours checks the commit out, installs the dependencies
   from the lockfile and runs the build command, `npm run build` here. The build turns TypeScript into
   JavaScript, bundles the modules into a few files and writes them to `dist/`. Lesson 3 is about that
   machine.
3. **The files are uploaded.** The contents of `dist/`, and nothing else, go to the host. The source,
   `node_modules` and the lockfile stay behind.
4. **The host answers.** It copies the files to servers in many cities, its **CDN** (content delivery
   network), so a reader in Recife and one in Lisbon each get them from somewhere nearby. A request
   for `/assets/index-BVi82VJx.js` is answered with that file, from the nearest copy.

**The host does steps 2 to 4 for you** when it is connected to the repository, and that is most of
what the four hosts in this lesson sell: they watch a branch, build each push and publish the result.
GitHub Pages is the odd one, because it can build only with GitHub Actions, a workflow you write;
the section on their steps shows it.

## What this does not cover

Some front ends do need a server: one that renders HTML on each request, or answers API calls beside
the pages. Those are server-side rendering and functions, and front-performance lessons 1 to 3 compare
them. Everything in this course is the static case, because it is the one every one of those
approaches still ends with: a folder of built files that somebody has to serve.

## What you will have by the end

A small app built and served on your own computer the way a host serves it, the configuration each
of the four hosts would read, and the one difference between them that breaks a site on its first day.
**None of the four is run in this course.** Each needs an account, and each changes its screens and its
free plan on its own schedule. Their steps are quoted from their own documentation and marked as not
run; what you run is everything they would run for you.
