---
title: Your lab, and three ways to have one
version: 1
---

**Everything in this lesson runs on a machine you prepare yourself; the platform runs nothing for
you.** The transcripts below were recorded on a Linux machine with the same tools and versions this
section tells you to install, by a user called `ana` on a machine called `vm`. Your prompt will show
your own names, and the timings and dates in the output will differ; everything else should match.

## What the three tools need

| tool | runs on | version used here |
| --- | --- | --- |
| **Mermaid's command-line renderer**, `mmdc` | Node.js, plus a headless browser it downloads on install | `@mermaid-js/mermaid-cli` 11.17.0 on Node.js 22 |
| **PlantUML** | Java, as a single `.jar` file | PlantUML 1.2026.9 on Java 21 |
| **Structurizr** | a container image (or Java, as a single `.war` file) | `structurizr/structurizr:2026.09.19` on Docker |

Docker is only needed for the Structurizr section. If you skip that section, Node.js and Java are
enough.

## Three paths

| | what it is | what it costs your computer |
| --- | --- | --- |
| **installed** (recommended) | Node.js 22 LTS, a Java 21 runtime and, for Structurizr, Docker, on the computer you already use | about 700 MB of disk for the browser `mmdc` downloads, 30 MB for PlantUML, about 730 MB for the Structurizr image; memory is not a concern |
| **a virtual machine** | an Ubuntu 24.04 VM, for example made with Multipass, with the same three installed inside | the same disk inside the VM, plus the VM itself: 2 processors, 4 GB of memory and 20 GB of disk is comfortable |
| **online** | the projects' own editors in the browser: the Mermaid Live Editor, PlantUML's online server, Structurizr's online tooling | nothing on your computer, and **everything you type is sent to somebody else's server** |

**Installed is recommended** because the tools are small, they are what a team's pipeline will run,
and the diagram files stay on your disk. The virtual machine is the right choice if you would rather
keep your own computer clean, or it runs an operating system on which one of the tools gives you
trouble. The online editors are named so you know they exist; they were not checked for this course,
they can change their terms whenever their owners decide, and **an architecture diagram of a real
company's system should not be typed into somebody else's website** without that company's
agreement.

## Installing

- **Node.js 22 LTS**: from nodejs.org, the installer for your system, or through a version manager.
  On Ubuntu 24.04 the packaged `nodejs` is an older version; use NodeSource's packages or the
  official binaries instead.
- **Java 21**: a free build such as Eclipse Temurin, from adoptium.net. On Ubuntu 24.04,
  `sudo apt install openjdk-21-jre-headless` installs one. **That command was not run for this
  course**; the recording machine already had Java 21.
- **Docker**: Docker Desktop on Windows or macOS, Docker Engine on Linux, following Docker's own
  instructions. Your user needs permission to run `docker` without `sudo`.

Then make a folder for this lesson and check the versions. These were recorded:

```
ana@vm:~$ mkdir diagrams
ana@vm:~/diagrams$ node --version
v22.22.0
ana@vm:~/diagrams$ java -version
openjdk version "21.0.12.1" 2026-08-18
OpenJDK Runtime Environment (build 21.0.12.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 21.0.12.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
ana@vm:~/diagrams$ docker --version
Docker version 29.9.1, build dfc520d
```

Your versions may be newer within the same major version, which is fine. Older ones may not be: an
older Node.js may fail to install `mmdc`, and PlantUML was only tested here on Java 21.

**Every command in the rest of the lesson runs in that `diagrams` folder.**
