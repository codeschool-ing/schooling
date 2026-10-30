---
title: Your lab, in brief
version: 1
---

**This course is practised with the real Azure command line, the real Bicep compiler and the
software Microsoft ships for running Azure's pieces on a laptop, and with no Azure account.** Every
command in it runs on your own computer, costs nothing and reaches no subscription. The four Azure
courses of this school share one environment, and `azure-foundations` builds it in its lesson 1,
with each path explained. If you did that course and kept the lab, skip to the check near the end
of this section. If not, the steps are below in brief, and they build the same thing.

## Less than you might hope, and more than nothing

You might expect an imitation of Azure that accepts `az vm create` and hands back a machine id,
the way a mock server stands in for an API in a test suite. **There is no such thing for Azure.** Nothing that runs on a laptop answers Azure Resource Manager, the API every subscription,
virtual machine, scale set, AKS cluster, Container App and App Service plan is created through.
The next section says exactly what does run here and what each lesson does instead. For now, the
short version is three tools and Docker:

- **the Azure CLI**, `az`, which you will use for its help text, its offline lists and the one
  answer it gives without a subscription, a refusal;
- **the Bicep compiler**, which reads a declaration of Azure resources and checks every property
  against Azure's own resource types, offline;
- **Docker**, from the `docker` course, which runs the images Azure would run, and the emulators
  Microsoft publishes as images: storage, the Functions host, Service Bus and Event Hubs. Each
  lesson that needs one pulls it then.

## Three ways to have the lab

**Recommended: install it on Ubuntu 24.04**, on your own computer or in the virtual machine you
used for the `docker` course. The command line and the compiler take about 800 MB of disk, and the
images the later lessons pull take a few gigabytes more by the end. A **virtual machine**
(VirtualBox, or Multipass on Windows and macOS) costs those gigabytes plus 4 GB of memory while it
runs, because lesson 11 starts a small Kubernetes cluster inside it; it gives you a clean Ubuntu to
break. An **online environment** such as GitHub Codespaces needs no installation and already has
Docker, at the price of a monthly allowance of hours and storage that you should check before
relying on it. `azure-foundations` lesson 1 walks through all three; the commands below are the
same in each.

## The commands

The packages come from Ubuntu's own archive, and this is the only step that needs `sudo`. Docker is
the one the `docker` course installed, and is not repeated here:

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl unzip jq
```

The Azure CLI, version 2.91.0, in a virtual environment of its own so it touches nothing else on
the machine, and the Bicep compiler, version 0.48.1, which the CLI downloads into `~/.azure/bin`.
The `config` line switches off the usage reports the CLI would otherwise send to Microsoft:

```sh
mkdir -p ~/azure ~/.local/bin
cd ~/azure
python3 -m venv venv
venv/bin/pip install -q 'azure-cli==2.91.0'
venv/bin/az config set core.collect_telemetry=false
venv/bin/az bicep install --version v0.48.1
```

The install takes a few minutes, most of it `pip` fetching the CLI's several hundred packages. On
an Arm processor, which includes a virtual machine on a Mac with Apple silicon, the same commands
work: `pip` and `az bicep install` pick the Arm builds themselves.

**Every time you open a terminal to work**, these lines go first. They put the CLI and the compiler
on your path and choose São Paulo, `brazilsouth`, as the region any command that asks for one is
given:

```sh
cd ~/azure
source venv/bin/activate
export PATH="$HOME/.local/bin:$HOME/.azure/bin:$PATH"
export AZURE_DEFAULTS_LOCATION=brazilsouth
```

Your prompt gains `(venv)` at the front; the transcripts leave it out.

## Checking it answers

In your working terminal:

```
ana@laptop:~/azure$ az version
{
  "azure-cli": "2.91.0",
  "azure-cli-core": "2.91.0",
  "azure-cli-telemetry": "1.1.0",
  "extensions": {}
}
ana@laptop:~/azure$ bicep --version
Bicep CLI version 0.48.1 (cec7951cf6)
ana@laptop:~/azure$ docker --version
Docker version 29.9.2, build a82e528
```

Your Docker version may be a later one; anything from 27 on behaves the same in this course. Now
ask Azure something:

```
ana@laptop:~/azure$ az account show
ERROR: Please run 'az login' to setup account.
ana@laptop:~/azure$ az vm list-skus --size Standard_D2 --output table
ERROR: Please run 'az login' to setup account.
```

**That refusal is the correct answer, and it is the one you will see whenever a command needs a
subscription.** Nothing was sent anywhere: the CLI found no account signed in and stopped before
making a request. Do not run `az login` during this course. It would open a real Microsoft sign-in,
and every command written here assumes the CLI has nobody to act for.

## When it does not answer

Three failures cover nearly everything. **The terminal lines were not typed** in this terminal, so
nothing called `az` is on the path. A new terminal starts that way; this one was started with an
empty environment to show it:

```
ana@laptop:~/azure$ env -i HOME=$HOME bash --norc -c "az version"
bash: line 1: az: command not found
```

Type the four lines again. **The install stopped halfway**, usually because the network dropped
while `pip` was fetching: run the `pip install` line again, and it carries on from what it already
has. And **Docker is not running**, which the later lessons will show as a failure to reach the
daemon:

```
ana@laptop:~/azure$ DOCKER_HOST=unix:///run/nothing.sock docker info 2>&1 | tail -n 1
failed to connect to the docker API at unix:///run/nothing.sock; check if the path is correct and if the daemon is running: dial unix /run/nothing.sock: connect: no such file or directory
```

The path here is a socket that does not exist, chosen to make the message appear; on your machine
it names `/var/run/docker.sock`. `sudo systemctl start docker` starts the daemon, and the `docker`
course's installation lesson is the place to go back to if that does not help.

One check is worth doing before moving on, because a later lesson depends on it. The region line
is read by every command that takes a location and was not given one:

```
ana@laptop:~/azure$ echo $AZURE_DEFAULTS_LOCATION
brazilsouth
```

If it prints an empty line, the fourth terminal line was missed.
