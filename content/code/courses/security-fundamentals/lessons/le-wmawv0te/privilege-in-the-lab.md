---
title: Privilege in the lab
version: 1
---

The shop's server `www` runs the portal and also stores the finance spreadsheet. This section looks
at what three accounts on that one machine may do: the portal's own account, bruno's and ana's.

### The portal's account

```
root@www:~# id shop
uid=990(shop) gid=990(shop) groups=990(shop)
root@www:~# ps -o user,args -p $(cat /srv/portal/portal.pid)
USER     COMMAND
shop     python3 /srv/portal/portal.py
root@www:~# getpcaps $(cat /srv/portal/portal.pid) | cut -d' ' -f2
cap_net_bind_service=eip
```

`id shop` shows an account with nothing extra: user `shop`, group `shop`, no other groups. `ps`
confirms that the running portal belongs to it, not to `root`, the administrator account that may
do anything on the machine. A web program running as `root` is one of the most common mistakes on
small servers, because it is the easiest way to make it start; it means a bug in the portal is a
bug with full control of the server.

The last line is subtler. A program on Linux normally needs to be `root` to listen on a port below
1024, and the web port is 80. Rather than run as `root` for that one need, the portal was started
holding a single **capability**, `cap_net_bind_service`: the right to listen on low ports, and
nothing else that `root` has. Linux splits `root`'s power into about forty such pieces exactly so a
program can be given one of them.

### Who reads the files

```
root@www:~# ls -l /srv/hr/salaries.csv /srv/portal/users
-rw-r----- 1 bruno hr    33 Sep 30 17:00 /srv/hr/salaries.csv
-rw-r----- 1 root  shop 189 Sep 30 17:00 /srv/portal/users
bruno@www:~$ id
uid=1002(bruno) gid=1002(bruno) groups=1002(bruno),1100(hr)
bruno@www:~$ cat /srv/hr/salaries.csv
name,monthly
ana,7800
bruno,8200
ana@www:~$ cat /srv/hr/salaries.csv
cat: /srv/hr/salaries.csv: Permission denied
```

The salaries file is readable by its owner, bruno, and by the group `hr`. The portal's password
file is readable by `root` and by the group `shop`, because the portal needs to check passwords and
nobody else does. bruno's `id` shows him in `hr`, and he reads the salaries. ana runs IT and has an
account on this server, and is refused, because running IT is not a reason to read salaries.

### What the administrator may do

ana administers the portal. That does not require `root`; it requires restarting the portal and
reading its log. `sudo` is the program that lets a user run specific commands as another user,
usually `root`, under rules an administrator wrote:

```
ana@www:~$ sudo -l
Matching Defaults entries for ana on www:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin,
    use_pty

User ana may run the following commands on www:
    (root) NOPASSWD: /usr/local/sbin/portal-restart, /usr/bin/tail /var/log/lab/portal.log
ana@www:~$ sudo tail /var/log/lab/portal.log
192.168.10.20 - "GET / HTTP/1.1" 200 -
192.168.10.20 - "GET /handbook HTTP/1.1" 200 -
ana@www:~$ sudo -l tail /var/log/lab/portal.log; echo "exit $?"
/usr/bin/tail /var/log/lab/portal.log
exit 0
ana@www:~$ sudo -l cat /srv/hr/salaries.csv; echo "exit $?"
exit 1
```

`sudo -l` lists what ana may run as `root` on `www`, and the answer is two commands: the portal's
restart script and `tail` on the portal's log, with that exact file named. She uses the second one,
and it works. `sudo -l` followed by a command asks whether that particular command would be allowed
without running it: `tail` on the log is (`exit 0`), and `cat` on the salaries is not (`exit 1`).

Two details make that rule tight. The commands are written with their **full paths and arguments**,
so the rule does not allow `tail` on any other file. And it does not allow a shell or an editor:
a rule permitting `sudo vim` or `sudo bash` would hand over `root` entirely, because both can run
any other command from inside. `linux-terminal` lesson 4 covers `sudo` and permissions in full.
