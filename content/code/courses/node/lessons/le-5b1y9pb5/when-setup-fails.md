---
title: When the setup fails
version: 1
---

Installing a language is where many people stop, on an error message about something they have not
learnt yet. These are the failures that happen with this setup, with what each one means and the
transcript of it happening.

## `node: command not found`

You saw this one on purpose in the previous section. In a terminal of your own the message may be
longer, and on Ubuntu it may suggest `sudo apt install nodejs`. Do not take the suggestion: that is
the second Node of the section below. The shell decides its `PATH` when it opens,
and `~/.local/bin` is only on it if the folder existed by then. **Open a new terminal.** If a new
terminal still says it, `ls ~/.local/bin` should list `node`, `npm` and `npx`; if it lists nothing,
the `ln -s` line did not run. On a Mac the folder is not on the `PATH` at all until
`export PATH="$HOME/.local/bin:$PATH"` is added to `~/.zprofile`.

## The wrong processor

A file for the wrong processor unpacks without complaint and refuses to run. This is the `arm64`
build unpacked on an `x86_64` computer:

```
ana@dev:~$ mkdir ~/wrong && cd ~/wrong
ana@dev:~/wrong$ curl -fsSLO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-arm64.tar.xz
ana@dev:~/wrong$ tar -xJf node-v22.22.0-linux-arm64.tar.xz --strip-components=1
ana@dev:~/wrong$ ./bin/node --version
bash: line 9: ./bin/node: cannot execute binary file: Exec format error
```

**`Exec format error` means the program is for another processor.** Delete the folder, check
`uname -m` again, and take the other file. A Mac with an Apple chip and many recent Windows laptops
on Snapdragon are `arm64`; most other computers are `x86_64`.

## Two Nodes on one `PATH`

Ubuntu has a Node of its own in its archive, and installing it, or a program that depends on it,
puts a second `node` in `/usr/bin`. This machine had Ubuntu's `nodejs` package installed beside the
course's Node:

```
ana@dev:~$ which -a node
/home/ana/.local/bin/node
/usr/bin/node
/bin/node
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ /usr/bin/node --version
v18.19.1
```

`which -a` lists every `node` on the `PATH`, in the order the shell tries them. **The first one
wins**, and here it is still yours, because Ubuntu's `~/.profile` puts `~/.local/bin` in front.
`/usr/bin/node` and `/bin/node` are one file, since `/bin` is a link to `/usr/bin` on Ubuntu, and it
is Node 18, four major versions behind, and a script that calls `/usr/bin/node` by its full
path, or a terminal that does not read `~/.profile`, gets that one. If `node --version` prints
anything but 22, `which -a node` says which one you are talking to; `sudo apt remove nodejs` removes
Ubuntu's.

## `npm install -g` says `EACCES`

Nothing in this course installs anything globally, so you should not meet this. You will meet the
advice to fix it with `sudo npm install -g`, and it is wrong: it runs a package's install scripts as
root, which javascript lesson 21 showed is code somebody else wrote. With Node in your home
directory, as here, `-g` writes into `~/.local/node` and needs no `sudo` at all.

## The download fails

`curl` printing `Could not resolve host` means the computer has no DNS; inside a virtual machine
that is usually a VPN on the host in the way. A message about a certificate means something
between you and the internet is inspecting the connection, as some company and school networks do.
**Never answer that by turning certificate checking off.** Ask whoever runs the network for its
certificate, or install from a network that does not do this.

## And when nothing else works

Delete it and do it again. `rm -rf ~/.local/node ~/.local/bin/node ~/.local/bin/npm ~/.local/bin/npx`
removes this Node completely, and the section before this one puts it back in about a minute. It
feels like giving up, and it is what people who do this for a living do with a machine whose state
nobody can explain any more.
