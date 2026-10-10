---
title: Your lab, and three ways to have one
version: 1
---

**Every lesson of this course runs something on your own computer**: an API, a collection of
requests, a test suite in JavaScript or Java, and from lesson 14 an app on an Android emulator.
Nothing is hosted for you. This section says what the machine needs for the first half and three
ways to have it; lesson 14 adds what the second half needs, and the section after next says what to
do when the setup fails.

For lessons 1 to 6 the lab is small:

- **a terminal** running bash, with `curl` to send requests and `jq` to read JSON;
- **Node.js 22**, the JavaScript runtime. boxoffice, the API every lesson tests, is one file of
  JavaScript with no packages to install, and Newman in lesson 6 is a Node program too;
- **a text editor** you are comfortable in. Visual Studio Code is free and is what the course
  assumes when it says "open the file", but any editor that saves plain text will do.

Lesson 4 installs Postman, lesson 7 a Java Development Kit and Maven, and each says how.

## Three ways to have one

| path | what you get | what it costs | the transcripts |
|---|---|---|---|
| **installed** (recommended) | the tools on the computer you already use; on Windows, inside WSL | about 200 MB for Node, more for Java in lesson 7 | match as printed on Ubuntu 24.04 and WSL; close on a Mac |
| **a virtual machine** | Ubuntu Server 24.04, apart from your own system | a few gigabytes of disk and 2 GB of memory while it runs | match as printed |
| **online** | a Linux machine in the browser, GitHub Codespaces | nothing on your computer; hours from a monthly allowance | close; the mobile half cannot run there |

**Installed is the recommended path, and the reason is lesson 14.** The Android emulator is itself
a virtual machine, and it needs your processor's virtualisation support directly. Inside another
virtual machine it needs *nested* virtualisation, which many laptops and hypervisors do not offer,
and an emulator without it either refuses to start or runs too slowly to test anything. So the
second half of the course runs on your own system whatever you choose now, and doing the first half
there too means one set of tools rather than two.

What "installed" means depends on your system:

- **Linux.** Use your terminal as it is. The commands below are Ubuntu 24.04's; another
  distribution has the same tools under the same names in its own package manager.
- **Windows.** Install WSL, the Windows Subsystem for Linux, with Ubuntu 24.04 (`wsl --install -d
  Ubuntu-24.04` in a PowerShell opened as administrator, then a restart). WSL is a small Linux
  that shares your files and your network, and every command below runs inside it unchanged.
  Postman and Android Studio, which have windows, are installed on Windows itself.
- **macOS.** The Terminal app runs zsh, which accepts every command in this course. curl is already
  there. Install Node 22 with the installer from nodejs.org, and jq with Homebrew (`brew install
  jq`). None of the macOS steps was run for this course, so a version number may differ from yours.

**A virtual machine** is fine for lessons 1 to 13 if you prefer to keep the tools apart from your
own system: VirtualBox on Windows or Linux, UTM on a Mac, with an Ubuntu Server 24.04 image from
ubuntu.com. `virtualization` lesson 4 builds one step by step. Plan to install Android Studio on
your own system when lesson 14 arrives anyway.

**Online**, GitHub Codespaces gives you a Linux machine with a terminal in the browser, at no cost
to your computer. GitHub gives personal accounts a monthly allowance of hours and charges past it,
on terms it sets and can change. It was not run for this course. It is enough for lessons 1 to 13,
and it cannot run an Android emulator, which needs hardware a codespace does not expose.

## Building it

Everything below is typed in a terminal on Ubuntu 24.04 or in WSL. First the two small tools, from
Ubuntu's own packages:

```sh
sudo apt-get update
sudo apt-get install -y curl jq
```

Node comes from nodejs.org rather than from Ubuntu, because Ubuntu 24.04 ships Node 18, which is
past the end of its support and too old for the tools of lessons 6 and 15. These four lines
download the version every transcript was recorded with, unpack it into `/opt/node`, and tell your
shell where to find it:

```sh
curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz
sudo mkdir -p /opt/node
sudo tar -xJf node-v22.22.0-linux-x64.tar.xz -C /opt/node --strip-components=1
echo 'export PATH=/opt/node/bin:$PATH' >> ~/.bashrc
```

On an ARM computer, which is what a virtual machine on an Apple-silicon Mac is, write `arm64` where
the first and third lines say `x64`. The last line adds a sentence to `~/.bashrc`, which a terminal
reads when it opens, **so close the terminal and open a new one** before going on. In the new one,
the four tools answer:

```
ana@laptop:~$ node --version
v22.22.0
ana@laptop:~$ npm --version
10.9.4
ana@laptop:~$ curl --version | head -1
curl 8.5.0 (x86_64-pc-linux-gnu) libcurl/8.5.0 OpenSSL/3.0.13 zlib/1.3 brotli/1.1.0 zstd/1.5.5 libidn2/2.3.7 libpsl/0.21.2 (+libidn2/2.3.7) libssh/0.10.6/openssl/zlib nghttp2/1.59.0 librtmp/2.3 OpenLDAP/2.6.10
ana@laptop:~$ jq --version
jq-1.7
ana@laptop:~$ cd boxoffice
```

A newer Node 22 behaves the same for this course. Node 24 should too, and was not tried.

## What the transcripts print

Every transcript in the course was recorded on Ubuntu 24.04 and shows the prompt
`ana@laptop:~/boxoffice$`. Ana is the tester whose terminal they come from; yours shows your own user
and machine. Most of what boxoffice answers is the same on every machine, with two exceptions: the
`Date` header, which is the moment the request was made, and the tokens of lesson 3, which carry
the time they were issued.
