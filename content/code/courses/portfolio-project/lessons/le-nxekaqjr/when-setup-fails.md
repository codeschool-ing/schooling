---
title: When the setup fails
version: 1
---

Setting up is where most people who give up on a course give up, usually over an error that takes a
minute to fix once somebody says what it means. These are the ones that come up, and what to do.

**The terminal does not know the command.** Asking for `git --version` answers that `git` is not found,
or *is not recognized*. Either it is not installed, or it was installed while the terminal was open and
the terminal has not looked again. Close every terminal, open a new one, and ask again; on Windows, use
Git Bash rather than the older Command Prompt. On macOS, the first `git` you type may open a window
offering to install the developer tools, which is the same `xcode-select --install`: accept it and wait.

**git refuses the first commit.** This is what it says when the identity was never set:

```
ana@laptop:~$ mkdir project && cd project && git init -q && echo "# project" > README.md
ana@laptop:~/project$ git add README.md && git commit -m "Say what the project is for"
Author identity unknown

*** Please tell me who you are.

Run

  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"

to set your account's default identity.
Omit --global to set the identity only in this repository.

fatal: unable to auto-detect email address (got 'ana@laptop.(none)')
```

The message holds its own fix. Type the three `git config --global` lines of the previous section, with
your name and address, and commit again. Nothing was lost: `git add` had already staged the file, and the
commit only needed a name to put on it.

**The branch is called `master`.** A repository made before `init.defaultBranch` was set keeps the name it
was born with:

```
ana@laptop:~/project$ git commit -q -m "Say what the project is for" && git branch --show-current
master
ana@laptop:~/project$ git branch -m main && git branch --show-current
main
```

`git branch -m` renames the branch you are on. Do it before the first push; after it, the hosting site
has a branch by the old name as well, and renaming both is a longer job.

**The virtual machine will not start.** A hypervisor needs the processor's virtualisation feature, and
some computers ship with it switched off in the firmware settings, called *Intel VT-x*, *AMD-V* or *SVM*
there. VirtualBox says so when it refuses to start the machine. Turning it on is a setting in the
firmware, reached by a key pressed while the computer starts, which differs by maker; the maker's support
page names it.

**The codespace is not there any more.** A codespace that sits unused is stopped, and later deleted, on
GitHub's schedule. What you committed and pushed is safe in the repository; what you did not push went
with it. Push at the end of every session, which is good practice on any path.

If the error you have is none of these, copy its **first** line into a search engine, in quotes. The
first line is the cause; the lines after it are usually consequences.
