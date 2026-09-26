---
title: The account says no
version: 1
---

On pc1, the help desk has an account of its own, `tec`, with a rule that gives it exactly two commands as
root:

```
ana@pc1:~$ sudo cat /etc/sudoers.d/helpdesk
tec ALL=(root) NOPASSWD: /usr/bin/systemctl restart cups, /usr/sbin/lpadmin
ana@pc1:~$ sudo visudo -cf /etc/sudoers.d/helpdesk
/etc/sudoers.d/helpdesk: parsed OK
```

The rule lives in its own file in `/etc/sudoers.d`, and `visudo -c` checks it before it is trusted: a
sudoers file with a mistake in it can lock everyone out of `sudo` on that computer. Asked what it may do,
the account answers with the same two commands, and one of them works:

```
ana@pc1:~$ sudo -u tec sudo -l | tail -2
User tec may run the following commands on pc1:
    (root) NOPASSWD: /usr/bin/systemctl restart cups, /usr/sbin/lpadmin
ana@pc1:~$ sudo -u tec sudo systemctl restart cups && echo restarted
restarted
```

tec's commands run with `sudo -u tec` from ana's session, as the lab's header says. Asked to create a
user, which is not on the list:

```
ana@pc1:~$ echo lab-only-password | sudo -u tec sudo -S useradd bruno
[sudo] password for tec: Sorry, user tec is not allowed to execute '/usr/sbin/useradd bruno' as root on pc1.
```

`sudo` asked for tec's password first, which the script piped in with `-S`, and only then refused: `is not
allowed to execute`, naming the exact command and the computer. **That refusal is the end of the
matter for this account**, and the right next step is not to find another way to run the same command. It
is to pass the request on to whoever creates accounts, lesson 7, with what was asked.
