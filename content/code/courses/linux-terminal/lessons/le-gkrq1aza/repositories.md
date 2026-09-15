---
title: Repositories, and why `update` is not `upgrade`
version: 1
---

A repository is a web server with packages on it and an **index** describing them. Your machine
holds a list of repositories, a copy of each index, and nothing else until you ask for something.

That is the whole model, and it explains the command people get wrong first:

| | |
|---|---|
| `apt update` | fetch the **indexes** again. Changes no installed package |
| `apt upgrade` | install newer versions of what you already have |

**`update` downloads a catalogue; `upgrade` acts on it.** Running `upgrade` without `update` uses
yesterday's catalogue and reports nothing to do, which is where "but I did update it" comes from.

## Where the list lives

```
root@vm:~# ls /etc/apt/sources.list.d/
deadsnakes-ubuntu-ppa-noble.sources  docker.list  ondrej-ubuntu-php-noble.sources  ubuntu.sources
root@vm:~# cat /etc/apt/sources.list.d/docker.list
deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu   n
oble stable
```

One line, and every part of it matters:

| | |
|---|---|
| `deb` | binary packages. `deb-src` would be source |
| `[arch=amd64 signed-by=…]` | options: which architecture, and **which key signs this** |
| `https://download.docker.com/linux/ubuntu` | the server |
| `noble` | the **suite** — here, the Ubuntu release it is for |
| `stable` | the **component**. Ubuntu's own are `main`, `universe`, `restricted`, `multiverse` |

On Ubuntu's own sources the four components are worth knowing: `main` is supported by Canonical,
`universe` is maintained by the community, `restricted` is drivers that are not free, `multiverse`
is everything else. **`cowsay` in section 104 came from `universe`**, which is the honest answer to
"is this supported" for an enormous amount of what people install.

The newer `.sources` files hold the same fields one per line instead of one per file. Same
information, easier to read, and you will meet both.

## `signed-by`, which is the whole of repository security

Every index is signed. Your machine checks the signature against a key it already has, and refuses
the repository if it cannot. **That is why adding a third-party repository is two steps** — the
key, then the source line — and why the instructions you copy from a vendor's page always have
both.

`signed-by=` pins one key to one repository, which is the part that changed and matters: a key in
the old global `trusted.gpg` could sign packages for *any* repository on the machine. Now
`/etc/apt/keyrings/docker.asc` vouches for Docker's repository and nothing else.

**You will see `apt-key add` in older instructions on the internet. It is deprecated and it is the
thing `signed-by` replaced.** If a page tells you to run it, the page is old enough that the rest
of it is worth checking too.

## `apt update`, read line by line

```
root@vm:~# apt update
Err:1 https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu noble InRelease
  403  Forbidden [IP: 185.125.189.187 443]
Err:2 https://ppa.launchpadcontent.net/ondrej/php/ubuntu noble InRelease
  403  Forbidden [IP: 185.125.189.187 443]
Get:3 https://download.docker.com/linux/ubuntu noble InRelease [48.5 kB]
Hit:4 http://archive.ubuntu.com/ubuntu noble InRelease
Get:5 http://archive.ubuntu.com/ubuntu noble-updates InRelease [126 kB]
Get:6 http://security.ubuntu.com/ubuntu noble-security InRelease [126 kB]
Hit:7 http://archive.ubuntu.com/ubuntu noble-backports InRelease
Get:8 http://archive.ubuntu.com/ubuntu noble-updates/main amd64 Packages [1566 kB]
Get:9 http://archive.ubuntu.com/ubuntu noble-updates/universe amd64 Packages [2152 kB]
Reading package lists... Done
E: Failed to fetch https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu/dists/noble/InRelease  403
  Forbidden [IP: 185.125.189.187 443]
E: The repository 'https://ppa.launchpadcontent.net/deadsnakes/ppa/ubuntu noble InRelease' is no lon
ger signed.
N: Updating from such a repository can't be done securely, and is therefore disabled by default.
N: See apt-secure(8) manpage for repository creation and user configuration details.
E: Failed to fetch https://ppa.launchpadcontent.net/ondrej/php/ubuntu/dists/noble/InRelease  403  Fo
rbidden [IP: 185.125.189.187 443]
E: The repository 'https://ppa.launchpadcontent.net/ondrej/php/ubuntu noble InRelease' is no longer
signed.
N: Updating from such a repository can't be done securely, and is therefore disabled by default.
N: See apt-secure(8) manpage for repository creation and user configuration details.
```

Three words carry the whole listing:

| | |
|---|---|
| `Hit` | unchanged since last time; nothing downloaded |
| `Get` | changed, so it was fetched, with the size |
| `Err` | it did not work, and everything after `E:` is why |

**And this run has two real failures in it**, which is luckier than it sounds, because this error is
one of the two you will actually meet.

What happened here is specific: this machine reaches the network through a proxy that returns `403
Forbidden` for those two PPAs. apt could not fetch `InRelease` — the signed file — at all, and
`no longer signed` is what apt says when the signed index is missing, whatever the reason. **The
message names the consequence, not the cause.**

That is worth knowing because the same four lines appear when the cause is entirely different: a
repository whose signing key expired, a mirror serving an unsigned copy, a URL that now redirects
to an error page. The message is identical and the fix is not.

So when you see `is no longer signed`, **read the `E: Failed to fetch` line above it first**. `403`
and `404` are network answers and a key problem is not. A key problem shows `NO_PUBKEY` and a
hexadecimal key id instead.

**And notice what did not happen: nothing was installed or upgraded.** Two repositories failed,
seven worked, and the machine is exactly as it was. `update` only ever writes to a cache.

## The rest of the vocabulary

```
apt update                 # refresh the indexes
apt upgrade                # newer versions of what is installed
apt full-upgrade           # the same, but allowed to remove things to do it
apt list --upgradable      # what upgrade would do, before doing it
```

**`apt list --upgradable` is the one to run first**, every time. It is the dry run, it is instant,
and it turns "168 not upgraded" from a number into a list you can read.

`full-upgrade` — `dist-upgrade` in older instructions — differs from `upgrade` in one way and it is
important: plain `upgrade` will never remove a package to satisfy an upgrade, and `full-upgrade`
will. On a server, run `upgrade`, read what it held back, and decide about those by hand.

On the rpm side the same split exists with different words: `dnf check-update` lists, `dnf upgrade`
acts, and there is no separate `update` step because dnf refreshes its metadata on its own when the
cache is stale. Section 112 is that difference in full.
