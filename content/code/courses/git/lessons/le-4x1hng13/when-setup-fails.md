---
title: When the setup does not work
version: 1
---

Everything in the last two sections can go wrong, and nearly every way it goes wrong prints a
sentence that says which. Read the sentence before anything else. Git's are usually exact, and the
line that starts with `fatal:` or `error:` is the one that names the problem.

## `command not found`

The shell, not Git, is answering: there is no program called that on this machine. Either Git is
not installed on the machine you are typing in, or the command is misspelt. Check which with
`git --version`. If that is also not found, go back to the path you chose two sections ago and
install it. Inside the virtual machine it is `sudo apt install git`.

## `not a git repository`

```
ana@vm:~$ git status
fatal: not a git repository (or any of the parent directories): .git
ana@vm:~$ cd first
ana@vm:~/first$ git status --short
A  notes.txt
```

Git is installed and working, and you are standing in the wrong folder. Every command that reads a
history looks for the hidden `.git` folder of a repository, first where you are and then in each
folder above, and in your home folder there is none. The prompt says where you are: `~` is home,
`~/first` is the repository. `cd` into it and the same command answers. This is the error you will
see most often in this course, and it is never more than that.

## `is not a git command`

```
ana@vm:~/first$ git comit -m "Start the notes"
git: 'comit' is not a git command. See 'git --help'.

The most similar command is
	commit
```

A typo after `git`, and Git suggests what you probably meant. The same message, with no
suggestion, has another cause: a Git older than 2.23 answering `git switch` or `git restore`. If
`git --version` prints an older number than that, install a newer one. The virtual machine path
has no such problem.

## A name without quotes

This one prints nothing at all, which is what makes it worth knowing:

```
ana@vm:~/first$ git config --global user.name Ana Souza
ana@vm:~/first$ git config --global user.name
Ana
ana@vm:~/first$ git config --global user.name "Ana Souza"
ana@vm:~/first$ git config --global user.name
Ana Souza
```

Without quotes the shell hands Git two words, and Git takes the first as the value and the second as
something else entirely. The command succeeds, and every commit from then on carries half a name.
**Asking for a setting with no value prints what it holds**, and that is the way to check any of
the four commands of the last section.

## An editor that is not there

```
ana@vm:~/first$ git config --global core.editor "code --wait"
ana@vm:~/first$ git commit
code --wait: 1: code: not found
error: There was a problem with the editor 'code --wait'.
Please supply the message using either -m or -F option.
```

`code --wait` is what many guides suggest, and it opens Visual Studio Code, which is not installed
inside a virtual machine. Git does what the setting says, fails, and makes no commit. The fix is to
set an editor the machine has: `git config --global core.editor nano`.

The opposite trap has no error message. With no editor set, Git may open vim, and a commit then
seems to hang on a screen full of `~`. It is waiting for a message. Press Esc, type `:q!` and
Enter to leave without committing, then set nano as above.

## Below all of these: the virtual machine itself

If the hypervisor refuses to start the machine with a message about `VT-x`, `AMD-V` or
virtualisation being disabled, **the processor can do it and the computer's firmware has the
feature switched off.** It is a setting in the BIOS or UEFI menu, reached by a key pressed while
the computer starts, and the manufacturer's site says which key. If you cannot change it, the
installed path or the online one needs no virtualisation at all.

## Starting again

Nothing here is precious yet. `rm -rf ~/first` removes the practice repository, `.git` folder and
all, and the last section makes it again in four lines. If the machine itself is in a state you
cannot explain, delete it in the hypervisor and make another. That is what a virtual machine is
for.
