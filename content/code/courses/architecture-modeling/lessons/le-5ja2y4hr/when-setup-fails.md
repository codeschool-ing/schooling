---
title: When the setup fails
version: 1
---

**Most setup failures in this lesson come from five causes, and each has a symptom you can
recognise.** Check them in this order before searching the web.

| symptom | likely cause | what to do |
| --- | --- | --- |
| `node: command not found`, or `java: command not found` | the runtime is not installed, or not on your `PATH` | reopen the terminal after installing; on Windows, sign out and in again |
| `npm install` stops while *downloading Chrome* or *chrome-headless-shell* | the browser download is blocked by a proxy or a firewall, or the disk is full | free the 700 MB it needs; behind a company proxy, set `HTTPS_PROXY` before installing, and ask your IT team which certificate to trust |
| `mmdc` says it *could not find chrome-headless-shell* | the install ran with the browser download disabled, or under a different user | run `npx puppeteer browsers install chrome-headless-shell` in the same folder, as the same user |
| `mmdc` says *running as root without --no-sandbox is not supported* | you are running it as the administrator, often inside a container | run it as a normal user; that is what the transcripts here did |
| `docker: permission denied` on the socket | your user is not allowed to talk to Docker | add your user to the `docker` group (Linux) and log in again, or start Docker Desktop |

## Two that are not obvious

**Structurizr writes files as the user inside its container.** If you run the container without
saying which user to be, the files it exports belong to a different user, or the export fails to
create its folder. The Structurizr section passes your own user and group to `docker run` for that
reason, and creates the output folder first.

**An old diagram can fail with a new version.** If a file that rendered last month fails today, check
whether a version changed before you check the file. That is the reason every command in this lesson
names an exact version, and the reason a pipeline should too.

## If it still does not work

Run the version checks from the previous section again and compare them with the table there. If
one tool will not install on your computer at all, use the virtual machine path for that tool alone:
the files in your `diagrams` folder can be copied into the VM and back. The online editors work for
practising the syntax, with the caveat the previous section gave.
