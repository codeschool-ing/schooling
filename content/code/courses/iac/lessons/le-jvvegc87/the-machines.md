---
title: Three machines to configure
version: 1
---

Ansible needs machines that run, and moto has none: it emulates the AWS API and starts nothing. So
in this lesson the shop's servers are **three Docker containers on your computer**, `web1`, `web2`
and `db1`, each one an Ubuntu 24.04 with an SSH server, Python, and a user `deploy` who may use
`sudo`. That is all Ansible asks of a machine, and it is what a fresh cloud server gives you too.
Packages inside them come from the real Ubuntu archive, and nginx in them serves real pages.

This is where the virtual machine lesson 1 recommends pays off. Inside a Linux VM, or on Linux
itself, a container's address is reachable from your shell. With Docker Desktop on macOS or Windows
it is not, because the containers live in a hidden VM of Docker's own, and the SSH connections this
lesson makes would have nowhere to go.

## Installing Docker and Ansible

Docker from Ubuntu's own package, and Ansible with `pipx`, which gives a Python program an environment
of its own the way `~/iac-venv` does for moto:

```sh
sudo apt-get install -y docker.io pipx
sudo usermod -aG docker $USER
pipx ensurepath
pipx install ansible-core==2.21.4
```

Then **log out and back in**, or close the VM's terminal and open a new one. Both of the middle two
lines change something your current session read when it started: `usermod` adds you to the group
allowed to talk to Docker, and `ensurepath` puts `~/.local/bin`, where `pipx` installs, on your
`PATH`. Before you log out again, this is what Docker says to somebody not in its group:

```
ana@laptop:~$ docker ps
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

## The machines

Two files, in a directory of their own. The first, `~/hosts/Dockerfile`, describes one machine:

```dockerfile
# ~/hosts/Dockerfile: an Ubuntu 24.04 server with sshd, Python 3 and a user
# `deploy` who may use sudo without a password, which is what Ansible needs.
FROM ubuntu:24.04
RUN apt-get update -q && apt-get install -yq openssh-server python3 sudo && rm -rf /var/lib/apt/lists/* \
 && useradd -m -s /bin/bash deploy && echo 'deploy ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/deploy \
 && mkdir -p /run/sshd /home/deploy/.ssh && chown deploy: /home/deploy/.ssh
CMD ["/usr/sbin/sshd", "-D", "-e"]
```

The second, `~/hosts/up.sh`, builds that image and starts three machines from it, each at a fixed
address on a Docker network of their own, with your SSH key authorised for `deploy`:

```sh
#!/bin/sh
# ~/hosts/up.sh: web1, web2 and db1 for lesson 18, as Docker containers.
# Run it again at any time: it throws the old machines away and starts new ones.
set -e
cd ~/hosts
mkdir -p ~/.ssh && chmod 700 ~/.ssh
[ -f ~/.ssh/id_ed25519 ] || ssh-keygen -q -t ed25519 -N "" -f ~/.ssh/id_ed25519
docker build -q -t iac-host . >/dev/null
docker network inspect iac >/dev/null 2>&1 ||
  docker network create --subnet 172.30.0.0/24 iac >/dev/null
for h in web1:172.30.0.11 web2:172.30.0.12 db1:172.30.0.21; do
  name=${h%%:*} addr=${h#*:}
  docker rm -f "$name" >/dev/null 2>&1 || true
  docker run -d --name "$name" --hostname "$name" --network iac --ip "$addr" iac-host >/dev/null
  docker cp ~/.ssh/id_ed25519.pub "$name:/home/deploy/.ssh/authorized_keys"
  docker exec "$name" chown deploy: /home/deploy/.ssh/authorized_keys
  grep -q " $name\$" /etc/hosts || echo "$addr $name" | sudo tee -a /etc/hosts >/dev/null
  echo "$name is $addr"
done
```

Three things in it are worth a sentence. **The key** is made only if you have none, and it has no
passphrase, which is acceptable for machines that exist on your computer for an afternoon and for
nothing else. **The names** go into `/etc/hosts`, which is why the script asks for `sudo` once: that
file is how `ssh web1` finds `172.30.0.11` without a DNS server. And **running it again** gives you
three new machines with nothing installed, which is how this lesson was recorded: its transcripts
start from machines this script had just made.

```
ana@laptop:~$ sh ~/hosts/up.sh
web1 is 172.30.0.11
web2 is 172.30.0.12
db1 is 172.30.0.21
ana@laptop:~$ docker ps --filter network=iac --format '{{.Names}}  {{.Image}}  {{.Status}}'
db1  iac-host  Up Less than a second
web2  iac-host  Up Less than a second
web1  iac-host  Up 1 second
```

The first run spends most of its time building the image, because `apt-get` runs inside the build;
later runs reuse the image. When you have finished the lesson, `docker rm -f web1 web2 db1` removes
the machines. What stays is the image `iac-host`, the network `iac`, your key and the three lines in
`/etc/hosts`, and lesson 20 uses Docker again.
