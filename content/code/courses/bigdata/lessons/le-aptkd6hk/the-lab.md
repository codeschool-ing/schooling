---
title: The lab, and three ways to run it
version: 1
---

**Nothing in this course runs on a machine we host.** Every job is run on a computer of your own,
and the transcripts in the lessons were recorded on one built exactly the way this section builds
yours. A course about clusters that you only read would teach you the vocabulary and none of the
judgement, and the judgement is the subject.

The lab is one Linux machine with three programs on it:

- **Java 17**, because Spark runs on the Java virtual machine even when you drive it from Python.
- **Apache Spark 4.1.3**, the binary release from the Apache Software Foundation, unpacked in your
  home directory. It brings its own copy of the Python library, `pyspark`, so nothing is installed
  with `pip`.
- **Python 3**, which Ubuntu already has, for the programs you write and for the Python half of
  Spark.

The machine in the transcripts belongs to Ana, Ponto Final's data analyst. It is called `lab`, her
working directory is `~/big`, and her prompt reads `ana@lab:~/big$`. Yours will carry your own name.

## Three ways to run it

| | what it is | what it costs your computer |
|---|---|---|
| **a virtual machine** (recommended) | Ubuntu Server 24.04 LTS in a virtual machine, made with Multipass or another hypervisor | 4 processors and 8 GB of memory while it runs, and a 40 GB disk |
| installed | Ubuntu 24.04 as the system of a computer you use, or inside WSL 2 on Windows | the same memory while a job runs, about 3 GB of disk for the programs, and the data on top |
| online | a hosted notebook that runs `pyspark` | nothing, and only the lessons that need no cluster |

**A virtual machine is the recommendation**, for two reasons. The cluster you start in the next
section is four Java processes that listen on network ports, and a virtual machine keeps them away
from everything else you run. And lessons 3 and 12 install Hadoop beside Spark, which is easier to
throw away with the machine than to remove by hand.

Multipass, from Canonical, makes an Ubuntu virtual machine with one command on Windows, macOS and
Linux. Install it from its website, then in your computer's own terminal:

```sh
multipass launch 24.04 --name lab --cpus 4 --memory 8G --disk 40G
multipass shell lab
```

**Those two commands were not run for this course**, because the computer it was recorded on
cannot run a hypervisor. The first creates the machine and the second opens a shell inside it, as
the user `ubuntu`. Everything after this point is typed in that shell. VirtualBox on Windows and
Linux, UTM on an Apple-silicon Mac and Hyper-V on Windows do the same job with more installer
screens: give the machine Ubuntu Server 24.04 LTS and the sizes in the table.

**Why 8 GB.** Three workers of 1 GB each, a driver of 1 GB, and the master and the workers' own
processes come to about 5 GB while a job runs. The rest is the operating system and room to breathe.
With 4 GB the cluster still starts if you give it two workers instead of three, and section 06 says
how; the lessons that count workers will then count two.

**Installed** costs nothing extra if your computer already runs Ubuntu 24.04, or Windows 10 or 11
with WSL 2 and its Ubuntu 24.04 distribution, which runs the same commands. On a Mac, Homebrew
installs Java 17 (`brew install openjdk@17`) and the Spark release below unpacks and runs the same
way; the course was not recorded on one, and the paths to Java differ.

**Online** is named so you know it exists. A hosted notebook can `pip install pyspark` and run
Spark in local mode, one process pretending to be the whole cluster, and that covers the Spark
API of lessons 5, 6, 9 and 10. It cannot cover the lessons about workers, shuffles between them and
failures, and those are most of the course. Free allowances on hosted notebooks change their terms
from year to year, so nothing here depends on one.

## The programs

In the machine's shell, as your own user:

```sh
sudo apt-get update
sudo apt-get install -y openjdk-17-jre-headless python3 jq curl
curl -O https://downloads.apache.org/spark/spark-4.1.3/spark-4.1.3-bin-hadoop3.tgz
curl -O https://downloads.apache.org/spark/spark-4.1.3/spark-4.1.3-bin-hadoop3.tgz.sha512
sha512sum -c spark-4.1.3-bin-hadoop3.tgz.sha512
tar -xzf spark-4.1.3-bin-hadoop3.tgz
ln -s spark-4.1.3-bin-hadoop3 spark
cat > ~/.sparkrc <<'END'
export SPARK_HOME=~/spark
export PATH=$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH
export TZ=America/Sao_Paulo
END
echo '. ~/.sparkrc' >> ~/.bashrc
. ~/.sparkrc
mkdir ~/big
```

The first two lines install Java 17, which is what Spark 4 asks for at least, and two small tools
the course uses to read Spark's answers: `curl` asks a web address for a page, and `jq` picks
fields out of the JSON that comes back. The two `curl -O` lines download the release, 573 MB, and
the file of its SHA-512 checksum. `sha512sum -c` recomputes the checksum and compares; anything but
`OK` means the download is damaged, and section 06 says what to do.

`tar` unpacks the release into a directory named after its version, and `ln -s` gives it the short
name `spark`, so that a later version is a new directory and a moved link. The four lines written to
`~/.sparkrc` tell every program where Spark lives, put its commands on your path, and make times
print in São Paulo's offset, as they do in the transcripts. The line added to `~/.bashrc` reads that
file in every new terminal, and `. ~/.sparkrc` reads it in this one.

The checksum and what the machine has afterwards:

```
ana@lab:~$ sha512sum -c spark-4.1.3-bin-hadoop3.tgz.sha512
spark-4.1.3-bin-hadoop3.tgz: OK
ana@lab:~$ java -version
openjdk version "17.0.20.1" 2026-08-18
OpenJDK Runtime Environment (build 17.0.20.1+1-1-24.04-Ubuntu)
OpenJDK 64-Bit Server VM (build 17.0.20.1+1-1-24.04-Ubuntu, mixed mode, sharing)
ana@lab:~$ spark-submit --version
WARNING: Using incubator modules: jdk.incubator.vector
Using Spark's default log4j profile: org/apache/spark/log4j2-defaults.properties
26/10/10 04:19:38 WARN Utils: Your hostname, lab, resolves to a loopback address: 127.0.1.1; using 192.0.2.2 instead (on interface eth0)
26/10/10 04:19:38 WARN Utils: Set SPARK_LOCAL_IP if you need to bind to another address
Welcome to
      ____              __
     / __/__  ___ _____/ /__
    _\ \/ _ \/ _ `/ __/  '_/
   /___/ .__/\_,_/_/ /_/\_\   version 4.1.3
      /_/
                        
Using Scala version 2.13.17, OpenJDK 64-Bit Server VM, 17.0.20.1
Branch HEAD
Compiled by user holden on 2026-07-12T02:17:43Z
Revision 77bbf77e86ad48f58b5dfbc6ac882b3e70cf1989
Url https://github.com/apache/spark
Type --help for more information.
```

Two kinds of warning came with the version, and neither is a fault. **`Using incubator modules:
jdk.incubator.vector`** is Java reporting that Spark asked for a module still marked experimental.
Every Spark program on Java 17 prints it, and you will see it at the top of most transcripts.
**`Your hostname, lab, resolves to a loopback address`** is Spark noticing that the machine's name
points back at itself, so it picked the machine's network address instead. The configuration of the
next section tells it which address to use, and the warning goes away with it, along with the line
about the default log profile.
