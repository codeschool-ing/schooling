---
title: When the setup fails
version: 1
---

A course is most often abandoned here, on an error about a tool the student has not finished
installing. These are the failures met while this lesson was recorded, in the order the setup meets
them, and what each one means. **Three of them were produced on purpose and are quoted as the
machine printed them; the others are described, and each says why.**

**The virtual environment was not created.** Ubuntu ships Python without the part that makes
virtual environments. `python3 -m venv` then stops with a message that begins *The virtual
environment was not created successfully because ensurepip is not available* and names the package
to install. The cure is `sudo apt-get install -y python3-venv`, the package the first block of the
setup installs. The failed attempt leaves a half-made `~/azure/venv` behind, so remove it with
`rm -rf ~/azure/venv` and run the second block again. **This one was not produced here**, because
the machine the lessons were recorded on has the package and the failure needs it absent.

**`apt-get` says it could not get a lock.** Ubuntu installs its own updates in the first minutes
after a machine starts, and only one program may install packages at a time. Wait a few minutes and
run the command again. Deleting the lock file is the advice you will find online, and it is how a
package database gets damaged.

**`pip` stops halfway with a network error.** The Azure CLI is around a hundred packages, fetched one
after another, and a dropped connection in the middle stops the whole install. Run the same `pip`
line again: what it already fetched is kept, and it carries on from where it stopped.

**`az` is not found.** The tools are installed and this terminal does not know where:

```
ana@laptop:~$ az version
bash: line 1: az: command not found
```

Every new terminal starts outside the virtual environment and without `~/.local/bin` on its path.
`source ~/azure/env.sh` puts both back, and the same line fixes a missing `terraform`. On an Ubuntu
desktop the message may add a suggestion to install `azure-cli` from a package. Ignore it: the
version the course needs is already in `~/azure/venv`.

**Terraform cannot execute.** The zip file was the one for another processor:

```
ana@laptop:~/azure$ terraform version
bash: line 1: /home/ana/.local/bin/terraform: cannot execute binary file: Exec format error
```

*Exec format error* means the file is a program for a different kind of processor, and the shell
cannot run it at all. It happens on an Arm machine given the `amd64` file and on an ordinary PC
given the `arm64` one. `uname -m` names yours: `x86_64` takes `amd64`, `aarch64` takes `arm64`.
Download the right zip and unpack it over the wrong one with the third block.

**`az bicep install` cannot download.** The Bicep compiler comes from `downloads.bicep.azure.com`,
and a network that blocks that address, which some company and university networks do, leaves the
command waiting and then failing with a connection error. **This one was not produced here**,
because the recording machine reaches the address. Microsoft also publishes the same file on GitHub,
under the releases of the `Azure/bicep` repository, as `bicep-linux-x64`: download it there, make
it executable with `chmod +x`, and put it at `~/azure/.azure/bin/bicep`, which is where the Azure CLI
looks.

**A command asks you to sign in.** Anything that needs Azure itself refuses straight away:

```
ana@laptop:~/azure$ az group list
ERROR: Please run 'az login' to setup account.
```

**This is not a failure of the lab; it is the lab.** Listing resource groups means asking Resource
Manager, Resource Manager needs a signed-in identity, and this course never signs in. The CLI
checked its own memory, found nobody, and stopped without sending a request. Where a lesson shows a
command like this one, it shows it to read, and says so.

**Do not run `az login` to make the message go away.** Without an account it opens a browser on
Microsoft's sign-in page, which offers to create one. With an account, the lab's CLI would be signed
in to it, and the next command typed from a lesson would run against a real subscription. The
section after this one says how to keep the two apart if you want both.

**Something else.** Run the same command again with `--debug` at the end, for the Azure CLI, or with
`TF_LOG=debug` in front of it, for Terraform. Both then print every step they take, and the error is
almost always in the last ten lines. Read those before searching for the message online, because the
first page of results is usually about a different version.
