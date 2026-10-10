---
title: Building the lab
version: 1
---

Four steps: a Linux machine, Docker Engine on it, the three images, and three containers that
answer. If you came from the `docker` course, the first two are done; check them with the commands
under "Is Docker ready?" and carry on from there.

## The machine

Install Multipass from Canonical's site, then, in your computer's own terminal:

```sh
multipass launch 24.04 --name vm --cpus 2 --memory 4G --disk 30G
multipass shell vm
```

The first command creates an Ubuntu 24.04 virtual machine called `vm`; the second opens a shell
inside it. **These two were not run for this course**, because the lab is itself a virtual machine
and cannot start another one. Everything from here on is typed in the shell the second command
opened.

## Docker Engine

Inside the VM, Docker Engine comes from Docker's own package repository. These are the commands
from Docker's installation instructions for Ubuntu, and lesson 6 of `docker` explains them one
line at a time. Check Docker's documentation before running them, since the details change; they
were not run for this course either, because the lab already had Docker installed:

```sh
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
```

The last line lets your user run `docker` without `sudo`. **It takes effect at the next login**, so
leave the shell with `exit` and open it again with `multipass shell vm`.

## Is Docker ready?

```
ana@vm:~$ docker version --format "client {{.Client.Version}}, server {{.Server.Version}}"
client 29.8.2, server 29.8.2
ana@vm:~$ id -nG
ana docker
```

Two version numbers mean the command reached the server, the daemon that runs containers. `docker`
in your list of groups means the new login took. If either is missing, the next section has the
message you will see instead.

## The three images, and the network between them

Pull the images once. Each is a few hundred megabytes, and only the first pull downloads anything;
the lab already had them, which is why its pull answers `up to date`:

```sh
docker pull mongo:8.0
docker pull redis:7.4
docker pull cassandra:5.0
```

```
ana@vm:~$ docker pull mongo:8.0
8.0: Pulling from library/mongo
Digest: sha256:d0d926f94df099bff534b7ee5b5986458131a22489dfff8664509af0c1e2ca9c
Status: Image is up to date for mongo:8.0
docker.io/library/mongo:8.0
```

The tag after the colon is a **release line**, not a release: `mongo:8.0` is whatever 8.0.x is
newest when you pull, so your patch number may be higher than the lab's.

The containers go on a network of their own, called `nosql`. On a user-defined network a container
reaches another **by its name**, which is what lets lesson 9 start three MongoDB servers that find
each other as `mongo1`, `mongo2` and `mongo3`:

```
ana@vm:~$ docker network create nosql
3fe5cc3a3bd354a18067b6dfed5ded5f17121d1724dfd7cbf40829b2c4e26628
```

## Three containers

```sh
docker run -d --name mongo --network nosql mongo:8.0
docker run -d --name redis --network nosql redis:7.4
docker run -d --name cassandra --network nosql -e MAX_HEAP_SIZE=256M -e HEAP_NEWSIZE=64M cassandra:5.0
```

`-d` runs each one in the background, and `--name` is how every later command refers to it. No
port is published to the VM: you will always talk to a server through the client that ships inside
its own image, with `docker exec`, so nothing else on your machine can collide with it.

**The two `-e` settings are the important part of the third line.** Cassandra runs on the Java
virtual machine, and without them it sizes its memory from the memory of the whole machine, not
from what it needs. One Cassandra sized that way fits in 4 GB; the three of lessons 16 to 19 do
not. With a 256 MB heap each node is slow to start and plenty for this course's data.

MongoDB and Redis answer in a second or two. Cassandra takes about a minute to start, and asking
too early is refused:

```
ana@vm:~$ docker exec cassandra cqlsh
Connection error: ('Unable to connect to any servers', {'127.0.0.1:9042': ConnectionRefusedError(111, "Tried connecting to [('127.0.0.1', 9042)]. Last error: Connection refused")})
```

`Connection refused` here means "nothing is listening yet", not "something is wrong". Wait for it
with a loop that asks every five seconds and returns, silently, once Cassandra answers:

```sh
until docker exec cassandra cqlsh -e "SELECT now() FROM system.local" >/dev/null 2>&1; do sleep 5; done
```

```
ana@vm:~$ docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
NAMES       IMAGE           STATUS
cassandra   cassandra:5.0   Up About a minute
redis       redis:7.4       Up About a minute
mongo       mongo:8.0       Up About a minute
```

## The first conversation with each

Each server comes with its own client, and each client has its own prompt. **MongoDB's is
`mongosh`**, which speaks JavaScript; `--quiet` leaves out the banner it otherwise prints:

```
ana@vm:~$ docker exec -it mongo mongosh --quiet
test> db.version()
8.0.32
test> db.lab.insertOne({ greeting: "hello from the lab" })
{
  acknowledged: true,
  insertedId: ObjectId('6ac9e3ec1cdb95b496e200b8')
}
test> db.lab.find()
[
  {
    _id: ObjectId('6ac9e3ec1cdb95b496e200b8'),
    greeting: 'hello from the lab'
  }
]
test> exit
```

`test>` names the database you are in. Nothing was created beforehand: the first write to a
collection called `lab` made both the collection and the database. Lesson 6 has more to say about
that habit.

**Redis's client is `redis-cli`**, and a command is a word followed by its arguments:

```
ana@vm:~$ docker exec -it redis redis-cli
127.0.0.1:6379> PING
PONG
127.0.0.1:6379> SET greeting "hello from the lab"
OK
127.0.0.1:6379> GET greeting
"hello from the lab"
127.0.0.1:6379> exit
ana@vm:~$ docker exec redis redis-server --version
Redis server v=7.4.11 sha=00000000:0 malloc=jemalloc-5.3.0 bits=64 build=f20da322597b16d7
```

**Cassandra's is `cqlsh`**, and its language, CQL, looks like SQL on purpose, with differences
lesson 16 makes the most of:

```
ana@vm:~$ docker exec -it cassandra cqlsh
Connected to Test Cluster at 127.0.0.1:9042
[cqlsh 6.2.0 | Cassandra 5.0.9 | CQL spec 3.4.7 | Native protocol v5]
Use HELP for help.
cqlsh> SELECT cluster_name, release_version FROM system.local;

 cluster_name | release_version
--------------+-----------------
 Test Cluster |           5.0.9

(1 rows)
cqlsh> exit
```

`-it` gives the client a terminal to type into. Leave it out when you hand a client one command
and want only its answer, as the `redis-server --version` line above does.

## What it costs to leave running

```
ana@vm:~$ docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}"
NAME        MEM USAGE / LIMIT
cassandra   595MiB / 15.72GiB
redis       9.523MiB / 15.72GiB
mongo       204.1MiB / 15.72GiB
```

About 800 MB with all three idle, and **Cassandra is three quarters of it** even with the small
heap. The number after the slash is the memory of the whole machine, 15.72 GiB on the lab; in a
4 GB VM yours will say about 3.8. Ask Cassandra how much of its heap it is using:

```
ana@vm:~$ docker exec cassandra nodetool info | grep -E "^Heap Memory"
Heap Memory (MB)       : 140.29 / 256.00
```

256, the limit the `-e` setting gave it.

## Stopping, starting, and starting over

`docker stop` ends the servers and keeps the containers, data included; `docker start` brings them
back as they were:

```
ana@vm:~$ docker stop mongo redis cassandra
mongo
redis
cassandra
ana@vm:~$ docker ps -a --format "table {{.Names}}\t{{.Status}}"
NAMES       STATUS
cassandra   Exited (143) Less than a second ago
redis       Exited (0) 4 seconds ago
mongo       Exited (0) 4 seconds ago
ana@vm:~$ docker start mongo redis cassandra
mongo
redis
cassandra
ana@vm:~$ docker exec mongo mongosh --quiet --eval 'db.lab.countDocuments()'
1
```

The document written before the stop is still there. `docker rm -f` is the other end: it removes
the container, and a new container with the same name starts from nothing:

```
ana@vm:~$ docker rm -f mongo
mongo
ana@vm:~$ docker run -d --name mongo --network nosql mongo:8.0
5a79e581561e308a9b5e12e43035de3951093e0c5a43402a481e4aeecca4fd92
ana@vm:~$ docker exec mongo mongosh --quiet --eval 'db.lab.countDocuments()'
0
```

That is a feature here. **Most lessons start from servers with nothing in them**, and say at the
top which containers they need; when a lesson needs data that must survive a container, it says so
and gives the container a volume. Between lessons, `docker stop` the three to give the VM its
memory back, and `docker start` them when you return.
