---
title: When srv will not cooperate
version: 1
---

Building a server is the step where a deploy lesson most often stops, and almost always at one of a few
places. The first four were met while this lesson was being recorded; the last two are described as the
tools document them.

**ssh does not know the name.** Before `~/.ssh/config` has a `Host srv` entry, `srv` is only a word:

```
ana@laptop:~$ ssh srv true
ssh: Could not resolve hostname srv: Temporary failure in name resolution
```

ssh asked the network what `srv` is and nobody knew. Check the file's spelling, and that its lines are
in `~/.ssh/config` and not in a file of another name. On Windows the file is `.ssh\config` in your
user folder, with no extension; an editor that quietly saves it as `config.txt` produces exactly this.

**The tools are not there yet.** The first boot installs packages, and srv answers ssh before it has
finished:

```
ana@laptop:~$ ssh srv cloud-init status
status: running
ana@laptop:~$ ssh srv podman --version
bash: line 1: podman: command not found
```

Nothing is wrong. `cloud-init status --wait` waits until it is, and then `podman` exists. If the status
ends in `error` instead of `done`, `ssh srv sudo cat /var/log/cloud-init-output.log` shows what every
step printed. The usual cause is a package that failed to download because the machine has no route to
the internet, and the fix for that is the hypervisor's network setting, not srv.yaml.

**ssh refuses the key.** This is what a wrong key or a wrong user name looks like:

```
ana@laptop:~$ ssh ubuntu@srv true
ubuntu@10.20.0.20: Permission denied (publickey).
```

`publickey` in the brackets is the list of ways srv accepts, and the key offered was not one of them. Here
the user was wrong: Ubuntu's images have a user called `ubuntu`, and srv.yaml's `users` list replaced it.
If the user is right, the key in srv.yaml is not the one in your `~/.ssh/id_ed25519.pub`: a line broken
in two when it was pasted is the usual way. cloud-init reads srv.yaml **only on the first boot**, so
correcting the file changes nothing on a machine that exists. Delete srv and build it again:
`multipass delete --purge srv`, then the `launch` line once more.

**ssh shouts that the machine has changed.** After srv is built again at the same address, it has new
keys of its own, and ssh remembers the old ones:

```
ana@laptop:~$ ssh srv true
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ED25519 key sent by the remote host is
SHA256:rHl6qcsOJuha/VvhLLJN0qYp7qa4J54W5G5YMIwREHY.
Please contact your system administrator.
Add correct host key in /home/ana/.ssh/known_hosts to get rid of this message.
Offending ECDSA key in /home/ana/.ssh/known_hosts:3
  remove with:
  ssh-keygen -f '/home/ana/.ssh/known_hosts' -R '10.20.0.20'
Host key for 10.20.0.20 has changed and you have requested strict checking.
Host key verification failed.
ana@laptop:~$ ssh-keygen -R 10.20.0.20
# Host 10.20.0.20 found: line 1
# Host 10.20.0.20 found: line 2
# Host 10.20.0.20 found: line 3
/home/ana/.ssh/known_hosts updated.
Original contents retained as /home/ana/.ssh/known_hosts.old
```

This is the warning that would catch somebody impersonating your server, so read it every time rather
than learn to dismiss it. When the reason is that **you** rebuilt srv, `ssh-keygen -R` with its address
forgets the old keys, and the next `ssh srv` asks the first-connection question again.

**The machine does not start.** A hypervisor needs the processor's virtualisation feature, and some
computers ship with it switched off in the firmware, where it is called *Intel VT-x*, *AMD-V* or *SVM*.
On Windows Home there is no Hyper-V, and Multipass needs VirtualBox installed and selected with
`multipass set local.driver=virtualbox` before the first `launch`. Neither failure was recorded here.

**`ssh srv` waits and then gives up.** If it worked yesterday, srv may be stopped, `multipass start srv`,
or its address may have changed after a restart of your computer. `multipass info srv` shows the address
it has now, and `HostName` in `~/.ssh/config` is the one line to correct.
