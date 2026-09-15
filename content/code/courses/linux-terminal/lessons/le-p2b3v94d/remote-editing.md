---
title: Editing a file that is on another machine
version: 1
---

The whole reason for this lesson is that the file is somewhere else. There are
four ways to deal with that and only one of them is "learn vim".

## One: edit it there

```sh
ssh web01
vim /etc/nginx/nginx.conf
```

**This is what this lesson has been teaching**, and it is the right answer when
the change is small, when you are already on the machine, and when what is
installed there is what you have.

The cost is that your editor configuration is not there, which is the argument in
section 201 for learning the plain editor.

## Two: copy it, edit it, copy it back

```sh
scp web01:/etc/nginx/nginx.conf .
vim nginx.conf
scp nginx.conf web01:/etc/nginx/nginx.conf
```

**Three steps, and two of them lose things.** `scp` writes the file as you, with
your umask, so the owner and the mode are the ones on your machine and not the
ones the service needs. Section 60's `chown` and section 62's `umask` both apply,
and neither is obvious afterwards.

It is fine for a file you own and wrong for anything under `/etc`.

## Three: mount the remote filesystem

```sh
sshfs web01:/etc/nginx /mnt/nginx      # needs sshfs installed locally
vim /mnt/nginx/nginx.conf
fusermount -u /mnt/nginx
```

`sshfs` presents a remote directory as a local one over the ssh connection you
already have. Your editor, your configuration, the remote file — and the
permissions are the remote machine's, because that is where the write happens.

**It is slow on a high-latency link** — every save is a round trip, and some
editors stat the file constantly — and it needs a package on your machine.

## Four: let the editor do it

Both of the big editors can open a remote path directly:

```vim
:e scp://web01//etc/nginx/nginx.conf      " vim, via netrw
```

```
C-x C-f /ssh:web01:/etc/nginx/nginx.conf   ; emacs, via tramp
```

**Emacs' `tramp` is the one that is genuinely good at this.** It keeps a
connection open, it handles `sudo` on the far end
(`/ssh:web01|sudo:root@web01:/etc/…`), and the buffer behaves like any other. It
is the single strongest practical argument for emacs in this lesson, and it is
why it is mentioned twice.

Vim's `netrw` works and is less pleasant: each save is a separate `scp`, and
anything that depends on the directory around the file — file browsing, project
plugins — does not follow.

Visual Studio Code's remote extension is a fifth way and is outside this
course's scope; it is doing roughly what `sshfs` does, with a helper it installs
on the far end.

## Which to use

| | |
|---|---|
| one line in a config file, on a server | **ssh and edit it there** |
| a file you own, on a machine you control | any of them |
| a long session in somebody else's codebase | `sshfs`, or the editor's own |
| under `/etc`, always | edit it there, with `sudoedit` |

## The better question

**Why are you editing a file on a server by hand at all?**

Section 80's unit files, lesson 13's crontabs, and every `/etc` file you are
about to change have the same problem: the change lives on one machine, nobody
else knows about it, and the next rebuild loses it.

| | |
|---|---|
| a configuration manager | Ansible, Puppet, Salt — the file comes from a repository |
| a container image | the config is in the image, and the machine is disposable |
| a package | the file ships with the software |
| by hand, in vim | **an emergency, or a machine nobody owns** |

That is not an argument against this lesson. **Every one of those systems fails
in a way that leaves you on the machine with an editor**, and the incident is
exactly when you need to change one line and be sure you changed nothing else.

Learn the editor. Then arrange not to need it.
