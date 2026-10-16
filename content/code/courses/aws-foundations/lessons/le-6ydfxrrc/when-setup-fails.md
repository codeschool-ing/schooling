---
title: When the setup fails
version: 1
---

A course is most often abandoned here, on an error about a tool the student has not finished
installing. These are the failures met while this lesson was recorded, in the order the setup meets
them, and what each one means. **Four of them were produced on purpose and are quoted as the machine
printed them; the others are described, and each says why.**

**The virtual environment was not created.** Ubuntu ships Python without the part that makes
virtual environments. `python3 -m venv` then stops with a message that begins *The virtual
environment was not created successfully because ensurepip is not available* and names the package
to install. The cure is `sudo apt-get install -y python3-venv`, the package the first block of the
setup installs. The failed attempt leaves a half-made `~/aws/venv` behind, so remove it with
`rm -rf ~/aws/venv` and run the third block again. **This one was not produced here**, because the
machine the lessons were recorded on has the package and the failure needs it absent. The `cloud`
course, lesson 1, quotes the whole message.

**`apt-get` says it could not get a lock.** Ubuntu installs its own updates in the first minutes
after a machine starts, and only one program may install packages at a time. Wait a few minutes and
run the command again. Deleting the lock file is the advice you will find online, and it is how a
package database gets damaged.

**`aws` is not found.** The tools are installed and this terminal does not know where:

```
ana@laptop:~$ aws --version
bash: line 1: aws: command not found
```

Every new terminal starts without `~/.local/bin` on its path and outside the virtual environment.
`source ~/aws/env.sh` puts both back, and the same line fixes a missing `moto_server`. On an Ubuntu
desktop the message may add a suggestion to install `aws-cli` from a package. Ignore it: the
version the course needs is already installed in `~/.local`.

**`aws` cannot connect to the endpoint.** The command line did what `env.sh` told it, and nothing
answered on port 4567:

```
ana@laptop:~/aws$ aws sts get-caller-identity

aws: [ERROR]: Could not connect to the endpoint URL: "http://localhost:4567/"
```

moto is not running. Start it in the first terminal with `moto_server -p 4567`, after reading
`env.sh` there too. If it is running and this still happens, look at the first terminal: a moto that
stopped with an error says why in its last lines.

**moto will not start because the port is in use.** A second copy, or any other program already
listening on 4567, gets this:

```
ana@laptop:~/aws$ timeout 10 moto_server -p 4567
Address already in use
Port 4567 is in use by another program. Either identify and stop that program, or start the server with a different port.
```

The likeliest owner is a moto you started earlier and left running, perhaps in a terminal hidden
behind another. Find it and press Ctrl+C there, or close that terminal. If another program really
needs 4567, any free port works, as long as `AWS_ENDPOINT_URL` in `env.sh` names the same one.

**The security token is invalid.** This is the failure worth understanding, because it is what
`env.sh` exists to prevent. Somebody unset the variable that points at moto, and the command line
did what it does by default:

```
ana@laptop:~/aws$ unset AWS_ENDPOINT_URL; aws sts get-caller-identity

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the GetCallerIdentity operation: The security token included in the request is invalid.
```

**That request went to AWS itself**, to the real security token service in São Paulo, carrying
moto's placeholder key. AWS refused it, because there is no such key, and nothing was created or
charged. With a real key in the environment the same mistake would have run the command against a
real account, which is why this course never asks you to keep one there. `source ~/aws/env.sh` sets
the variable again.

**The AWS installer fails with `Exec format error`, or `aws` will not run.** The zip file is built
for one kind of processor. A virtual machine on a Mac with Apple silicon, and most small Arm boards,
need the `aarch64` file the setup names, and `uname -m` prints which kind you have: `x86_64` or
`aarch64`. Delete `~/.local/aws-cli` and install from the other file. Not produced here, since the
recording machine is `x86_64`.

**A download of the price list stopped halfway.** The program in the last section of this lesson
writes each download to a file ending in `.part`, and gives it its real name only when it is
complete. A broken download is never mistaken for a finished one. Run the same command again and
it starts from the beginning. The files this lesson reads are about 1.5 MB each, so this is rare.
The EC2 file lesson 14 reads is some 290 MB, and that is where it happens.
