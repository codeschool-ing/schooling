---
title: When the setup fails
version: 1
---

A course is most often abandoned here, on an error from a tool that is not quite installed yet. These
are the failures met while this lesson was recorded, in the order the setup meets them. **Four were
produced on purpose and are quoted as the machine printed them; the others are described, and each
says why.**

**The virtual environment was not created.** Ubuntu ships Python without the part that builds
virtual environments, and `python3 -m venv` then stops with a message beginning *The virtual
environment was not created successfully because ensurepip is not available*, naming the package to
install. Install it with `sudo apt-get install -y python3-venv`, which the first block already does,
remove the half-made directory with `rm -rf ~/aws/venv`, and run the third block again. **Not
produced here**: the recording machine has the package, and the failure needs it absent.

**`apt-get` cannot get a lock.** Ubuntu installs its own updates in the first minutes after a
machine starts, and only one program may install packages at a time. Wait a few minutes and run it
again. Deleting the lock file, the advice you will find online, is how a package database gets
damaged.

**`aws` is not found.** The tools are installed and this terminal does not know where:

```
ana@laptop:~$ aws --version
bash: line 1: aws: command not found
```

Every new terminal starts without `~/.local/bin` on its path and outside the virtual environment.
`source ~/aws/env.sh` puts both back, and the same line fixes a missing `moto_server`.

**`aws` cannot connect to the endpoint.** The command line did what `env.sh` told it to, and nothing
answered on port 4567:

```
ana@laptop:~/aws$ aws sts get-caller-identity

aws: [ERROR]: Could not connect to the endpoint URL: "http://localhost:4567/"
```

moto is not running. Start it in the first terminal, after reading `env.sh` there too. If it is
running and this still happens, look at that terminal: a moto that stopped with an error says why in
its last lines.

**moto will not start because the port is in use.** A second copy, or any other program already
listening on 4567, gets this:

```
ana@laptop:~/aws$ timeout 10 moto_server -p 4567
Address already in use
Port 4567 is in use by another program. Either identify and stop that program, or start the server with a different port.
```

The likeliest owner is a moto you started earlier and left running in a terminal hidden behind
another. Press Ctrl+C there, or close that terminal. If something else really needs 4567, any free
port works, as long as `AWS_ENDPOINT_URL` in `env.sh` names the same one.

**The security token is invalid.** This is the failure worth understanding, because it is the one
`env.sh` was written to make harmless. The variable that points at moto was unset, and the command
line did what it does by default:

```
ana@laptop:~/aws$ unset AWS_ENDPOINT_URL; aws sts get-caller-identity

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the GetCallerIdentity operation: The security token included in the request is invalid.
```

**That request went to AWS itself**, to the real security token service, carrying moto's
placeholder key. AWS refused it, since no such key exists, and nothing was created or charged. With
a real key in the environment, the same slip would have run the command against a real account.
That is the whole case for the `test` values: **a mistake should fail, not succeed somewhere you did
not mean**. `source ~/aws/env.sh` sets the variable again.

**The installer fails with `Exec format error`.** The zip file is built for one kind of processor,
and `uname -m` says which you have: `x86_64` or `aarch64`. Delete `~/.local/aws-cli` and install from
the file the setup names for the other one. Not produced here, since the recording machine is
`x86_64`.
