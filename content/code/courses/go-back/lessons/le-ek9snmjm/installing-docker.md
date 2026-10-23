---
title: A container engine on your machine
version: 1
---

This lesson ends with boxoffice running in a container, which needs a container engine: the program that
builds images and runs containers from them. **Docker Engine** is the one every transcript here used, and
the `docker` course explains it in lessons 1 to 4 and installs it in lessons 5 and 6; if you took that course,
check the two commands at the end of this section and move on. This section is the setup in brief.

## Three places to run it

| path | what it costs your computer | for this lesson |
|---|---|---|
| **installed**, Docker Engine on the Ubuntu you have used since lesson 1 (recommended) | five packages from Docker's repository, a daemon running as root, and disk for every image you pull or build | every command runs as printed |
| **a virtual machine**: Docker Desktop on macOS or Windows, or Docker Engine inside the VM of lesson 1 | Desktop runs its own Linux VM, a few gigabytes of disk and the memory you give it; Desktop's licence asks larger companies for a paid subscription | the same commands; on macOS with Apple chips the host is `arm64`, which section 08 is about |
| **online**, an Ubuntu server rented by the hour from any provider | money for every hour it runs, and nothing on your computer | the same commands, typed over `ssh` |

**Install it on Linux if you can.** On macOS and Windows, a container is a Linux process and needs a Linux
kernel, so every path there is a virtual machine; Docker Desktop hides it, and the Ubuntu VM of lesson 1
makes it visible. **Podman** is the other engine worth knowing: Ubuntu packages it as `podman`, it has no
daemon, it runs rootless by default, and `podman build` and `podman run` take the same Dockerfile and
nearly the same flags. This course did not run it.

## Installing Docker Engine on Ubuntu

Docker's own repository, not Ubuntu's `docker.io` package, which lags behind. These are the commands from
Docker's installation instructions that the `docker` course gives in lessons 5 and 6; they were not run again for
this course, because the lab machine already had the result, and Docker's documentation is the place to
check them first, since the details change:

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

The result, on the lab machine:

```
ana@vm:~$ dpkg-query -W -f '${Package} ${Version}\n' docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
containerd.io 2.3.6-1~ubuntu.24.04~noble
docker-buildx-plugin 0.37.1-1~ubuntu.24.04~noble
docker-ce 5:29.8.2-1~ubuntu.24.04~noble
docker-ce-cli 5:29.8.2-1~ubuntu.24.04~noble
docker-compose-plugin 5.6.0-1~ubuntu.24.04~noble
```

The engine, its command, containerd underneath them, and the two plugins that give `docker buildx` and
`docker compose`. On a machine that boots with systemd, which is nearly every Linux machine, the package
starts the daemon and enables it at boot. The next section is the check, and what to do when it fails.
