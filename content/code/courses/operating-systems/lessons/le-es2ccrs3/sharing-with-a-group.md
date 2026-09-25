---
title: A folder a group can share
version: 1
---

The payroll problem is really a group problem: **the accounting people** should read and write the
folder, and nobody else should. On Linux that is a group, a folder owned by it, and one special bit.

```
ana@server:/srv/office$ sudo groupadd accounts
ana@server:/srv/office$ sudo usermod -aG accounts bruno
ana@server:/srv/office$ sudo mkdir /srv/accounts
ana@server:/srv/office$ sudo chown root:accounts /srv/accounts
ana@server:/srv/office$ sudo chmod 2770 /srv/accounts
ana@server:/srv/office$ ls -ld /srv/accounts
drwxrws--- 2 root accounts 4096 Sep 25 10:53 /srv/accounts
ana@server:/srv/office$ sudo -u bruno touch /srv/accounts/ledger.xlsx
ana@server:/srv/office$ sudo -u carla touch /srv/accounts/ledger.xlsx
touch: cannot touch '/srv/accounts/ledger.xlsx': Permission denied
ana@server:/srv/office$ sudo ls -l /srv/accounts
total 0
-rw-rw-r-- 1 bruno accounts 0 Sep 25 10:53 ledger.xlsx
```

Step by step:

1. `groupadd accounts` creates the group, and **`usermod -aG accounts bruno`** adds bruno to it.
   The `-a` matters: without it, `-G` *replaces* all of bruno's groups with this one.
2. The folder belongs to **`root:accounts`**, so the group's letters are the ones that count.
3. `2770`: everything for the owner and the group, nothing for others, and the leading **2**, the
   *setgid* bit, shown as the `s` in `rws`.
4. bruno, a member, created a file. carla, who is not, was refused.
5. The new file's group is **`accounts`**, not bruno's own group. **That is what setgid does on a
   folder**: every new file inside joins the folder's group, so the next member can open it. Without it
   each file would belong to its creator's private group and the sharing would quietly stop working
   one file at a time.

A user added to a group gets it **at their next login**. A session that was open before `usermod` still
has the old list, which is the usual reason "I added her and it still says Permission denied".

## The default for new files

Where did `-rw-rw-r--` on the new file come from? From the *umask*, the permissions every new file
starts *without*:

```
ana@server:/srv/office$ umask
0002
ana@server:/srv/office$ touch new.txt && mkdir newdir
ana@server:/srv/office$ ls -ld new.txt newdir
-rw-rw-r-- 1 ana ana    0 Sep 25 10:53 new.txt
drwxrwxr-x 2 ana ana 4096 Sep 25 10:53 newdir
```

Programs ask for `666` for files and `777` for folders, and the umask **`0002`** takes away `w` for
others. New files come out `664`, new folders `775`. A stricter server sets `027`, and new files are
born unreadable by others.
