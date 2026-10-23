---
title: Nine bits, and the one file that needed them
version: 1
---

**Every file on Linux carries three sets of permissions: for its owner, for its group, and for
everybody else.** Each set says whether that class of user may read, write or execute. That is nine
bits, printed by `ls -l` as `rwxrwxrwx`, and for most files they are all the access control there
is. The rest of this lesson is about where nine bits run out, but first, a file where they were
enough and were set wrong.

Start the lab with `sudo bash hostlab.sh up web`. Lesson 1 noted, as it built the portal, a backup
script that root runs every night. Ask the file system for every file that anybody at all may write:

```
ana@web:~$ sudo find / -xdev -type f -perm -0002 2>/dev/null
/opt/portal/backup.sh
ana@web:~$ ls -l /opt/portal/backup.sh; cat /etc/cron.d/portal-backup
-rwxrwxrwx 1 root root 54 Oct 23 09:11 /opt/portal/backup.sh
30 2 * * * root /opt/portal/backup.sh
```

One file, and the worst place for it to be. The script is owned by root and run by root at 02:30
every night through `/etc/cron.d/portal-backup`, and its last three bits are `rwx`: **any account on
the machine may change what root will run tonight.** That includes `portal`, the account the web
application runs as, so a flaw in the portal that let somebody write one file would hand them root
by the next morning. Ask the system whether `portal` really can, without changing anything:

```
ana@web:~$ sudo -u portal test -w /opt/portal/backup.sh && echo "portal may change a script root runs"
portal may change a script root runs
```

`test -w` answers whether the user it runs as may write the file, and `sudo -u portal` runs it as
`portal`. The answer is yes. The fix is the permission the file should have had from the start:
owned by root, writable by root alone.

```
ana@web:~$ sudo chown root:root /opt/portal/backup.sh && sudo chmod 755 /opt/portal/backup.sh && ls -l /opt/portal/backup.sh
-rwxr-xr-x 1 root root 54 Oct 23 09:11 /opt/portal/backup.sh
ana@web:~$ sudo -u portal test -w /opt/portal/backup.sh || echo "portal may not change it"
portal may not change it
```

## The rule behind the fix

A program that runs with privilege must not be writable by anybody with less. The same holds for
every file such a program reads to decide what to do: the scripts in `/etc/cron.d`, a service's
unit file, the configuration of `sudo`, the directories they live in. The `find` above is one line
worth running on every machine you inherit, and lesson 18 makes it part of the inventory. Its
cousins find files with the set-user-id bit, which run with their owner's privilege whoever starts
them (`-perm -4000`), and directories anybody may write without the sticky bit that `/tmp` has.

## Where nine bits run out

The permission bits name exactly one user and exactly one group. Jatobá's client documents need
more than that: the accountants read and write them, an external auditor reads them and never
writes, and the portal reads them to let each client download their own. Three kinds of access to
one directory, and only one group slot to give. The next section shows the bits failing at that,
and the extension that does not.
