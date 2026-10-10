---
title: When the setup fails
version: 1
---

Most people who give up on a course like this give up on the first day, on an error about a
machine they have only just built. These are the failures that actually happen, roughly in the
order you would meet them. Where the lab machine could produce one, it is shown as that machine
printed it.

**The VM will not start, and the message mentions virtualisation, VT-x, AMD-V or SVM.** The
processor's virtualisation support is switched off in the computer's firmware. It is a setting in
the BIOS or UEFI menu, usually under *Advanced* or *CPU configuration*, and no program can switch
it on for you. Docker Desktop on Windows fails on the same setting.

**`multipass launch` times out.** The first launch downloads an Ubuntu image of several hundred
megabytes, and a slow connection takes longer than the default wait. Add `--timeout 1800` and let
it finish.

**`multipass launch` says there is not enough memory.** The 8 GB has to be free when the VM
starts, not merely installed. Close what you can, or ask for `--memory 6G`; the lessons that need
the most say so at the top, and stopping the previous lesson's containers is usually enough.

**`apt-get` says it could not get a lock.** Ubuntu runs its own updates in the first minutes after
a machine boots, and only one program may install packages at a time. Wait a few minutes and run
the command again. Deleting the lock file is the advice you will find online, and it is how a
package database gets corrupted.

**`permission denied while trying to connect to the docker API`.** The engine is running and
refused you: either you are not in the `docker` group, or you are and have not logged in again
since. `id -nG` without `docker` in it says which. Two fixes you will be offered are both wrong:
`sudo chmod 666` on the socket hands every account on the machine what membership of the group
amounts to, which is root, and `sudo` before every `docker` leaves files owned by root in your own
directories.

**A port is already in use.** Every lesson publishes its services on the machine's loopback, and
a container left running by an earlier lesson still holds its port. This is what that looks like,
with the shop of this lesson started a second time under another project name:

```
ana@vm:~/lab/monolith$ docker compose -p second up -d --quiet-build
 Volume second_data Creating 
 Network second_default Creating 
 Volume second_data Creating 
 Network second_default Creating 
 Volume second_data Created 
 Volume second_data Created 
 Network second_default Created 
 Network second_default Created 
 Container second-shop-1 Creating 
 Container second-shop-1 Created 
 Container second-shop-1 Starting 
Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint second-shop-1 (42ea779442c08ba397371a91ecee4a3555a6132ec901591353bbec83b4dbfbbf): Bind for 127.0.0.1:8000 failed: port is already allocated
```

`docker ps` lists what is running and which ports it holds; `docker compose down` in the old
lesson's directory frees them.

**A container stops with exit code 137.** That is 128 plus signal 9: the kernel killed the process,
almost always because the container, or the whole VM, ran out of memory. Here is the same thing on
purpose, a program asking for 200 MB in a container allowed 64:

```
ana@vm:~/lab/monolith$ docker run --name hog --memory 64m python:3.12-slim python -c "b = bytearray(200 * 1024 * 1024)"; echo "exit code $?"
exit code 137
ana@vm:~/lab/monolith$ docker inspect --format "{{.State.OOMKilled}} {{.State.ExitCode}}" hog
true 137
```

`docker inspect` says `"OOMKilled": true` when the container's own limit was the cause. If it says
`false` and the code is still 137, the VM itself ran out: give it more memory or run fewer things
at once.

**`no space left on device`.** Images, build cache and volumes pile up across twenty lessons.
`docker system df` says how much each takes, and `docker system prune` removes stopped containers,
unused networks and dangling images; add `--volumes` only when nothing in them matters, because it
deletes data for good.

**`429 Too Many Requests` from Docker Hub.** Docker Hub limits how many images an address may pull
without logging in, and a school, an office or a café shares one address between everybody behind
it. Wait and try again, or create a free Docker Hub account and run `docker login`, which raises the
limit for you.

**On a Mac with Apple silicon**, Multipass makes an `arm64` machine. Every image this course uses
is published for `arm64` as well as `amd64`, so the commands work unchanged; only the image digests
differ from the transcripts.
