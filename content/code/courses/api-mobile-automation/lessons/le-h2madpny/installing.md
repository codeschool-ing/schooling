---
title: Postman, and keeping your work in files
version: 1
---

**Postman is a desktop application that sends HTTP requests and keeps them**, so a request you built
once can be sent tomorrow exactly as it was. Everything it sends, curl sent in lesson 1. What it
adds is memory and a window. Each request is saved under a name, the answer is laid out in panes,
and the requests of one API sit together in a *collection*. It is also the tool most QA teams open
first when a new API arrives, which is reason enough to know it.

It is not the API, and it is not a test framework, though it can run tests. A request in Postman is
the same text on the wire as the one curl sent, and boxoffice cannot tell which program asked.

## Getting it

Download it from postman.com, for Windows, macOS or Linux. On Ubuntu the same program is also
published as a snap, which installs with one line:

```sh
sudo snap install postman
```

On Windows with WSL, install the Windows version rather than the Linux one. WSL passes `localhost`
through to Windows, so Postman on Windows reaches boxoffice running inside WSL at `localhost:8080`
with nothing to configure. Start boxoffice in its own terminal, as in lesson 1, before sending
anything.

**The free plan asks you to sign in, and keeps your collections in Postman's cloud.** That is
Postman's business, and the terms are Postman's to change. They did in 2023, when the Scratch Pad,
the way of working without an account, was retired. So this course keeps every collection as a JSON
file in your own project, under `~/boxoffice/postman/`. You save the files from these lessons and
import them into the app. A file is yours whatever the plan becomes: Newman runs it in lesson 6
without an account, and git keeps its history like any other file.

Make the directory now, in your first terminal:

```sh
mkdir -p ~/boxoffice/postman
```

## Two alternatives that use the same ideas

| tool | what it is | where it keeps your requests |
|---|---|---|
| **Bruno** | open source, desktop | as plain-text files in a folder you choose |
| **Insomnia** | from Kong, desktop | on your computer or in Kong's cloud, as you choose |

Both have collections, environments and variables under those names, and both can import a Postman
collection file. Everything this lesson explains carries over; only the buttons move. Bruno's
choice to keep requests as files in your project is the same choice this course makes for Postman
by hand.

## What this lesson cannot show you

**Postman was not run for this course.** The machine every transcript comes from has no graphical
desktop, and Postman does not run without one. So its windows are described in words here, never
drawn or photographed, and every claim about a file is checked in a terminal with jq instead.
Postman also rearranges its interface from time to time. When a button is not where a sentence puts
it, look for the word rather than the position.
