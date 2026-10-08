---
title: When the setup fails
version: 1
---

Most people who give up on a course like this one give up here, before the first real lesson, on an
error message about a machine they have only just built. These are the failures that actually
happen, in the order you would meet them, with what each one means. The three with a transcript
were made to happen on the machine this course was recorded on, so the words are the ones you will
see.

**The virtual machine will not start, and the message mentions virtualisation, VT-x, AMD-V or
SVM.** The processor's virtualisation support is switched off in the computer's firmware. It is a
setting in the BIOS or UEFI menu, usually under *Advanced* or *CPU configuration*, and it is off by
default on many laptops. No software can turn it on for you. On Windows, Hyper-V and the Windows
Subsystem for Linux can also hold it, and then VirtualBox runs slowly or not at all.

**`multipass launch` times out.** The first launch downloads an Ubuntu image of several hundred
megabytes, and a slow connection takes longer than its default wait. `multipass launch` accepts a
`--timeout` in seconds; give it 1800 and let it finish.

**Docker says permission denied.**

```
ana@obs:~/shop$ docker compose ps
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

Your user is not in the `docker` group yet, or it is and this shell started before it was. The
`usermod` of the first section only counts from your next login: `exit`, open the shell again, and
`id` should list `docker` among your groups. Putting `sudo` in front of every command also works,
and then every file Docker creates in `~/shop` belongs to root, which the next failure shows is
its own trouble.

**The download stops with `429 Too Many Requests`.** Docker Hub limits how many images one address
may download anonymously in a few hours, and the first `docker compose up` asks for fifteen. It
happened while this lab was built, on `prom/node-exporter`. The limit resets with time: wait a
quarter of an hour and run the same command again, and Docker keeps what it already has. Signing
in with `docker login` raises the limit, if you have a Docker account; the course does not need
one.

**The build fails while `pip install` runs.** The shop's image downloads its Python packages from
the Python Package Index as it is built, so the machine needs to reach `pypi.org`. Inside the
machine, `curl -sI https://pypi.org/simple/ | head -1` should answer `HTTP/2 200`. If it cannot,
the machine has no route out, which in a virtual machine usually means the host's VPN or firewall
is in the way.

**Grafana starts, and nobody can sign in.** This one says nothing when it happens:

```
ana@obs:~/shop$ docker compose up -d grafana
 Container shop-grafana-1 Creating 
 Container shop-grafana-1 Created 
 Container shop-grafana-1 Starting 
 Container shop-grafana-1 Started 
ana@obs:~/shop$ ls -ld .grafana-password
drwxr-xr-x 2 root root 4096 Oct  7 10:48 .grafana-password
ana@obs:~/shop$ cat .grafana-password
cat: .grafana-password: Is a directory
```

`compose.yaml` mounts `.grafana-password` into Grafana's container, and when that file does not
exist, **Docker creates a directory by that name instead**, owned by root, and starts Grafana
anyway. Grafana finds no password in it, and every lesson that reads the file fails on `cat`. The
fix is to remove the container and the directory and write the file this time:

```sh
docker compose rm -sf grafana
sudo rm -r .grafana-password
openssl rand -hex 12 > .grafana-password
docker compose up -d grafana
```

**A container will not start because its port is taken.**

```
ana@obs:~/shop$ docker compose up -d grafana
 Container shop-grafana-1 Starting
Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint shop-grafana-1 (b1aae8ecb42cfc33c668b625b9db7e0468d653d1655be5a271df7033f1376120): failed to bind host port 127.0.0.1:3000/tcp: address already in use
ana@obs:~/shop$ ss -ltn 'sport = :3000'
State  Recv-Q Send-Q Local Address:Port Peer Address:PortProcess
LISTEN 0      5          127.0.0.1:3000      0.0.0.0:*
```

Something else on the machine already listens on `127.0.0.1:3000`, and `ss` names the port. With
`sudo` in front, `ss -ltnp` names the program as well. It is often a development server of your
own, on an installed path rather than in a fresh virtual machine. Stop it, or change the left-hand
number of that service's `ports` line in `compose.yaml`, and then use your number wherever a
lesson types the original.

**A container keeps restarting, or shows `Exited (137)`.** 137 means the process was killed, and on
a lab machine the killer is almost always the kernel running out of memory. `free -h` shows what is
left. Give the virtual machine more memory, or stop what else is running on it.

**When something does not answer**, ask Docker before asking the program: `docker compose ps`
says whether the container is running, and `docker compose logs <service>` says what it printed
on the way up. The last lines name the reason almost every time.

**And when nothing else works**, start the lab again from nothing with the three commands at the end
of the previous section. If that is not enough, delete the machine and build it again: with
Multipass that is `multipass delete --purge obs`, then the commands of the first section and the
files of the next two, about half an hour. It feels like giving up. It is what professionals do with
a machine whose state nobody can explain any more, and it is the reason this course builds
everything from files you can read.
