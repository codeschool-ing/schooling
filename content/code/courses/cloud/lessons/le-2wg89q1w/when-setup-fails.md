---
title: When the setup fails
version: 1
---

A course is most often abandoned here, on an error about a tool the student has not finished
installing. These are the failures met while this lesson was recorded, in the order the setup meets
them, and what each one means.

**The virtual environment was not created.** Ubuntu ships Python without the part that makes
virtual environments, and this is what `python3 -m venv` says without it:

```
ana@laptop:~/cloud$ python3 -m venv ~/cloud/venv
The virtual environment was not created successfully because ensurepip is not
available.  On Debian/Ubuntu systems, you need to install the python3-venv
package using the following command.

    apt install python3.12-venv

You may need to use sudo with that command.  After installing the python3-venv
package, recreate your virtual environment.

Failing command: /home/ana/cloud/venv/bin/python3
```

The message names the cure: `sudo apt-get install -y python3-venv`, the package the first block of
the setup installs. The failed attempt left a half-made `~/cloud/venv` behind, and the rest of the
block may have cloned cloud-init before it stopped, so remove both with
`rm -rf ~/cloud/venv ~/cloud/cloud-init` and run the whole third block of the setup again.

**`apt-get` says it could not get a lock.** Ubuntu installs its own updates in the first minutes after
a machine starts, and only one program may install packages at a time. Wait a few minutes and run the
command again. Deleting the lock file is the advice you will find online, and it is how a package
database gets damaged.

**`aws` is not found.** The tools are installed and the shell does not know where:

```
ana@laptop:~/cloud$ aws --version
bash: line 1: aws: command not found
```

Every new terminal starts without `~/.local/bin` and without the virtual environment. The two lines
under "Every time you open a terminal" in the setup put both back; the same happens with
`moto_server` and `cloud-init`, and the same two lines fix it.

**The AWS installer fails with `Exec format error`, or `aws` will not run.** The zip file is built for
one kind of processor. A virtual machine on a Mac with Apple silicon, and most small Arm boards, need
the `aarch64` file the setup names, and `uname -m` prints which kind you have: `x86_64` or
`aarch64`. Delete `~/.local/aws-cli` and install from the other file.

**A download of the price list stopped halfway.** The EC2 files are hundreds of megabytes, and a
connection that drops partway leaves Python with fewer bytes than the server announced. It happened
once while this course was recorded, and the last line of the error was:

```
urllib.error.ContentTooShortError: <urlopen error retrieval incomplete: got only 291821784 out of 292285717 bytes>
```

Run the same command again. The program writes each download to a file ending in `.part` and gives it
its real name only when it is complete, so a broken download is never mistaken for a finished one,
and the next run starts it again from the beginning.

**The price sheet prints its header and then the word `Killed`.** The system ran out of memory and
stopped the program, which is what Linux does when a process asks for more than the machine has. The
EC2 block needs about 2.2 GB of its own. Close other programs; in a virtual machine, give it 4 GB of
memory. If neither is possible, every price the lessons quote is printed in the lesson itself, so the
EC2 block is the one command in this course you can read rather than run.

**moto will not start because the port is in use.** Lesson 5 starts `moto_server` on port 5000. A
second copy, or any other program already listening there, gets this:

```
ana@laptop:~/cloud$ timeout 10 moto_server -p 5000 2>&1 | tail -3
Address already in use
Port 5000 is in use by another program. Either identify and stop that program, or start the server with a different port.
```

The likeliest owner is a `moto_server` you started earlier and left running, and `jobs` in the same
terminal lists it. Stop it with `kill %1`, or close the terminal that started it. On a Mac, port 5000
is also where the system's AirPlay receiver listens. Any free port works, if you use the same number
in `AWS_ENDPOINT_URL` in lesson 5.
