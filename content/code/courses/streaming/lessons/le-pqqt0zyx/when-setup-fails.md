---
title: When the setup fails
version: 1
---

Most people who give up on a course like this one give up here, on an error about a machine they
have not finished building. These are the failures that happen, roughly in the order you would
meet them. Where there is a transcript, it is the real message, provoked on purpose on this course's
machine.

**The virtual machine will not start, and the message mentions virtualisation, VT-x, AMD-V or
SVM.** The processor's support for virtual machines is switched off in the computer's firmware. It
is a setting in the BIOS or UEFI menu, usually under *Advanced* or *CPU configuration*, and many
laptops ship with it off. No program can turn it on for you. That one was not provoked here,
because the course's machine cannot run a hypervisor.

**`multipass launch` gives up before the machine is ready.** The first launch downloads an Ubuntu
image of several hundred megabytes, and a slow connection takes longer than Multipass waits by
default. Add `--timeout 1800` to the command and let it finish.

**`curl` or `pip` cannot download anything.** Inside the virtual machine, `curl -sI
https://archive.apache.org` should print a status line. If the name does not resolve, the virtual
machine has no DNS, which usually means a VPN or a firewall on your computer is in the way.

**`kafka-topics.sh: command not found`, or `python` runs the wrong Python.** The `PATH` line went
into `~/.profile` and the shell you are typing in started before it did. Run `source ~/.profile`,
or open a new shell. If it still happens, `tail -1 ~/.profile` should show the line; if it does
not, the `echo` was not run.

**`JAVA_HOME is not set and no 'java' command could be found`.** Kafka's scripts look for Java and
found none: the `apt-get install` line did not finish. Run it again and read what it says at the
end. That message was not provoked here, because the course's machine had Java from the start.

**There is no cluster yet.** `start` refuses to guess what you wanted:

```
ubuntu@stream:~/work$ ./cluster.sh start
start: no cluster; cluster.sh new 1 first
```

**The cluster is running and you asked for a new one.** `new` deletes everything the cluster holds,
so it will not do that under a cluster that is still writing:

```
ubuntu@stream:~/work$ ./cluster.sh new 1
new: the cluster is running; cluster.sh stop first
```

`./cluster.sh stop` first, then `new`, if starting from nothing is really what you meant.

**The virtual machine was restarted**, or shut down and started again. The node is a process, and
a restart ends every process, so the first sign is a Kafka tool that waits and cannot connect.
`status` says why, and `start` brings it back with everything it had:

```
ubuntu@stream:~/work$ ./cluster.sh status
node 1: stopped
ubuntu@stream:~/work$ ./cluster.sh start
node 1: up on localhost:9092
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --list
__consumer_offsets
sales
```

The topic made in this lesson is still listed, and its five sales are still in it, because they
are on disk. `__consumer_offsets` is a topic Kafka made for itself, the first time a consumer read
something; lesson 4 opens it.

**Something else holds the port.** Another program listening on 9092 — an earlier Kafka you
installed some other way, or a forgotten server of your own — would let the node start and then
kill it ten seconds later. The script checks first:

```
ubuntu@stream:~/work$ ./cluster.sh start
node 1: port 9092 is taken by another program
ubuntu@stream:~/work$ ss -ltnp | grep 9092
bash: line 1: ss: command not found
```

`ss -ltnp | grep 9092` names the program that holds it, if it is yours. Here it was a Python web
server left running in the other shell, which Ctrl+C there ended.

**The script was saved on Windows and copied in.** Windows ends each line with two characters
where Linux expects one, and the first line of the script then names a program called `bash` plus
an invisible carriage return:

```
ubuntu@stream:~/work$ ./cluster.sh status
/usr/bin/env: ‘bash\r’: Permission denied
ubuntu@stream:~/work$ file cluster.sh
cluster.sh: Bourne-Again shell script, ASCII text executable, with CRLF line terminators
ubuntu@stream:~/work$ sed -i 's/\r$//' cluster.sh
ubuntu@stream:~/work$ file cluster.sh
cluster.sh: Bourne-Again shell script, ASCII text executable
ubuntu@stream:~/work$ ./cluster.sh status
node 1: up on localhost:9092
```

`file` says `with CRLF line terminators`, the `sed` takes the extra character off every line, and
`file` agrees. On this course's machine the first message ends in `Permission denied`; on an
ordinary Ubuntu virtual machine the same file ends it in `No such file or directory`. Either way,
`bash\r` is the clue. Pasting into `nano` inside the virtual machine, as the last section
suggested, avoids the problem altogether.

**A node stopped while starting.** The script says so and names the file with the reason. The
reason is almost always one of three: the directory was never formatted (run `new`), the disk is
full (`df -h ~` shows it), or the configuration was edited by hand and a line is wrong. The last
lines of `~/kafka-data/node1/logs/server.log` say which, in a Java exception whose first line is
the useful one.

**And when nothing else works**, start the cluster from nothing: `./cluster.sh stop`, `./cluster.sh
new 1`, `./cluster.sh start`. You lose the topics and their messages, which in this course are
always made again by the lesson that needs them. If even that fails, delete the virtual machine with
`multipass delete --purge stream` and build it again from the top of this lesson. It feels like
giving up, and it is what people who run labs for a living do with a machine whose state nobody can
explain any more.
