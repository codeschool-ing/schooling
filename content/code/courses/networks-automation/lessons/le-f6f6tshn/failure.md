---
title: A backup that failed has to say so
version: 2
---

For the next run, edge2's SSH server was stopped, the way a router stops answering after a
crash, a wrong ACL or a rotated key. To do the same, stop it from the virtual machine with
`sudo ~/netlab/netlab.sh enter edge2 root 'kill $(cat /run/sshd-edge2.pid)'`, and start it again
afterwards with `sudo ~/netlab/netlab.sh enter edge2 root '/usr/sbin/sshd -f /etc/ssh/sshd_config'`:

```
ana@ctl:~$ cd net && python backup.py; echo "exit status $?"
edge2: FAILED, kept the previous copy: TCP connection to device failed.
no change since the last backup
exit status 1
```

Read the second line. **`no change since the last backup` is true**, and it is exactly the trap: the
repository still has an `edge2.conf`, from the last night it answered, and the commit history looks
the same as on a quiet night. Without the first line, a backup job that has not reached edge2 in a
month looks identical to one that reached it last night.

So the failure is reported twice. The line names the router and the reason, and **the exit status
is 1**, which is what a scheduler, a pipeline or a monitoring check can act on without reading the
output. A job that printed the failure and exited 0 would leave it to somebody reading the log every
morning, which is to say to nobody.

The other two routers were still backed up; Nornir runs every host regardless of the others, as
lesson 8 showed. edge2's SSH server was started again after this run, with the second command
above.
