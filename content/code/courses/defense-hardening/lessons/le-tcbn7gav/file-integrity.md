---
title: File integrity, the detection half
version: 1
---

**File integrity monitoring answers one question: what changed on this machine since somebody
last said it was right?** It records a fingerprint of chosen files, their permissions, owners and a
hash of their contents, and compares them later. Any difference is reported. It does not know
whether the difference was a legitimate edit or an intruder's, which is exactly why it reports and
does not block.

On `web`, AIDE is installed. Its own configuration watches the whole system and takes a long time
to build its database; a smaller one, written for the portal, is faster and easier to read. Save
this as `aide.conf` in your home on `web`:

```schooling-example
{"language": "conf", "file": "aide.conf", "parts": [{"code": "database_in=file:/var/lib/aide/portal.db\ndatabase_out=file:/var/lib/aide/portal.db.new\nreport_url=stdout", "note": "AIDE compares the files with a database of how they were. It reads the old database from one file and writes a new one to another, and the gap between the two names is deliberate: a fresh database is only trusted once a person has moved it into place."}, {"code": "Watched = p+u+g+s+sha256\n/etc/ssh Watched\n/etc/sudoers.d Watched\n/opt/portal Watched\n/usr/local/sbin Watched", "note": "`Watched` is a rule naming what to record about each file: permissions, owner, group, size and a SHA-256 of the contents. The four directories are the ones whose change on `web` would matter most: who may log in, who may become root, the portal itself, and the programs root runs."}]}
```

Build the first database, and approve it by moving it into place:

```
ana@web:~$ sudo mkdir -p /var/lib/aide && sudo aide --config=aide.conf --init | tail -3


End timestamp: 2026-10-23 09:18:50 -0300 (run time: 0m 0s)
ana@web:~$ sudo mv /var/lib/aide/portal.db.new /var/lib/aide/portal.db
```

That database is now the approved state of the four directories. **The approval is the important
step**: AIDE reports differences from whatever database it is given, so a database built on a
machine that was already changed approves the change. Built on a fresh server, kept somewhere the
server cannot rewrite, it is a reference.

Now change two things the way an administrator might, or an intruder: a line added to the backup
script that root runs every night, and a new file in `sudoers.d`:

```
ana@web:~$ echo "# reviewed by the new administrator" | sudo tee -a /opt/portal/backup.sh
# reviewed by the new administrator
ana@web:~$ echo "estagio ALL=(ALL) ALL" | sudo tee /etc/sudoers.d/90-helpdesk
estagio ALL=(ALL) ALL
```

And ask AIDE:

```
ana@web:~$ sudo aide --config=aide.conf --check | head -34
Start timestamp: 2026-10-23 09:27:45 -0300 (AIDE 0.18.6)
AIDE found differences between database and filesystem!!

Summary:
  Total number of entries:	22
  Added entries:		1
  Removed entries:		0
  Changed entries:		1

---------------------------------------------------
Added entries:
---------------------------------------------------

f+++++++++++++++++: /etc/sudoers.d/90-helpdesk

---------------------------------------------------
Changed entries:
---------------------------------------------------

f > ...     H     : /opt/portal/backup.sh

---------------------------------------------------
Detailed information about changes:
---------------------------------------------------

File: /opt/portal/backup.sh
 Size      : 54                               | 90
 SHA256    : zVu/+ldDCNjTUYMdyX1M3ffStckqX7Qi | 4+PkGXp2qaiXUEEfX+P9bqqC1vxH5Igd
             j81yOEiv7U0=                     | tBIDR40hHmw=


---------------------------------------------------
The attributes of the (uncompressed) database(s):
---------------------------------------------------
```

Both changes are in the report, with what changed about each: the backup script's size and hash,
and a file added where nobody approved one. AIDE says nothing about whether either was right. A
person reads the report, and either approves the new state, by building and moving a new database
as before, or starts asking who edited the file root runs every night.

A check like this belongs on a schedule, every night, with its report sent off the machine, which
is the same argument lesson 8 made for telemetry: **a report kept on the machine it reports on can
be edited by whoever changed the machine.**
