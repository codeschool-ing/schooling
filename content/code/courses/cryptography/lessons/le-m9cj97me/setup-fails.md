---
title: When the setup fails
version: 1
---

**A setup that fails says so, and almost always in words that name the fix.** The five failures
below are the common ones, and each was made on purpose on the machine these lessons were recorded
on, so the messages are the real ones. **Read the message to the end before trying anything else.**

## The virtual environment is not created

A fresh Ubuntu Server has Python, and not the part of it that makes virtual environments. Skip
`python3-venv` in the `apt-get` line and this is what you get:

```
ana@lab:~$ python3 -m venv ~/lab/venv
The virtual environment was not created successfully because ensurepip is not
available.  On Debian/Ubuntu systems, you need to install the python3-venv
package using the following command.

    apt install python3.12-venv

You may need to use sudo with that command.  After installing the python3-venv
package, recreate your virtual environment.

Failing command: /home/ana/lab/venv/bin/python3
```

The message gives the fix: the package it names, with `sudo`. Install it, and run the same command
again. It reuses the half-made directory:

```sh
sudo apt-get install -y python3-venv
```

```
ana@lab:~$ python3 -m venv ~/lab/venv && echo created
created
```

Then carry on from the `pip install` line. If `pip install` itself stops on a network error, the
machine cannot reach the Python Package Index, where the two libraries come from. Check that the
machine reaches the internet at all, with `curl -I https://pypi.org`, and in a virtual machine that
its network adapter is attached.

## `vcrypt: command not found`

The lines added to `~/.bashrc` take effect in terminals opened after them. In the one that was
already open, the shell does not know where `vcrypt` is:

```
ana@lab:~$ vcrypt derive iv-a 16
bash: vcrypt: command not found
ana@lab:~$ source ~/.bashrc; vcrypt derive iv-a 16
ad5784f4861a73ec2a48dadd23983178
```

Read the file again into this terminal, or open a new one. The same cause makes `python3` in that
terminal Ubuntu's own rather than the lab's, and the versions check of the previous section says
so.

## `Permission denied`

A file is not a program until it is allowed to run. Forget `chmod +x` and the shell finds `vcrypt`
and refuses it:

```
ana@lab:~/lab$ vcrypt derive iv-a 16
bash: /home/ana/lab/bin/vcrypt: Permission denied
ana@lab:~/lab$ chmod +x bin/vcrypt; vcrypt derive iv-a 16
ad5784f4861a73ec2a48dadd23983178
```

## A paste that lost its indentation

Python reads indentation as structure, so a paste that dropped the spaces at the start of a line is
not a typo the program can ignore. Here the line under `if raw:` in `derive.py` arrived flush left:

```
ana@lab:~/lab$ vcrypt derive iv-a 16
  File "/home/ana/lab/tools/derive.py", line 12
    sys.stdout.buffer.write(data)
    ^
IndentationError: expected an indented block after 'if' statement on line 11
```

The message gives the file, the line and what it expected. Open the file, compare it with the block
in the lesson, and fix the line. If the editor added spaces of its own while you pasted, which some
editors do on every new line, paste into `nano` instead, or turn the editor's automatic indentation
off.

## A file with the wrong bytes

The digests at the end of the previous section are the check for everything a command wrote. Here
`data/slots.dat` was typed with four spaces after `free` instead of five:

```
ana@lab:~/lab$ sha256sum data/slots.dat; wc -c data/slots.dat
62dbb24783542ecf59afb8dfaa8ee562c95269b5d43ed6e65e7094e8f8d0dc39  data/slots.dat
490 data/slots.dat
```

The digest shares nothing with the right one, and `wc -c` says how far off the file is: 490 bytes
where there should be 512, which is 22 bytes short, one for each free slot. Every later transcript
that uses the file would then disagree with yours. **The fix is to run the command that wrote the
file again**, copied from the lesson rather than retyped.

## Starting again

Nothing in `~/lab` is precious. If it has got into a state you cannot explain, delete it and build it
again: `rm -rf ~/lab`, then this lesson's commands from `mkdir` on, leaving out the `cat >>
~/.bashrc`, whose lines are already there. The keys come back identical,
because they are derived from their labels. Later lessons add files of their own, and each one says
how to make them, so a lab rebuilt in lesson 9 needs the commands of lessons 1 to 8 again too. In a
virtual machine, a snapshot taken at the end of this lesson is a quicker way back.
