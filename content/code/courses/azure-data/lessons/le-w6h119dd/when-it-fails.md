---
title: When the lab does not answer
version: 1
---

These are the failures met while this lesson was recorded, in the order a student meets them, with
what each one says and what it means. Most of them are one forgotten line.

**`az` is not found.** A new terminal starts without `~/.local/bin` on its path:

```
ana@laptop:~/azure$ PATH=/usr/bin:/bin; az version
bash: line 1: az: command not found
```

The second line under "Every time you open a terminal" puts it back, and `terraform` disappears the
same way.

**No connection string.** The terminal has the path and not the third line, so the command line does
not know which storage to talk to, and stops before sending anything:

```
ana@laptop:~/azure$ env -u AZURE_STORAGE_CONNECTION_STRING az storage container list -o table 2>&1 | tail -3
ERROR: Please provide storage account name or connection string.
```

**Azurite is not running.** The variable is set and nothing is listening on the port, because the
computer was restarted or the containers were stopped:

```
ana@laptop:~/azure$ docker compose stop azurite 2>&1 | tail -1
 Container azure-azurite-1 Stopped 
ana@laptop:~/azure$ az storage container list -o table 2>&1 | tail -3
ERROR: HTTPConnection(host='127.0.0.1', port=10000): Failed to establish a new connection: [Errno 111] Connection refused
ana@laptop:~/azure$ docker compose up -d 2>&1 | tail -1
 Container azure-azurite-1 Started 
```

`Connection refused` on port 10000 is Azurite, on 8081 the Cosmos DB emulator, on 1433 SQL Server
and on 5672 the Event Hubs emulator. Start the one the lesson names; it comes back empty.

**The port is taken.** Another program is already listening on one of the emulator's ports,
often an Azurite installed some other way, or the Visual Studio Code extension of the same name:

```
ana@laptop:~/azure$ docker compose up -d 2>&1 | tail -1
Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint azure-azurite-1 (9ea6bfe423cfdad65ee7939114da6f05842ec9ed176408f1ae71134c2e7806d4): failed to bind host port 127.0.0.1:10000/tcp: address already in use
```

`sudo ss -ltnp 'sport = :10000'` names the program holding it. Stop that one rather than changing the
port in `compose.yaml`: `UseDevelopmentStorage=true` always means 10000, 10001 and 10002.

**Docker answers `permission denied`.** This one was not recorded, because the machine the course was
recorded on runs everything as an administrator. Its message names `/var/run/docker.sock`, and it
means your user is not yet in the `docker` group: the `usermod` line of the first step takes effect
at the next login, not in the terminal you typed it in. Log out and back in, and `id` should list
`docker` among your groups.

**A command reached a real Azure.** This is the one to recognise, because it is the only failure here
that leaves your computer. Nothing in this course ever runs `az login`, and so nothing in it can
touch a subscription. If you have used the Azure command line before, with a real account, the login
is remembered in `~/.azure`. A command that names a real account, such as
`az storage container list --account-name` followed by a name of yours, will use it. **Every
storage command in this course takes its target from the connection string and names no account.**
If you ever see an account name in an answer that is not `devstoreaccount1`, stop, and run `az logout`
before going on.

**SQL Server stops a few seconds after starting.** `docker compose --profile sql logs sql` says why,
and on a laptop it is nearly always memory: SQL Server refuses to run with less than 2 GB. Give the
virtual machine or Docker Desktop more, or stop the Cosmos DB emulator while you use SQL Server; no
lesson needs both at once.
