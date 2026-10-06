---
title: Installing Docker Engine, and who may use it
version: 1
---

**On Linux, install Docker Engine from Docker's own package repository, not from the distribution's
and not through Docker Desktop.** The distribution's packages lag behind and are sometimes named
differently; Docker's repository has the current engine, containerd, and the Compose and Buildx
plugins, built for each supported distribution.

## What an installation looks like

The lab machine was installed this way before the course began, and its packages and repository
file show the result:

```
ana@vm:~$ dpkg-query -W -f '${Package} ${Version}\n' docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
containerd.io 2.3.6-1~ubuntu.24.04~noble
docker-buildx-plugin 0.37.1-1~ubuntu.24.04~noble
docker-ce 5:29.8.2-1~ubuntu.24.04~noble
docker-ce-cli 5:29.8.2-1~ubuntu.24.04~noble
docker-compose-plugin 5.6.0-1~ubuntu.24.04~noble
ana@vm:~$ cat /etc/apt/sources.list.d/docker.list
deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu   noble stable
```

Five packages: the engine (`docker-ce`), the command (`docker-ce-cli`), containerd, and the two
plugins that provide `docker buildx` and `docker compose`. The repository line names Docker's
server, the machine's architecture, the Ubuntu release by its code name, `noble`, and the key that
signs the packages, so `apt` refuses anything not signed by Docker.

These are the commands that set that up on Ubuntu, from Docker's installation instructions. **They
were not run for this course**, because the lab already had the result, and Docker's documentation
is the place to check them before you run them, since the details change:

```sh
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

On a machine that boots with systemd, which is nearly every Linux server and laptop, the package
starts the daemon and enables it at boot; `sudo systemctl status docker` shows it running, and
`sudo systemctl start docker` starts it if it stopped. **The lab machine is the exception**: it
does not boot with systemd, so its daemon is started by the lab's own script, and `systemctl` says
as much:

```
ana@vm:~$ systemctl status docker
System has not been booted with systemd as init system (PID 1). Can't operate.
Failed to connect to bus: Host is down
```

## The docker group

By default only root may use the socket from the previous section. To let an ordinary user run
`docker` without `sudo`, the installation instructions add that user to the `docker` group, which
owns the socket. Ana is in it; Bruno, another user on the same machine, is not:

```
ana@vm:~$ id
uid=30033(ana) gid=30033(ana) groups=30033(ana),996(docker)
ana@vm:~$ getent group docker
docker:x:996:ana
```

```
ana@vm:~$ sudo -u bruno docker ps
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

The message is the socket refusing him, which is correct. **Before adding Bruno, understand what
the group grants.** Membership lets him ask `dockerd` for anything, and `dockerd` runs as root. One
request it accepts is "start a container with this host directory mounted inside". The lab has a
directory only root may read, with made-up salary figures in it. Ana cannot list it as herself, and
can read it through a container:

```
ana@vm:~$ ls /srv/payroll
ls: cannot open directory '/srv/payroll': Permission denied
ana@vm:~$ docker run --rm -v /srv/payroll:/p alpine:3.22 cat /p/salaries.csv
name,monthly_brl
ana,9800
bruno,10400
```

**Membership of the `docker` group is root on that machine, by another route.** That is not a bug
to be fixed; it is what a daemon running as root and accepting mounts means, and Docker's own
documentation warns that the group grants root-level privileges. So the group gets the same care as the `sudo` list: on a
shared server, only the people who would be trusted with root. Lesson 21 returns to the same
socket from the other direction, as something never to mount into a container.

**Rootless mode is the alternative** when that trust cannot be given: the daemon itself runs as an
ordinary user, inside a user namespace, so a container's root is that user and nothing more.
Docker publishes a setup tool for it in the `docker-ce-rootless-extras` package. It has limits, around ports below 1024
and some network and storage features, and Docker's documentation lists them; it was not set up
for this course.
