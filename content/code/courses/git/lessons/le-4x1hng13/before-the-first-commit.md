---
title: Before the first commit — install Git and tell it who you are
version: 1
---

Lesson 2 starts making commits, and a fresh machine is not ready for one. This section gets it
ready. It takes four commands, and each one is here because of something Git will otherwise do to
you.

## Is it there?

```
ana@vm:~$ git --version
git version 2.43.0
```

Anything from 2.23 on has every command this course uses; that release, from 2019, is where
`git switch` and `git restore` arrived. If the shell answers
`command not found` instead, install it. On Debian and Ubuntu that is `sudo apt install git`. On
macOS, typing `git` in a terminal offers to install Apple's developer tools, which include it. On
Windows, the installer from git-scm.com brings Git and a terminal called Git Bash, and every command
in this course works in that terminal.

## What Git says the first time

Here is a fresh account making a repository and trying to save a first version, before anybody has
set anything:

```
ana@vm:~$ mkdir first && cd first
ana@vm:~/first$ git init
hint: Using 'master' as the name for the initial branch. This default branch name
hint: is subject to change. To configure the initial branch name to use in all
hint: of your new repositories, which will suppress this warning, call:
hint: 
hint: 	git config --global init.defaultBranch <name>
hint: 
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint: 
hint: 	git branch -m <name>
Initialized empty Git repository in /home/ana/first/.git/
ana@vm:~/first$ echo 'first line' > notes.txt
ana@vm:~/first$ git add notes.txt
ana@vm:~/first$ git commit -m "Start the notes"
Author identity unknown

*** Please tell me who you are.

Run

  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"

to set your account's default identity.
Omit --global to set the identity only in this repository.

fatal: unable to auto-detect email address (got 'ana@vm.(none)')
```

Two complaints, and **the second is a refusal**: no commit was made. You met the reason in the last
two sections. Every commit records an author, and Git will not invent one. It tried — `ana@vm.(none)`
is the account name and the machine's name glued together — and rightly decided that is not an
address.

**Both messages tell you exactly what to type.** Read them, because Git's messages are usually that
good, and a habit of skipping them is expensive later.

## Telling it

```
ana@vm:~$ git config --global user.name "Ana Souza"
ana@vm:~$ git config --global user.email "ana@example.com"
ana@vm:~$ git config --global init.defaultBranch main
ana@vm:~$ git config --global core.editor nano
```

None of them prints anything, which is how a command says it worked. **`--global` means *for my
account, in every repository*.** Without it, the setting applies to the repository you are standing
in and nowhere else — useful for a work repository that should carry your work address.

**The name and the address are not a login.** There is no password and nothing checks them. They
are copied into every commit you make, and a commit is copied into every clone, so treat them as
public and permanent. If you would rather not publish your personal address, GitHub and GitLab each
give you a private relay address to use here, and link the commits to your account through it.

## What that wrote

Those four commands edited one small text file in your home directory, and it is worth reading once
so that it is not a mystery later:

```schooling-example
{"language": "ini", "file": ".gitconfig", "parts": [{"code": "[user]\n\tname = Ana Souza\n\temail = ana@example.com", "note": "Who you are, copied into every commit you make. A section in brackets, then its settings, one per line. The tab is Git's own indentation."}, {"code": "[init]\n\tdefaultBranch = main", "note": "The name of the first branch in every new repository — what the hint asked for. `main` is what GitHub and GitLab name theirs now. Branches are lesson 5."}, {"code": "[core]\n\teditor = nano", "note": "The editor Git opens when it needs you to write something longer than `-m` allows. Left unset it is whatever the system chose, often vim, which is hard to leave the first time. nano shows its keys along the bottom of the screen."}]}
```

Git reads that file every time it runs. You can edit it by hand, and it will take effect on the next
command. Asking Git for the list gives the same four settings, one per line:

```
ana@vm:~$ git config --global --list
user.name=Ana Souza
user.email=ana@example.com
init.defaultbranch=main
core.editor=nano
```

The `defaultBranch` of the file comes back as `defaultbranch`. The names of settings ignore case, so
both spellings are the same setting, and Git prints the lower-case form.

That is everything lesson 2 needs. It starts with the commit Git just refused, and with what
`git add` did before it.
