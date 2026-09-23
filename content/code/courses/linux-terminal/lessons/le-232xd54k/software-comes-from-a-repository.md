---
title: Software you do not download
version: 2
---

On Windows and macOS, installing something means finding its website, downloading a file, running
it, and trusting whoever made it. **On Linux that is the unusual path, not the normal one.**

The normal one is that your machine already knows a catalogue of software, signed by people your
distribution trusts, and installing is one command that names what you want.

```
sudo apt install htop
```

No browser, no website, no file in `Downloads`, no installer with a Next button.

## What a repository is

A **repository** is a server holding thousands of packages and an index of what is in it. Your
machine has a list of the repositories it trusts, and — this is the part that matters — **the
index is cryptographically signed.**

So installing does four things you did not have to think about:

1. looks the name up in an index it already has;
2. works out what else that package needs, and gets those too;
3. checks the signature — software that was tampered with in transit does not install;
4. records what it installed, so it can be removed completely later.

Compare that with downloading an `.exe`: you checked the website was the right one, and that was
the entire security model.

## Three consequences you feel immediately

**Updating is one command for everything.** Not one updater per program, each with its own
schedule and its own nagging window. The browser, the database, the kernel and the text editor are
all updated by the same two commands, at a moment you chose.

**Uninstalling actually removes it.** The package manager knows every file it put down, because it
put them down. There is no leftover folder and no registry residue — there is no registry at all,
as section 13 said.

**And the update does not reboot you.** This is the difference people notice most. Updating a
program on Linux replaces files and, where a service is involved, restarts that service. The
machine keeps running. **Only a kernel update genuinely needs a reboot**, and even that can be
deferred to a moment of your choosing rather than announced by a countdown.

That is why the servers running the internet are Linux servers. An operating system that decides
when to restart itself cannot be the one holding your database.

## Where the risk moved

It did not vanish, it changed shape, and being clear-eyed about that is part of the lesson.

Everything above is true **inside the repository**. The moment you step outside it — a
third-party repository, a `.deb` from a website, or the instruction you will absolutely meet:

```
curl -sSL https://example.com/install.sh | sh
```

…you are back to the Windows model, and worse: that line downloads a script and runs it
immediately, as whatever user you are, with no signature and no chance to read it first.

It is very common, some of it is from reputable projects, and it is still the thing to be
deliberate about rather than reflexive. Lesson 7 ranks the options by risk. The habit worth
starting now: **prefer the repository; when you step outside it, know that you did.**

## The two commands, for orientation

You will meet these properly in lesson 7 — and in lesson 2, which explains why the same idea has
three names.

| | Debian, Ubuntu | Red Hat, Rocky, Alma | SUSE |
|---|---|---|---|
| refresh the index | `apt update` | *(automatic)* | `zypper refresh` |
| install | `apt install X` | `dnf install X` | `zypper install X` |
| upgrade everything | `apt upgrade` | `dnf upgrade` | `zypper update` |
| remove | `apt remove X` | `dnf remove X` | `zypper remove X` |

**`apt update` does not update your software.** It refreshes the catalogue. `apt upgrade` is the
one that installs newer versions, and running the second without the first is why somebody's
machine has been "up to date" for a year.
