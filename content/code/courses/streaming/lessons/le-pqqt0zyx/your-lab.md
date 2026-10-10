---
title: Your lab, and three ways to have one
version: 1
---

Every command in this course was run, and every line of output is what the command printed. **You
run them too, on a machine you build yourself in this lesson.** Nothing runs on a machine we host,
and nothing in the course needs one.

The machine is one Linux computer running **Ubuntu 24.04 LTS**, with Java, Apache Kafka 4.3.1 and a
Python environment on it. A real Kafka installation spreads over several servers; here the servers
are processes on the same computer, each with its own port and its own directory. Everything that
matters about Kafka still happens — data really is written to disk, copied between nodes and read
back — and what is missing is only the separate hardware, which lesson 5 says what costs.

| path | what it is | what it costs your computer | the transcripts |
|---|---|---|---|
| **a virtual machine** (recommended) | Ubuntu Server 24.04 in a VM made with Multipass | 2 processors, 4 GB of memory and 20 GB of disk while it runs | match as printed |
| installed | Ubuntu 24.04 as the system of a computer you can spare | nothing extra; Java, Kafka and later PostgreSQL and RabbitMQ stay on that computer | match as printed |
| online | an Ubuntu 24.04 server rented by the hour from a cloud provider | nothing; the provider charges by the hour | match as printed |

The sizes have room in them, and the room was measured. One Kafka node uses about 400 MB of
memory; three of them, which lesson 5 runs, about 1.2 GB. The heaviest lessons are 12 and 13,
where Spark or Flink run beside a broker, and they stay under 3 GB. On disk, Kafka is 135 MB to
download, and by lesson 14 the whole course has installed under 3 GB. Multipass's own default
disk, 5 GB, is too small once Spark and Flink arrive.

**The virtual machine is the recommended path.** The course installs a database, a message broker
and three processing engines, and starts servers that listen on a dozen ports. All of that is
better kept inside a machine you can delete in one command. **Multipass**, Canonical's tool, makes
an Ubuntu VM with one command on Windows, macOS and Linux. Any other hypervisor works in its place
at the price of going through an installer: VirtualBox on Windows and Linux, UTM on an
Apple-silicon Mac, Hyper-V on Windows Pro, GNOME Boxes on Linux. On an Apple-silicon Mac the
machine is ARM rather than x86; Java, Kafka and every Python package the course uses exist for
both.

**Installed** is right on a spare computer that already runs Ubuntu 24.04. On the computer you use
every day it is the wrong choice, because every server the course starts stays installed.

**Online** is any provider that rents an Ubuntu 24.04 server: the big three clouds and the smaller
hosting companies all do. Some offer a free allowance for new accounts, and its terms are theirs to
change, so no lesson depends on one. A rented server is on the internet from its first minute. The
course's servers only ever listen on `localhost`, so they cannot be reached from outside, but keep
the server's own SSH locked to a key. **Remember to delete it** when you stop for the day: a stream
is a thing that never stops, and neither does the bill for the machine under it.

## With Multipass

Install Multipass from its website, then, in your computer's own terminal:

```
$ multipass launch 24.04 --name stream --cpus 2 --memory 4G --disk 20G
$ multipass shell stream
```

**Those two commands were not run for this course**, because the computer it was recorded on
cannot run a hypervisor. The first makes the virtual machine and the second opens a shell inside
it, as the user `ubuntu`, on a machine called `stream`. Everything after this point is typed in
that shell. Most lessons need **two shells at once**, one where something keeps running and one
where you type: open the second the same way, with `multipass shell stream` in another window of
your computer's terminal.

## The software

Java comes from Ubuntu's archive, and so do the Python tools. The JDK rather than the runtime alone,
because lesson 13 compiles a small Java program:

```sh
sudo apt-get update
sudo apt-get install -y openjdk-21-jdk-headless python3-venv curl jq
```

Kafka is not in Ubuntu's archive. It comes from the Apache Software Foundation as one archive of
135 MB, with a checksum published beside it:

```sh
cd ~
curl -fsSLO https://archive.apache.org/dist/kafka/4.3.1/kafka_2.13-4.3.1.tgz
curl -fsSLO https://archive.apache.org/dist/kafka/4.3.1/kafka_2.13-4.3.1.tgz.sha512
```

`archive.apache.org` keeps every release forever, which is why it is the address here; the
faster mirrors keep only the newest. The `2.13` in the name is the version of Scala Kafka was built
with, and it does not matter to you. Before unpacking anything downloaded, check it is what was
published:

```
ubuntu@stream:~$ sha512sum kafka_2.13-4.3.1.tgz | cut -d" " -f1
c7d7b2318cb51aa0c61d3246a51c349210073c5c9b754947ef965a439f2f939e8600f204e134a75ac31faf3829c9370960ef7c6a9886c8a1dbf0339a21f4c54c
ubuntu@stream:~$ cut -d: -f2 kafka_2.13-4.3.1.tgz.sha512 | tr -d " \n" | tr A-F a-f; echo
c7d7b2318cb51aa0c61d3246a51c349210073c5c9b754947ef965a439f2f939e8600f204e134a75ac31faf3829c9370960ef7c6a9886c8a1dbf0339a21f4c54c
```

The two lines are the same string, so the file is the one Apache signed off. A mismatch means a
download that was cut short, or a file that is not Kafka; delete it and fetch it again.

Then unpack it to `~/kafka`, make a Python **virtual environment** in `~/venv` — a directory with its
own Python and its own packages, so nothing here touches the Python Ubuntu runs on — and install
Kafka's Python client into it. The version is pinned, because a newer client can print something
differently from the transcript you are reading:

```sh
tar -xzf kafka_2.13-4.3.1.tgz
mv kafka_2.13-4.3.1 ~/kafka
python3 -m venv ~/venv
~/venv/bin/pip install confluent-kafka==2.16.0
echo 'export PATH="$HOME/venv/bin:$HOME/kafka/bin:$PATH"' >> ~/.profile
mkdir -p ~/work
```

The `echo` line puts Kafka's commands and the environment's Python first on your `PATH`, so that
`kafka-topics.sh` and `python` mean the right thing in every new shell. It takes effect in the next
shell you open; for the one you are in, run `source ~/.profile` once. The software the later
lessons need arrives with them: a schema registry in lesson 6, Spark in 12, Flink in 13,
PostgreSQL and Debezium in 14, and RabbitMQ in 15.
