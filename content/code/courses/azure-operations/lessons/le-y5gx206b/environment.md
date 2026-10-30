---
title: Your Azure, on your own computer
version: 1
---

This course is practised on your own computer, with the real Azure command line, `az`, and a few
programs Microsoft publishes for working without the cloud. There is no Azure subscription anywhere in
it, nothing is billed, and the platform runs nothing for you: every command in these lessons is one you
type in your own terminal. **Lesson 1 of `azure-foundations` builds this environment in full**, with
the three ways to have a terminal on Ubuntu 24.04 (installed, which it recommends; a virtual machine;
a shell rented online), what each costs your computer, and what to do when the setup fails. If you
took that course, you already have what follows. If you did not, or you deleted it since, this section
is the same setup in brief. Later lessons add three tools to it, each in the lesson that first needs it:
Bicep in lesson 4, Terraform in lesson 6 and a Kusto emulator in lesson 9.

## Building it

Four packages come from Ubuntu's archive. `docker.io` runs the emulators, and the last line lets you
use it without `sudo`; it takes effect at your next login, so log out and back in once:

```sh
sudo apt-get update
sudo apt-get install -y python3-venv curl unzip jq docker.io
sudo usermod -aG docker "$USER"
```

Then the Azure command line, version 2.91.0, into a virtual environment of its own in `~/azure/venv`.
It is a Python program, which is why it comes from `pip`; nothing here needs `sudo`:

```sh
mkdir -p ~/azure && cd ~/azure
python3 -m venv venv
venv/bin/pip install -q 'azure-cli==2.91.0'
```

The last step is **Azurite**, Microsoft's emulator for Azure Storage: blobs, queues and tables, on three
ports of your own computer. It runs in a container, and `--restart unless-stopped` brings it back
after a reboot:

```sh
docker run -d --name azurite --restart unless-stopped \
  -p 10000-10002:10000-10002 mcr.microsoft.com/azure-storage/azurite:3.37.0
```

## Every new terminal

Three lines point a terminal at the lab. The connection string `UseDevelopmentStorage=true` is a
shorthand every Azure storage tool understands: it means Azurite on this machine, with the well-known
development account `devstoreaccount1`. The second variable stops the command line sending usage data
to Microsoft:

```sh
cd ~/azure && source venv/bin/activate
export AZURE_STORAGE_CONNECTION_STRING=UseDevelopmentStorage=true
export AZURE_CORE_COLLECT_TELEMETRY=false
```

Then check it answers:

```
ana@laptop:~/azure$ az version
{
  "azure-cli": "2.91.0",
  "azure-cli-core": "2.91.0",
  "azure-cli-telemetry": "1.1.0",
  "extensions": {}
}
ana@laptop:~/azure$ docker ps --format "{{.Names}}  {{.Image}}  {{.Status}}"
azurite  mcr.microsoft.com/azure-storage/azurite:3.37.0  Up 2 seconds
ana@laptop:~/azure$ az storage container create --name smoke -o tsv
True
ana@laptop:~/azure$ az storage container list --query "[].name" -o tsv
smoke
ana@laptop:~/azure$ du -sh ~/azure/venv
707M	/home/ana/azure/venv
```

The first answer is the version. The container is Azurite, and the two storage commands created a
container called `smoke` in it and listed it back. The last line is the disk the command line takes,
which deleting `~/azure` gives back; the Azurite image adds about 600 MB, which `docker rmi` removes.

## When it does not answer

Three failures cover nearly every case. **The connection string is missing**, in a new terminal where
the three lines were not typed:

```
ana@laptop:~/azure$ az storage container list --query "[].name" -o tsv
ERROR: Please provide storage account name or connection string.
```

**Azurite is not running**. The command line retries for a while, then gives up on the address:

```
ana@laptop:~/azure$ az storage container list --query "[].name" -o tsv 2>&1 | tail -1
ERROR: HTTPConnection(host='127.0.0.1', port=10000): Failed to establish a new connection: [Errno 111] Connection refused
```

**An older Azurite is still on your machine.** Each release of the command line speaks a newer version
of the storage API, and Azurite refuses one it does not know rather than guessing. This is 3.35.0,
two releases behind the one this course pins:

```
ana@laptop:~/azure$ az storage container list --query "[].name" -o tsv 2>&1 | grep -m1 "API version"
ERROR: The API version 2026-04-06 is not supported by Azurite. Please upgrade Azurite to latest version and retry. If you are using Azurite in Visual Studio, please check you have installed latest Visual Studio patch. Azurite command line parameter "--skipApiVersionCheck" or Visual Studio Code configuration "Skip Api Version Check" can skip this error. 
```

Remove it with `docker rm -f azurite` and start the pinned image again. The message also suggests
skipping the version check; do not, because then the two programs disagree in silence.
